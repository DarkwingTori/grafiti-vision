import UIKit

/// Local persistence for user-created stickers: PNGs (with alpha) on disk
/// plus a single Codable JSON index. Same plain FileManager + Codable
/// pattern as `CaptureStore` — a personal sticker collection has no
/// relational-querying need, so a database would be unjustified overhead.
final class StickerStore {
    static let shared = StickerStore()

    private let directoryName = "Stickers"
    private let indexFileName = "index.json"

    private init() {}

    func load() -> [CustomSticker] {
        guard let data = try? Data(contentsOf: indexURL()),
              let stickers = try? JSONDecoder().decode([CustomSticker].self, from: data) else {
            return []
        }
        return stickers.sorted { $0.dateCreated > $1.dateCreated }
    }

    @discardableResult
    func save(image: UIImage) -> CustomSticker? {
        guard let data = image.pngData() else { return nil }

        let id = UUID()
        let sticker = CustomSticker(
            id: id,
            dateCreated: Date(),
            fileName: "\(id.uuidString).png",
            aspectRatio: image.size.width / image.size.height
        )
        do {
            try data.write(to: try directory().appendingPathComponent(sticker.fileName))
            var all = load()
            all.append(sticker)
            try writeIndex(all)
            return sticker
        } catch {
            return nil
        }
    }

    func delete(_ sticker: CustomSticker) {
        try? FileManager.default.removeItem(at: (try? directory().appendingPathComponent(sticker.fileName)) ?? URL(fileURLWithPath: ""))
        let remaining = load().filter { $0.id != sticker.id }
        try? writeIndex(remaining)
    }

    func fileURL(for sticker: CustomSticker) -> URL? {
        try? directory().appendingPathComponent(sticker.fileName)
    }

    private func writeIndex(_ stickers: [CustomSticker]) throws {
        let data = try JSONEncoder().encode(stickers)
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
