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

        guard let uiImage = UIImage(named: asset.imageName),
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
}
