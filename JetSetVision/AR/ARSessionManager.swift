import ARKit
import Combine

/// Owns the ARSession lifecycle and publishes tracking/plane state for the UI.
///
/// ARKit reports tracking quality through `ARCamera.TrackingState`; this class
/// translates that into the SEARCHING / TRACKING LIMITED / SURFACE DETECTED
/// messaging described in the product spec, and forwards plane anchor
/// lifecycle events to `PlaneDetector` for visualization.
final class ARSessionManager: NSObject, ObservableObject {
    enum TrackingStatus: Equatable {
        case searching
        case limited(ARCamera.TrackingState.Reason)
        case normal
    }

    enum SurfaceKind {
        case wall
        case floor
    }

    @Published var trackingStatus: TrackingStatus = .searching
    @Published var targetedSurface: SurfaceKind?
    @Published var sessionError: String?

    /// Set by `ARViewContainer` once the RealityKit view exists, so plane
    /// anchor callbacks below can drive visualization.
    weak var planeDetector: PlaneDetector?

    /// Set by `CameraView` so every AR frame can be offered to Vision Mode's
    /// processor — `VisionProcessor` itself no-ops unless Vision Mode is on.
    weak var visionProcessor: VisionProcessor?
}

extension ARSessionManager: ARSessionDelegate {
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            trackingStatus = .searching
        case .limited(let reason):
            trackingStatus = .limited(reason)
        case .normal:
            trackingStatus = .normal
            sessionError = nil
        }
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let plane = anchor as? ARPlaneAnchor else { continue }
            planeDetector?.addPlane(plane)
        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let plane = anchor as? ARPlaneAnchor else { continue }
            planeDetector?.updatePlane(plane)
        }
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let plane = anchor as? ARPlaneAnchor else { continue }
            planeDetector?.removePlane(plane)
        }
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        visionProcessor?.consume(frame: frame)
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        trackingStatus = .searching
        sessionError = error.localizedDescription
    }

    func sessionWasInterrupted(_ session: ARSession) {
        sessionError = "AR SESSION INTERRUPTED"
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        sessionError = nil
    }
}
