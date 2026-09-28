import ARKit
import Combine
import RealityKit
import SwiftUI

/// Bridges RealityKit's `ARView` into SwiftUI: configures world tracking with
/// horizontal + vertical plane detection, wires plane visualization, and
/// continuously raycasts from screen center against detected planes so the
/// UI can tell the user what surface they're currently pointing at.
struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var sessionManager: ARSessionManager
    @ObservedObject var placementController: GraffitiPlacementController

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic

        arView.session.delegate = sessionManager
        arView.session.run(configuration)

        sessionManager.planeDetector = context.coordinator.planeDetector(for: arView)
        context.coordinator.startRaycasting(on: arView, sessionManager: sessionManager)
        context.coordinator.configureTapToPlace(on: arView, placementController: placementController)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject {
        private var detector: PlaneDetector?
        private var updateSubscription: Cancellable?
        private var lastRaycastTime: TimeInterval = 0
        private let raycastInterval: TimeInterval = 0.2
        private var placementController: GraffitiPlacementController?

        func planeDetector(for arView: ARView) -> PlaneDetector {
            let detector = PlaneDetector(arView: arView)
            self.detector = detector
            return detector
        }

        /// Raycasts from the center of the screen against detected plane
        /// geometry on every rendered frame (throttled), rather than only on
        /// tap — this is what drives the live "WALL DETECTED" / "FLOOR
        /// DETECTED" status the user sees while just pointing the camera.
        /// Tap-to-place (Phase 3) will reuse this same raycast on demand.
        func startRaycasting(on arView: ARView, sessionManager: ARSessionManager) {
            updateSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self, weak arView, weak sessionManager] _ in
                guard let self, let arView, let sessionManager else { return }
                let now = Date().timeIntervalSinceReferenceDate
                guard now - self.lastRaycastTime >= self.raycastInterval else { return }
                self.lastRaycastTime = now

                let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
                let results = arView.raycast(from: center, allowing: .existingPlaneGeometry, alignment: .any)

                guard let planeAnchor = results.first?.anchor as? ARPlaneAnchor else {
                    sessionManager.targetedSurface = nil
                    return
                }
                sessionManager.targetedSurface = planeAnchor.alignment == .horizontal ? .floor : .wall
            }
        }

        /// Wires a tap recognizer that either selects an existing graffiti
        /// entity or, when the tap lands on bare detected surface, sprays
        /// the currently selected design there.
        func configureTapToPlace(on arView: ARView, placementController: GraffitiPlacementController) {
            self.placementController = placementController
            placementController.attach(to: arView)

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            arView.addGestureRecognizer(tap)
        }

        @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else { return }
            placementController?.handleTap(at: recognizer.location(in: arView))
        }
    }
}
