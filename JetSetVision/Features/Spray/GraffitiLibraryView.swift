import SwiftUI

/// Manage the graffiti picker's lineup: reorder, hide/delete designs,
/// organize them into flat categories, and toggle randomized order.
struct GraffitiLibraryView: View {
    @ObservedObject private var libraryStore = GraffitiLibraryStore.shared
    @State private var customStickers: [CustomSticker] = StickerStore.shared.load()
    @State private var selectedCategoryID: UUID??
    @State private var isAddingCategory = false
    @State private var newCategoryName = ""
    @Environment(\.dismiss) private var dismiss

    private var allAssets: [GraffitiAsset] {
        GraffitiAsset.library + customStickers.compactMap { $0.asGraffitiAsset() }
    }

    /// `nil` selection = "All"; `.some(nil)` = "Uncategorized"; `.some(id)`
    /// = a specific category.
    private var filteredAssets: [GraffitiAsset] {
        guard let selection = selectedCategoryID else { return allAssets }
        return allAssets.filter { libraryStore.category(for: $0.id)?.id == selection }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Toggle("RANDOMIZE LINEUP", isOn: $libraryStore.isRandomized)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                categoryChips

                List {
                    ForEach(filteredAssets) { asset in
                        row(for: asset)
                    }
                    .onMove(perform: moveAssets)
                }
                .listStyle(.plain)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("MANAGE GRAFFITI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CLOSE") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
            .alert("NEW CATEGORY", isPresented: $isAddingCategory) {
                TextField("Name", text: $newCategoryName)
                Button("CANCEL", role: .cancel) { newCategoryName = "" }
                Button("ADD") {
                    guard !newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    libraryStore.addCategory(name: newCategoryName.uppercased())
                    newCategoryName = ""
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "ALL", isSelected: selectedCategoryID == nil) {
                    selectedCategoryID = nil
                }
                chip(title: "UNCATEGORIZED", isSelected: selectedCategoryID == .some(nil)) {
                    selectedCategoryID = .some(nil)
                }
                ForEach(libraryStore.categories.sorted(by: { $0.sortOrder < $1.sortOrder })) { category in
                    chip(title: category.name, isSelected: selectedCategoryID == .some(category.id)) {
                        selectedCategoryID = .some(category.id)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            if selectedCategoryID == .some(category.id) { selectedCategoryID = nil }
                            libraryStore.deleteCategory(category.id)
                        } label: {
                            Label("Delete Category", systemImage: "trash")
                        }
                    }
                }
                Button {
                    isAddingCategory = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .accessibilityLabel("Add category")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(isSelected ? .black : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.white : Color.white.opacity(0.15), in: Capsule())
        }
    }

    private func row(for asset: GraffitiAsset) -> some View {
        HStack(spacing: 12) {
            thumbnail(for: asset)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(asset.name)
                    .font(.system(size: 14, weight: .semibold))
                Menu {
                    Button("UNCATEGORIZED") { libraryStore.setCategory(nil, for: asset.id) }
                    ForEach(libraryStore.categories) { category in
                        Button(category.name) { libraryStore.setCategory(category.id, for: asset.id) }
                    }
                } label: {
                    Text(libraryStore.category(for: asset.id)?.name ?? "UNCATEGORIZED")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .foregroundStyle(.white)
        .listRowBackground(Color.white.opacity(0.05))
        .swipeActions(edge: .trailing) {
            switch asset.source {
            case .bundled:
                Button {
                    libraryStore.setHidden(!libraryStore.isHidden(asset.id), for: asset.id)
                } label: {
                    Label(libraryStore.isHidden(asset.id) ? "Unhide" : "Hide", systemImage: libraryStore.isHidden(asset.id) ? "eye" : "eye.slash")
                }
                .tint(.orange)
            case .custom:
                Button(role: .destructive) {
                    deleteCustomSticker(asset)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .opacity(libraryStore.isHidden(asset.id) ? 0.4 : 1.0)
    }

    private func thumbnail(for asset: GraffitiAsset) -> some View {
        Group {
            switch asset.source {
            case .bundled(let imageName):
                Image(imageName).resizable().aspectRatio(contentMode: .fit)
            case .custom(let fileURL):
                if let uiImage = UIImage(contentsOfFile: fileURL.path) {
                    Image(uiImage: uiImage).resizable().aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "photo")
                }
            }
        }
        .padding(4)
        .background(.black.opacity(0.3))
    }

    private func moveAssets(from offsets: IndexSet, to destination: Int) {
        var ids = filteredAssets.map(\.id)
        ids.move(fromOffsets: offsets, toOffset: destination)
        libraryStore.reorder(assetIDs: ids)
    }

    private func deleteCustomSticker(_ asset: GraffitiAsset) {
        guard case .custom = asset.source,
              let sticker = customStickers.first(where: { "sticker:\($0.id.uuidString)" == asset.id }) else { return }
        StickerStore.shared.delete(sticker)
        GraffitiRenderer.invalidateCache(for: asset.id)
        libraryStore.removePreference(for: asset.id)
        customStickers.removeAll { $0.id == sticker.id }
    }
}
