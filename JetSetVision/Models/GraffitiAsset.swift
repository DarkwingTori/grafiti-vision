import Foundation

/// A single graffiti design the user can spray onto a surface, rendered
/// onto a RealityKit plane by `GraffitiRenderer`. Artwork either ships
/// bundled in `Assets.xcassets` (the built-in `Graffiti_*` image sets) or
/// is a user-created photo cutout stored on disk by `StickerStore`.
struct GraffitiAsset: Identifiable, Hashable {
    enum Source: Hashable {
        case bundled(imageName: String)
        case custom(fileURL: URL)
    }

    let id: String
    let name: String
    let source: Source

    /// Aspect ratio (width / height) of the source artwork, so the placed
    /// plane isn't stretched.
    let aspectRatio: CGFloat
}

extension GraffitiAsset {
    static let library: [GraffitiAsset] = [
        GraffitiAsset(id: "bis", name: "BIS", source: .bundled(imageName: "Graffiti_Bis"), aspectRatio: 128.0 / 128.0),
        GraffitiAsset(id: "breakItUp", name: "BREAK IT UP", source: .bundled(imageName: "Graffiti_BreakItUp"), aspectRatio: 256.0 / 128.0),
        GraffitiAsset(id: "freakyDeaky", name: "FREAKY DEAKY", source: .bundled(imageName: "Graffiti_FreakyDeaky"), aspectRatio: 128.0 / 128.0),
        GraffitiAsset(id: "hazeAmaze", name: "HAZE AMAZE", source: .bundled(imageName: "Graffiti_HazeAmaze"), aspectRatio: 256.0 / 128.0),
        GraffitiAsset(id: "hero", name: "HERO", source: .bundled(imageName: "Graffiti_Hero"), aspectRatio: 128.0 / 128.0),
        GraffitiAsset(id: "interrobang", name: "INTERROBANG", source: .bundled(imageName: "Graffiti_Interrobang"), aspectRatio: 184.0 / 46.0),
        GraffitiAsset(id: "psychoColors", name: "PSYCHO COLORS", source: .bundled(imageName: "Graffiti_PsychoColors"), aspectRatio: 184.0 / 46.0),
        GraffitiAsset(id: "sprayMe", name: "SPRAY ME", source: .bundled(imageName: "Graffiti_SprayMe"), aspectRatio: 256.0 / 128.0),
        GraffitiAsset(id: "sugar", name: "SUGAR", source: .bundled(imageName: "Graffiti_Sugar"), aspectRatio: 256.0 / 128.0),
        GraffitiAsset(id: "wildStyleWars", name: "WILD STYLE WARS", source: .bundled(imageName: "Graffiti_WildStyleWars"), aspectRatio: 184.0 / 46.0),
        GraffitiAsset(id: "yaGottaCheat", name: "YA GOTTA CHEAT", source: .bundled(imageName: "Graffiti_YaGottaCheat"), aspectRatio: 128.0 / 128.0)
    ]
}
