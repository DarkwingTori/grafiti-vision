import UIKit

/// Local persistence for captured AR scenes: JPEGs on disk plus a single
/// Codable JSON index. Deliberately plain `FileManager` + `Codable` rather
/// than a database framework — at MVP scale (a personal collection of
/// captures, no relational queries) that would be meaningfully more
/// machinery for no real benefit, and this stays trivially inspectable.
final class CaptureStore {
    static let shared = CaptureStore()

    private let directoryName = "Captures"
    private let indexFileName = "index.json"

    private init() {}

    func load() -> [Capture] {
        guard let data = try? Data(contentsOf: indexURL()),
              let captures = try? JSONDecoder().decode([Capture].self, from: data) else {
            return []
        }
        return captures.sorted { $0.dateCreated > $1.dateCreated }
    }

    @discardableResult
    func save(image: UIImage, graffitiAssetName: String?) -> Capture? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }

        let id = UUID()
        let capture = Capture(id: id, dateCreated: Date(), fileName: "\(id.uuidString).jpg", graffitiAssetName: graffitiAssetName)
        do {
            try data.write(to: try directory().appendingPathComponent(capture.fileName))
            var all = load()
            all.append(capture)
            try writeIndex(all)
            return capture
        } catch {
            return nil
        }
    }

    func delete(_ capture: Capture) {
        try? FileManager.default.removeItem(at: (try? directory().appendingPathComponent(capture.fileName)) ?? URL(fileURLWithPath: ""))
        let remaining = load().filter { $0.id != capture.id }
        try? writeIndex(remaining)
    }

    func image(for capture: Capture) -> UIImage? {
        guard let url = try? directory().appendingPathComponent(capture.fileName) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    /// A downsampled copy for grid thumbnails — a full-resolution AR
    /// snapshot is several megapixels, too large to decode once per visible
    /// grid cell without a scroll hitch.
    func thumbnail(for capture: Capture, pixelSize: CGSize) -> UIImage? {
        image(for: capture)?.preparingThumbnail(of: pixelSize)
    }

    private func writeIndex(_ captures: [Capture]) throws {
        let data = try JSONEncoder().encode(captures)
        try data.write(to: try indexURL())
    }

    private func indexURL() throws -> URL {
        try directory().appendingPathComponent(indexFileName)
    }

    private func directory() throws -> URL {
        let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = documents.appendingPathComponent(directoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
}
