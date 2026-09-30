import RealityKit
import UIKit

/// Bridges the capture button to the underlying `ARView`'s snapshot API,
/// which composites the live camera feed with rendered RealityKit content —
/// exactly the "real world + graffiti" image the spec calls for.
final class ARCaptureController: ObservableObject {
    @Published private(set) var isCapturing = false
    @Published var lastError: String?

    private weak var arView: ARView?

    func attach(to arView: ARView) {
        self.arView = arView
    }

    func capture(placementController: GraffitiPlacementController, completion: ((Capture) -> Void)? = nil) {
        guard let arView, !isCapturing else { return }
        isCapturing = true

        // The selection highlight is a UI affordance, not part of the
        // creation — hide it for the duration of the snapshot.
        placementController.hideHighlightForCapture()

        arView.snapshot(saveToHDR: false) { [weak self, weak placementController] image in
            placementController?.restoreHighlightAfterCapture()
            guard let self else { return }

            guard let image else {
                DispatchQueue.main.async {
                    self.isCapturing = false
                    self.lastError = "CAPTURE FAILED — TRY AGAIN"
                }
                return
            }

            let assetName = placementController?.selectedAsset.name

            // JPEG encoding + disk write can take a moment for a full-res
            // snapshot — keep it off the main thread so the UI doesn't hitch.
            DispatchQueue.global(qos: .utility).async {
                let saved = CaptureStore.shared.save(image: image, graffitiAssetName: assetName)
                DispatchQueue.main.async {
                    self.isCapturing = false
                    if let saved {
                        self.lastError = nil
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        completion?(saved)
                    } else {
                        self.lastError = "CAPTURE FAILED — TRY AGAIN"
                    }
                }
            }
        }
    }
}
