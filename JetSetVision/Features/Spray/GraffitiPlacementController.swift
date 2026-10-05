import ARKit
import Combine
import RealityKit
import UIKit

/// Places, selects, and removes graffiti entities in the AR scene.
///
/// Tapping an empty detected surface sprays the currently selected
/// `GraffitiAsset` there: the tap's screen point becomes an AR raycast
/// against existing plane geometry, and the raycast's `worldTransform`
/// already carries the surface's orientation (its local +Y axis matches
/// the surface normal), so the graffiti naturally faces out from a wall or
/// lies flat on a floor with no extra rotation math needed — *provided*
/// the mesh itself is generated with `generatePlane(width:depth:)` (XZ
/// plane, +Y normal), matching `PlaneDetector`'s convention. The other
/// overload, `generatePlane(width:height:)` (XY plane, +Z normal), is a
/// 90° mismatch from what the raycast orientation and RealityKit's
/// rotation gesture (which spins around local Y) both assume. Move/rotate/
/// scale are handled by RealityKit's built-in entity gestures rather than
/// custom gesture code — these require both a `CollisionComponent` (a
/// physical shape to hit-test against) and an `InputTargetComponent`
/// (marking the entity as touch-interactive); dropping either silently
/// disables dragging/twisting/pinching. Tapping an existing piece selects
/// it, showing a highlight outline and enabling the delete button.
///
/// A placement is a real `ARAnchor` registered with the `ARSession` (named
/// `"graffiti|<assetID>"`), not just a RealityKit-only anchor — that's what
/// lets `WorldMapStore` capture it in a saved `ARWorldMap` and have it come
/// back as a fresh `didAdd` callback (via `handleAddedAnchor`) once a later
/// session relocalizes into the same physical space. Building the
/// RealityKit entity happens in that one callback for both a brand-new
/// placement and a restored one — `pendingPlacementAnchorID` is how the
/// freshly-placed case is told apart from a silent restoration, so only a
/// placement the user just made gets selected/haptic feedback.
final class GraffitiPlacementController: ObservableObject {
    private struct Instance {
        let anchor: ARAnchor
        let anchorEntity: AnchorEntity
        let modelEntity: ModelEntity
        let highlightEntity: ModelEntity
    }

    private static let anchorNamePrefix = "graffiti|"

    /// Placed graffiti can be pinched between 0.3x and 3x its original size
    /// (roughly 9cm–90cm wide) so it can't be shrunk to nothing or blown up
    /// past what fits believably on a wall/floor.
    private static let scaleRange: ClosedRange<Float> = 0.3...3.0

    @Published var selectedAsset: GraffitiAsset = GraffitiAsset.library[0]
    @Published private(set) var hasSelection = false

    private weak var arView: ARView?
    private var instances: [UUID: Instance] = [:]
    private var selectedInstanceID: UUID?
    private var scaleGestureRecognizers: [ObjectIdentifier: EntityScaleGestureRecognizer] = [:]
    private var pendingPlacementAnchorID: UUID?

    func attach(to arView: ARView) {
        self.arView = arView
    }

    func handleTap(at location: CGPoint) {
        guard let arView else { return }

        if let hitEntity = arView.entity(at: location),
           let id = UUID(uuidString: hitEntity.name),
           instances[id] != nil {
            select(id)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }

        guard let result = arView.raycast(from: location, allowing: .existingPlaneGeometry, alignment: .any).first else {
            return
        }
        place(at: result)
    }

    /// The selection highlight is a UI affordance, not part of the artwork —
    /// hidden for the duration of an `ARCaptureController` snapshot so it
    /// doesn't bake into the saved image, then restored after.
    func hideHighlightForCapture() {
        guard let id = selectedInstanceID else { return }
        instances[id]?.highlightEntity.isEnabled = false
    }

    func restoreHighlightAfterCapture() {
        guard let id = selectedInstanceID else { return }
        instances[id]?.highlightEntity.isEnabled = true
    }

    func deleteSelected() {
        guard let id = selectedInstanceID,
              let arView,
              let instance = instances.removeValue(forKey: id) else { return }
        arView.scene.removeAnchor(instance.anchorEntity)
        arView.session.remove(anchor: instance.anchor)
        selectedInstanceID = nil
        hasSelection = false
    }

    private func place(at result: ARRaycastResult) {
        guard arView != nil else { return }

        let anchor = ARAnchor(name: Self.anchorNamePrefix + selectedAsset.id, transform: result.worldTransform)
        pendingPlacementAnchorID = anchor.identifier
        arView?.session.add(anchor: anchor)
    }

