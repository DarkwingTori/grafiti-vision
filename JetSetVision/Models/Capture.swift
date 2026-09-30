import Foundation

/// Metadata for one saved AR scene capture. The actual image lives on disk
/// as `<id>.jpg` inside `CaptureStore`'s captures directory; this is just
/// the Codable record of it.
struct Capture: Codable, Identifiable, Equatable {
    let id: UUID
    let dateCreated: Date
    let fileName: String
    let graffitiAssetName: String?
}
