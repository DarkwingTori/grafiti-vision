import ARKit
import RealityKit
import UIKit

/// Renders a translucent overlay for each ARKit-detected plane so the user
/// can see which surfaces the app considers usable for graffiti placement.
///
/// `ARPlaneAnchor.center`/`planeExtent` describe the plane's boundary in the
/// anchor's own local space; the anchor's transform (attached via
/// `AnchorEntity(anchor:)`) already accounts for the plane's real-world
/// position and orientation, including the rotation that distinguishes a
/// vertical wall from a horizontal floor/table.
final class PlaneDetector {
    private weak var arView: ARView?
    private var entities: [UUID: (anchorEntity: AnchorEntity, model: ModelEntity)] = [:]

    init(arView: ARView) {
        self.arView = arView
    }

    func addPlane(_ plane: ARPlaneAnchor) {
        guard let arView else { return }
        let anchorEntity = AnchorEntity(anchor: plane)
        let model = ModelEntity()
        apply(plane, to: model)
        anchorEntity.addChild(model)
        arView.scene.addAnchor(anchorEntity)
        entities[plane.identifier] = (anchorEntity, model)
    }

    func updatePlane(_ plane: ARPlaneAnchor) {
        guard let entry = entities[plane.identifier] else {
            addPlane(plane)
            return
        }
        apply(plane, to: entry.model)
    }

    func removePlane(_ plane: ARPlaneAnchor) {
        guard let entry = entities.removeValue(forKey: plane.identifier), let arView else { return }
        arView.scene.removeAnchor(entry.anchorEntity)
    }

    private func apply(_ plane: ARPlaneAnchor, to model: ModelEntity) {
        let mesh = MeshResource.generatePlane(width: plane.planeExtent.width, depth: plane.planeExtent.height)
        var material = UnlitMaterial(color: color(for: plane.alignment).withAlphaComponent(0.35))
        material.blending = .transparent(opacity: .init(floatLiteral: 1.0))
        model.model = ModelComponent(mesh: mesh, materials: [material])
        model.position = plane.center
        model.orientation = simd_quatf(angle: plane.planeExtent.rotationOnYAxis, axis: [0, 1, 0])
    }

    private func color(for alignment: ARPlaneAnchor.Alignment) -> UIColor {
        switch alignment {
        case .horizontal:
            return .systemGreen
        case .vertical:
            return .systemPink
        @unknown default:
            return .systemYellow
        }
    }
}
