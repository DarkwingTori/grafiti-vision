import ARKit
import Combine
import RealityKit

/// Places, selects, and removes graffiti entities in the AR scene.
///
/// Tapping an empty detected surface sprays the currently selected
/// `GraffitiAsset` there: the tap's screen point becomes an AR raycast
/// against existing plane geometry, and the raycast's `worldTransform`
/// already carries the surface's orientation (its up-axis matches the
/// surface normal), so the graffiti naturally faces out from a wall or
/// lies flat on a floor with no extra rotation math needed. Move/rotate/
/// scale are handled by RealityKit's built-in entity gestures rather than
/// custom gesture code. Tapping an existing piece selects it, enabling the
/// delete button.
final class GraffitiPlacementController: ObservableObject {
    private struct Instance {
        let anchorEntity: AnchorEntity
        let modelEntity: ModelEntity
    }

    @Published var selectedAsset: GraffitiAsset = GraffitiAsset.library[0]
    @Published private(set) var hasSelection = false

    private weak var arView: ARView?
    private var instances: [UUID: Instance] = [:]
    private var selectedInstanceID: UUID?

    func attach(to arView: ARView) {
        self.arView = arView
    }

    func handleTap(at location: CGPoint) {
        guard let arView else { return }

        if let hitEntity = arView.entity(at: location),
           let id = UUID(uuidString: hitEntity.name),
           instances[id] != nil {
            select(id)
            return
        }

        guard let result = arView.raycast(from: location, allowing: .existingPlaneGeometry, alignment: .any).first else {
            return
        }
        place(at: result)
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

        let anchorEntity = AnchorEntity(world: result.worldTransform)
        anchorEntity.addChild(model)
        arView.scene.addAnchor(anchorEntity)
        arView.installGestures([.translation, .rotation, .scale], for: model)

        instances[id] = Instance(anchorEntity: anchorEntity, modelEntity: model)
        select(id)
    }

    private func select(_ id: UUID) {
        selectedInstanceID = id
        hasSelection = true
    }
}
