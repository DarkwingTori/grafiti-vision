import Foundation

/// A flat, user-created category for organizing graffiti designs (e.g.
/// "Tags", "Stickers"). An asset with no category assignment is treated as
/// "Uncategorized" — a filter state, not a stored category of its own.
struct GraffitiCategory: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var sortOrder: Int
}
