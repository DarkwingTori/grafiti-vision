import Photos
import UIKit

/// Saves a capture to the user's Photos library. Requests add-only
/// authorization (`.addOnly`) rather than full library access, since the
/// app only ever writes captures out — it never reads the user's library.
enum PhotoLibrarySaver {
    enum SaveError: Error {
        case accessDenied
        case saveFailed
    }

    static func save(_ image: UIImage, completion: @escaping (Result<Void, SaveError>) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            switch status {
            case .authorized, .limited:
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                } completionHandler: { success, _ in
                    DispatchQueue.main.async {
                        completion(success ? .success(()) : .failure(.saveFailed))
                    }
                }
            default:
                DispatchQueue.main.async {
                    completion(.failure(.accessDenied))
                }
            }
        }
    }
}
