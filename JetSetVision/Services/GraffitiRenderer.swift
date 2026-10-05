import RealityKit
import UIKit

/// Turns a `GraffitiAsset`'s bundled image into a RealityKit material,
/// caching the result so the same design isn't re-decoded into a texture
/// every time the user sprays it again.
enum GraffitiRenderer {
    private static var cache: [String: UnlitMaterial] = [:]

    static func makeMaterial(for asset: GraffitiAsset) -> UnlitMaterial? {
        if let cached = cache[asset.id] {
            return cached
        }

        guard let uiImage = loadImage(for: asset.source),
              let cgImage = uiImage.cgImage,
              let texture = try? TextureResource.generate(from: cgImage, options: .init(semantic: .color)) else {
            return nil
        }

        var material = UnlitMaterial(color: .white)
        material.color = .init(tint: .white, texture: .init(texture))
        material.blending = .transparent(opacity: .init(floatLiteral: 1.0))

        cache[asset.id] = material
        return material
    }

    /// Clears any cached material for the given asset id — used when a
    /// custom sticker is deleted, so a later re-add with the same id (rare,
    /// but possible if ids ever collide) doesn't serve a stale texture.
    static func invalidateCache(for assetID: String) {
        cache.removeValue(forKey: assetID)
    }

    private static func loadImage(for source: GraffitiAsset.Source) -> UIImage? {
        switch source {
        case .bundled(let imageName):
            return UIImage(named: imageName)
        case .custom(let fileURL):
            return UIImage(contentsOfFile: fileURL.path)
        }
    }
}
