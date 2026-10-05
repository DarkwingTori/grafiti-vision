import PhotosUI
import SwiftUI

/// Horizontal strip for choosing which graffiti design to spray next —
/// the built-in designs, any custom photo-cutout stickers the user has
/// made, a "+" button to make a new one, and a manage-library button.
/// The visible lineup, its order, and whether it's shuffled all come from
/// `GraffitiLibraryStore`, not a hardcoded list.
struct GraffitiPicker: View {
    @ObservedObject var controller: GraffitiPlacementController
    @ObservedObject private var libraryStore = GraffitiLibraryStore.shared
    @State private var customStickers: [GraffitiAsset] = StickerStore.shared.load().compactMap { $0.asGraffitiAsset() }
    @State private var lineup: [GraffitiAsset] = []
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isExtracting = false
    @State private var extractionError: String?
    @State private var showManageLibrary = false

    private var allAssets: [GraffitiAsset] {
        GraffitiAsset.library + customStickers
    }

    var body: some View {
        VStack(spacing: 6) {
            if let extractionError {
                ErrorBanner(message: extractionError)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(lineup) { asset in
                        thumbnailButton(for: asset)
                    }
                    addStickerButton
                    manageLibraryButton
                }
                .padding(.horizontal, 16)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: extractionError)
        .onAppear(perform: refreshLineup)
        .onChange(of: photoPickerItem) { _, item in
            guard let item else { return }
            Task { await extractSticker(from: item) }
        }
        .onChange(of: showManageLibrary) { _, isPresented in
            guard !isPresented else { return }
            // The manage sheet may have hidden/reordered/deleted designs —
            // refresh both the sticker list and the resolved lineup.
            customStickers = StickerStore.shared.load().compactMap { $0.asGraffitiAsset() }
            refreshLineup()
        }
        .sheet(isPresented: $showManageLibrary) {
            GraffitiLibraryView()
        }
    }

    private func refreshLineup() {
        let resolved = libraryStore.resolvedLineup(from: allAssets)
        lineup = libraryStore.isRandomized ? resolved.shuffled() : resolved
    }

    private func thumbnailButton(for asset: GraffitiAsset) -> some View {
        Button {
            controller.selectedAsset = asset
        } label: {
            thumbnailImage(for: asset)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 56)
                .padding(6)
                .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(controller.selectedAsset.id == asset.id ? Color.white : .clear, lineWidth: 3)
                )
        }
        .accessibilityLabel(asset.name)
        .accessibilityAddTraits(controller.selectedAsset.id == asset.id ? [.isSelected] : [])
    }

    private func thumbnailImage(for asset: GraffitiAsset) -> Image {
        switch asset.source {
        case .bundled(let imageName):
            return Image(imageName)
        case .custom(let fileURL):
            if let uiImage = UIImage(contentsOfFile: fileURL.path) {
                return Image(uiImage: uiImage)
            }
            return Image(systemName: "photo")
        }
    }

    private var addStickerButton: some View {
        PhotosPicker(selection: $photoPickerItem, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.black.opacity(0.45))
                    .frame(width: 56, height: 56)
                if isExtracting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .disabled(isExtracting)
        .accessibilityLabel("Add sticker from photo")
    }

    private var manageLibraryButton: some View {
        Button {
            showManageLibrary = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.black.opacity(0.45))
                    .frame(width: 56, height: 56)
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .accessibilityLabel("Manage graffiti library")
    }

    private func extractSticker(from item: PhotosPickerItem) async {
        isExtracting = true
        extractionError = nil
        defer {
            isExtracting = false
            photoPickerItem = nil
        }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else {
            extractionError = "COULDN'T LOAD THAT PHOTO"
            return
        }

        do {
            let cutout = try StickerExtractor.extractSticker(from: uiImage)
            guard let saved = StickerStore.shared.save(image: cutout), let asset = saved.asGraffitiAsset() else {
                extractionError = "COULDN'T SAVE STICKER — TRY AGAIN"
                return
            }
            customStickers.insert(asset, at: 0)
            controller.selectedAsset = asset
            refreshLineup()
        } catch StickerExtractor.ExtractionError.noSubjectFound {
            extractionError = "NO SUBJECT FOUND — TRY ANOTHER PHOTO"
        } catch {
            extractionError = "COULDN'T MAKE A STICKER FROM THAT PHOTO"
        }
    }
}
