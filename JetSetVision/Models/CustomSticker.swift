import Foundation

/// Metadata for one user-created sticker (a photo subject cutout). The
/// actual transparent-background PNG lives on disk as `<id>.png` inside
/// `StickerStore`'s directory; this is the Codable record of it.
struct CustomSticker: Codable, Identifiable, Equatable {
    let id: UUID
    let dateCreated: Date
    let fileName: String
    let aspectRatio: Double
}

extension CustomSticker {
    /// Lets a user-created sticker flow through the same picker/placement
    /// code as the built-in designs.
    func asGraffitiAsset() -> GraffitiAsset? {
        guard let url = StickerStore.shared.fileURL(for: self) else { return nil }
        return GraffitiAsset(
            id: "sticker:\(id.uuidString)",
            name: "STICKER",
            source: .custom(fileURL: url),
            aspectRatio: aspectRatio
        )
    }
}