    /// Called by `ARSessionManager` for every non-plane anchor ARKit adds —
    /// a brand-new placement (added a moment ago, just above) or one
    /// restored from a loaded `ARWorldMap` after relocalizing. Builds the
    /// RealityKit entity identically either way.
    func handleAddedAnchor(_ anchor: ARAnchor) {
        guard let arView,
              let name = anchor.name,
              name.hasPrefix(Self.anchorNamePrefix) else { return }

        let assetID = String(name.dropFirst(Self.anchorNamePrefix.count))
        guard let asset = resolveAsset(id: assetID),
              let material = GraffitiRenderer.makeMaterial(for: asset) else { return }

        let width: Float = 0.3
        let height = width / Float(asset.aspectRatio)
        let mesh = MeshResource.generatePlane(width: width, depth: height)
        let model = ModelEntity(mesh: mesh, materials: [material])

        model.name = anchor.identifier.uuidString
        model.generateCollisionShapes(recursive: false)
        // RealityKit's entity-manipulation gestures (installGestures below)
        // need this to treat the entity as touch-interactive; it's part of
        // the newer cross-platform (visionOS-unified) input model and only
        // exists from iOS 18 onward.
        if #available(iOS 18.0, *) {
            model.components.set(InputTargetComponent(allowedInputTypes: .all))
        }

        let highlight = makeHighlight(width: width, height: height)

        let anchorEntity = AnchorEntity(anchor: anchor)
        anchorEntity.addChild(highlight)
        anchorEntity.addChild(model)
        arView.scene.addAnchor(anchorEntity)

        let recognizers = arView.installGestures([.translation, .rotation, .scale], for: model)
        if let scaleRecognizer = recognizers.compactMap({ $0 as? EntityScaleGestureRecognizer }).first {
            scaleRecognizer.addTarget(self, action: #selector(handleScaleChanged(_:)))
            scaleGestureRecognizers[ObjectIdentifier(model)] = scaleRecognizer
        }

        instances[anchor.identifier] = Instance(anchor: anchor, anchorEntity: anchorEntity, modelEntity: model, highlightEntity: highlight)

        if pendingPlacementAnchorID == anchor.identifier {
            pendingPlacementAnchorID = nil
            select(anchor.identifier)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    /// Bundled designs live in the static library by id; custom stickers
    /// are looked up from `StickerStore` by the UUID encoded in their id.
    private func resolveAsset(id: String) -> GraffitiAsset? {
        if let bundled = GraffitiAsset.library.first(where: { $0.id == id }) {
            return bundled
        }
        return StickerStore.shared.load()
            .first { "sticker:\($0.id.uuidString)" == id }?
            .asGraffitiAsset()
    }

    /// A slightly larger, translucent plane behind the graffiti that reads
    /// as a selection outline/glow. Hidden until its instance is selected.
    private func makeHighlight(width: Float, height: Float) -> ModelEntity {
        let outlineScale: Float = 1.15
        let mesh = MeshResource.generatePlane(width: width * outlineScale, depth: height * outlineScale)
        var material = UnlitMaterial(color: .white.withAlphaComponent(0.55))
        material.blending = .transparent(opacity: .init(floatLiteral: 1.0))
        let highlight = ModelEntity(mesh: mesh, materials: [material])
        // Nudged behind the graffiti along the surface normal (local +Y,
        // matching the XZ-plane mesh convention above) so it reads as an
        // outline/glow rather than fighting the artwork for the same depth.
        highlight.position = SIMD3(0, -0.001, 0)
        highlight.isEnabled = false
        return highlight
    }

    @objc private func handleScaleChanged(_ recognizer: EntityScaleGestureRecognizer) {
        guard recognizer.state == .changed || recognizer.state == .ended,
              let entity = recognizer.entity else { return }

        let clampedScale = SIMD3<Float>(
            entity.scale.x.clamped(to: Self.scaleRange),
            entity.scale.y.clamped(to: Self.scaleRange),
            entity.scale.z.clamped(to: Self.scaleRange)
        )
        entity.scale = clampedScale
    }

    private func select(_ id: UUID) {
        if let previousID = selectedInstanceID, previousID != id {
            instances[previousID]?.highlightEntity.isEnabled = false
        }
        instances[id]?.highlightEntity.isEnabled = true
        selectedInstanceID = id
        hasSelection = true
    }
}

private extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
