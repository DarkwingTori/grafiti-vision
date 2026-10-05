import ARKit

/// Saves and restores the physical space ARKit has mapped, via
/// `ARWorldMap` — the actual ARKit mechanism for this, not just
/// remembering coordinates: a world map captures both the space's feature
/// points and every `ARAnchor` added to the session, and lets a later
/// session relocalize into that same physical space and have those anchors
/// come back. Entirely local (`Documents/world.map`) — no cloud anchors,
/// no backend.
enum WorldMapStore {
    private static var fileURL: URL? {
        try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("world.map")
    }

    static func load() -> ARWorldMap? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
    }

    /// Asks the session for its current world map and saves it. Can
    /// legitimately fail (e.g. not enough of the space has been mapped
    /// yet) — that's not an error state worth surfacing to the user, it
    /// just means nothing new is saved this time.
    static func save(from session: ARSession) {
        session.getCurrentWorldMap { worldMap, _ in
            guard let worldMap, let fileURL else { return }
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true) else { return }
            try? data.write(to: fileURL)
        }
    }
}
