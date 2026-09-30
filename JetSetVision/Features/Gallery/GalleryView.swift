import SwiftUI

/// Grid of saved AR captures, backed by `CaptureStore`. A simple modal
/// sheet from the camera screen — no tab bar, no navigation stack, per the
/// spec's "camera remains the central experience" navigation rule.
struct GalleryView: View {
    @State private var captures: [Capture] = []
    @State private var selected: Capture?
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]

    var body: some View {
        NavigationStack {
            ScrollView {
                if captures.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(captures) { capture in
                            thumbnail(for: capture)
                                .onTapGesture { selected = capture }
                        }
                    }
                    .padding(8)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("GALLERY")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CLOSE") { dismiss() }
                        .accessibilityLabel("Close gallery")
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { captures = CaptureStore.shared.load() }
        .sheet(item: $selected) { capture in
            CaptureDetailView(capture: capture) {
                CaptureStore.shared.delete(capture)
                captures.removeAll { $0.id == capture.id }
                selected = nil
            }
        }
    }

    private func thumbnail(for capture: Capture) -> some View {
        Group {
            if let image = CaptureStore.shared.thumbnail(for: capture, pixelSize: CGSize(width: 200, height: 200)) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel("Capture from \(capture.dateCreated.formatted(date: .abbreviated, time: .shortened))")
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("NO CREATIONS YET")
                .font(.system(size: 16, weight: .black, design: .monospaced))
            Text("GO SPRAY SOMETHING AND CAPTURE IT")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .opacity(0.6)
        }
        .foregroundStyle(.white)
        .padding(.top, 80)
    }
}

private struct CaptureDetailView: View {
    let capture: Capture
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let image = CaptureStore.shared.image(for: capture) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .navigationTitle(capture.dateCreated.formatted(date: .abbreviated, time: .shortened))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CLOSE") { dismiss() }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash.fill")
                    }
                    .accessibilityLabel("Delete this creation")
                    .accessibilityHint("Deletes this creation permanently")
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
