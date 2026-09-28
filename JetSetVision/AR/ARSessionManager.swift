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

    /// Set by `ARViewContainer` once the RealityKit view exists, so plane
    /// anchor callbacks below can drive visualization.
    weak var planeDetector: PlaneDetector?
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

    func session(_ session: ARSession, didFailWithError error: Error) {
        trackingStatus = .searching
    }
}
