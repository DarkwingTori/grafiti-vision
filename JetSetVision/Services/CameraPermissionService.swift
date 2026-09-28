import AVFoundation

/// Thin wrapper around `AVCaptureDevice` authorization so views don't talk
/// to AVFoundation directly. ARKit needs camera access to run at all, so this
/// is checked before an `ARSession` is ever started.
enum CameraPermissionService {
    enum Status {
        case authorized
        case denied
        case notDetermined
    }

    static var currentStatus: Status {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    static func requestAccess(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async { completion(granted) }
        }
    }
}
