import Foundation

/// User preferences for curating the graffiti picker: lineup order, which
/// designs are hidden, flat categories, and whether the lineup shuffles.
///
/// Unlike `CaptureStore`/`StickerStore` (plain classes views reload from
/// once on appear), this is an `ObservableObject` singleton: both the
/// picker and the Manage Library sheet are on screen editing/reflecting
/// the same preferences live, so they need to observe one shared instance
/// rather than each reloading independently. Persistence itself is the
/// same plain Codable-JSON-file pattern as everywhere else in the project.
final class GraffitiLibraryStore: ObservableObject {
    static let shared = GraffitiLibraryStore()

    private struct AssetPreference: Codable {
        var sortOrder: Int
        var categoryID: UUID?
        var isHidden: Bool
    }

    private struct FileContents: Codable {
        var categories: [GraffitiCategory]
        var assetPreferences: [String: AssetPreference]
        var isRandomized: Bool
    }

    @Published private(set) var categories: [GraffitiCategory]
    @Published var isRandomized: Bool {
        didSet { persist() }
    }
    private var assetPreferences: [String: AssetPreference]

    private let fileName = "preferences.json"
    private let directoryName = "GraffitiLibrary"

    private init() {
        let contents = Self.readFromDisk()
        categories = contents.categories
        assetPreferences = contents.assetPreferences
        isRandomized = contents.isRandomized
    }

    /// Filters out hidden designs and sorts the rest by stored order,
    /// assigning a trailing order to any asset id never seen before (a new
    /// bundled design or a freshly-made sticker) so it appears at the end
    /// rather than being silently dropped.
    func resolvedLineup(from allAssets: [GraffitiAsset]) -> [GraffitiAsset] {
        var nextOrder = (assetPreferences.values.map(\.sortOrder).max() ?? -1) + 1
        var didAssignNewOrder = false

        let ordered = allAssets
            .filter { !(assetPreferences[$0.id]?.isHidden ?? false) }
            .sorted { lhs, rhs in
                sortOrder(for: lhs.id, next: &nextOrder, didAssign: &didAssignNewOrder)
                    < sortOrder(for: rhs.id, next: &nextOrder, didAssign: &didAssignNewOrder)
            }

        if didAssignNewOrder {
            persist()
        }
        return ordered
    }

    func category(for assetID: String) -> GraffitiCategory? {
        guard let categoryID = assetPreferences[assetID]?.categoryID else { return nil }
        return categories.first { $0.id == categoryID }
    }

    func isHidden(_ assetID: String) -> Bool {
        assetPreferences[assetID]?.isHidden ?? false
    }

    func setHidden(_ hidden: Bool, for assetID: String) {
        var preference = assetPreferences[assetID] ?? AssetPreference(sortOrder: nextTrailingOrder(), categoryID: nil, isHidden: false)
        preference.isHidden = hidden
        assetPreferences[assetID] = preference
        persist()
    }

    func setCategory(_ categoryID: UUID?, for assetID: String) {
        var preference = assetPreferences[assetID] ?? AssetPreference(sortOrder: nextTrailingOrder(), categoryID: nil, isHidden: false)
        preference.categoryID = categoryID
        assetPreferences[assetID] = preference
        persist()
    }

    /// Persists an explicit order for a list of asset ids, as the user left
    /// them after dragging to reorder.
    func reorder(assetIDs: [String]) {
        for (index, assetID) in assetIDs.enumerated() {
            var preference = assetPreferences[assetID] ?? AssetPreference(sortOrder: index, categoryID: nil, isHidden: false)
            preference.sortOrder = index
            assetPreferences[assetID] = preference
        }
        persist()
    }

    @discardableResult
    func addCategory(name: String) -> GraffitiCategory {
        let category = GraffitiCategory(id: UUID(), name: name, sortOrder: (categories.map(\.sortOrder).max() ?? -1) + 1)
        categories.append(category)
        persist()
        return category
    }

    func renameCategory(_ id: UUID, to name: String) {
        guard let index = categories.firstIndex(where: { $0.id == id }) else { return }
        categories[index].name = name
        persist()
    }

    /// Removing a category reassigns its members to Uncategorized rather
    /// than hiding or deleting the designs themselves.
    func deleteCategory(_ id: UUID) {
        categories.removeAll { $0.id == id }
        for key in assetPreferences.keys where assetPreferences[key]?.categoryID == id {
            assetPreferences[key]?.categoryID = nil
        }
        persist()
    }

    func reorderCategories(_ ids: [UUID]) {
        for (index, id) in ids.enumerated() {
            if let categoryIndex = categories.firstIndex(where: { $0.id == id }) {
                categories[categoryIndex].sortOrder = index
            }
        }
        persist()
    }

    /// Clears a deleted custom sticker's stored preference entirely, since
    /// its asset id will never be reused.
    func removePreference(for assetID: String) {
        assetPreferences.removeValue(forKey: assetID)
        persist()
    }

    private func sortOrder(for assetID: String, next: inout Int, didAssign: inout Bool) -> Int {
        if let existing = assetPreferences[assetID]?.sortOrder {
            return existing
        }
        let assigned = next
        assetPreferences[assetID] = AssetPreference(sortOrder: assigned, categoryID: nil, isHidden: false)
        next += 1
        didAssign = true
        return assigned
    }

    private func nextTrailingOrder() -> Int {
        (assetPreferences.values.map(\.sortOrder).max() ?? -1) + 1
    }

    private func persist() {
        let contents = FileContents(categories: categories, assetPreferences: assetPreferences, isRandomized: isRandomized)
        guard let data = try? JSONEncoder().encode(contents), let url = try? Self.fileURL() else { return }
        try? data.write(to: url)
    }

    private static func readFromDisk() -> FileContents {
        guard let url = try? fileURL(),
              let data = try? Data(contentsOf: url),
              let contents = try? JSONDecoder().decode(FileContents.self, from: data) else {
            return FileContents(categories: [], assetPreferences: [:], isRandomized: false)
        }
        return contents
    }

    private static func fileURL() throws -> URL {
        let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = documents.appendingPathComponent("GraffitiLibrary", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("preferences.json")
    }
}
