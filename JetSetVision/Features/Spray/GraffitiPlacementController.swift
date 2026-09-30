import ARKit
import Combine
import RealityKit
import UIKit

/// Places, selects, and removes graffiti entities in the AR scene.
///
/// Tapping an empty detected surface sprays the currently selected
/// `GraffitiAsset` there: the tap's screen point becomes an AR raycast
/// against existing plane geometry, and the raycast's `worldTransform`
/// already carries the surface's orientation (its up-axis matches the
/// surface normal), so the graffiti naturally faces out from a wall or
/// lies flat on a floor with no extra rotation math needed. Move/rotate/
/// scale are handled by RealityKit's built-in entity gestures rather than
/// custom gesture code — these require both a `CollisionComponent` (a
/// physical shape to hit-test against) and an `InputTargetComponent`
/// (marking the entity as touch-interactive); dropping either silently
/// disables dragging/twisting/pinching. Tapping an existing piece selects
/// it, showing a highlight outline and enabling the delete button.
final class GraffitiPlacementController: ObservableObject {
    private struct Instance {
        let anchorEntity: AnchorEntity
        let modelEntity: ModelEntity
        let highlightEntity: ModelEntity
    }

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
        selectedInstanceID = nil
        hasSelection = false
    }

    private func place(at result: ARRaycastResult) {
        guard let arView, let material = GraffitiRenderer.makeMaterial(for: selectedAsset) else { return }

        let width: Float = 0.3
        let height = width / Float(selectedAsset.aspectRatio)
        let mesh = MeshResource.generatePlane(width: width, height: height)
        let model = ModelEntity(mesh: mesh, materials: [material])

        let id = UUID()
        model.name = id.uuidString
        model.generateCollisionShapes(recursive: false)
        // RealityKit's entity-manipulation gestures (installGestures below)
        // need this to treat the entity as touch-interactive; it's part of
        // the newer cross-platform (visionOS-unified) input model and only
        // exists from iOS 18 onward.
        if #available(iOS 18.0, *) {
            model.components.set(InputTargetComponent(allowedInputTypes: .all))
        }

        let highlight = makeHighlight(width: width, height: height)

        let anchorEntity = AnchorEntity(world: result.worldTransform)
        anchorEntity.addChild(highlight)
        anchorEntity.addChild(model)
        arView.scene.addAnchor(anchorEntity)

        let recognizers = arView.installGestures([.translation, .rotation, .scale], for: model)
        if let scaleRecognizer = recognizers.compactMap({ $0 as? EntityScaleGestureRecognizer }).first {
            scaleRecognizer.addTarget(self, action: #selector(handleScaleChanged(_:)))
            scaleGestureRecognizers[ObjectIdentifier(model)] = scaleRecognizer
        }

        instances[id] = Instance(anchorEntity: anchorEntity, modelEntity: model, highlightEntity: highlight)
        select(id)

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// A slightly larger, translucent plane behind the graffiti that reads
    /// as a selection outline/glow. Hidden until its instance is selected.
    private func makeHighlight(width: Float, height: Float) -> ModelEntity {
        let outlineScale: Float = 1.15
        let mesh = MeshResource.generatePlane(width: width * outlineScale, height: height * outlineScale)
        var material = UnlitMaterial(color: .white.withAlphaComponent(0.55))
        material.blending = .transparent(opacity: .init(floatLiteral: 1.0))
        let highlight = ModelEntity(mesh: mesh, materials: [material])
        // Nudged behind the graffiti along the surface normal so it reads as
        // an outline/glow rather than fighting the artwork for the same depth.
        highlight.position = SIMD3(0, 0, -0.001)
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
