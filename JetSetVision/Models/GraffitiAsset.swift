import Foundation

/// A single graffiti design the user can spray onto a surface. Artwork is
/// bundled in `Assets.xcassets` (see the `Graffiti_*` image sets) and
/// rendered onto a RealityKit plane by `GraffitiRenderer`.
struct GraffitiAsset: Identifiable, Hashable {
    let id: String
    let name: String
    let imageName: String

    /// Aspect ratio (width / height) of the source artwork, so the placed
    /// plane isn't stretched.
    let aspectRatio: CGFloat
}

extension GraffitiAsset {
    static let library: [GraffitiAsset] = [
        GraffitiAsset(id: "bis", name: "BIS", imageName: "Graffiti_Bis", aspectRatio: 128.0 / 128.0),
        GraffitiAsset(id: "breakItUp", name: "BREAK IT UP", imageName: "Graffiti_BreakItUp", aspectRatio: 256.0 / 128.0),
        GraffitiAsset(id: "freakyDeaky", name: "FREAKY DEAKY", imageName: "Graffiti_FreakyDeaky", aspectRatio: 128.0 / 128.0),
        GraffitiAsset(id: "hazeAmaze", name: "HAZE AMAZE", imageName: "Graffiti_HazeAmaze", aspectRatio: 256.0 / 128.0),
        GraffitiAsset(id: "hero", name: "HERO", imageName: "Graffiti_Hero", aspectRatio: 128.0 / 128.0),
        GraffitiAsset(id: "interrobang", name: "INTERROBANG", imageName: "Graffiti_Interrobang", aspectRatio: 184.0 / 46.0),
        GraffitiAsset(id: "psychoColors", name: "PSYCHO COLORS", imageName: "Graffiti_PsychoColors", aspectRatio: 184.0 / 46.0),
        GraffitiAsset(id: "sprayMe", name: "SPRAY ME", imageName: "Graffiti_SprayMe", aspectRatio: 256.0 / 128.0),
        GraffitiAsset(id: "sugar", name: "SUGAR", imageName: "Graffiti_Sugar", aspectRatio: 256.0 / 128.0),
        GraffitiAsset(id: "wildStyleWars", name: "WILD STYLE WARS", imageName: "Graffiti_WildStyleWars", aspectRatio: 184.0 / 46.0),
        GraffitiAsset(id: "yaGottaCheat", name: "YA GOTTA CHEAT", imageName: "Graffiti_YaGottaCheat", aspectRatio: 128.0 / 128.0)
    ]
}
