import ARKit
import Vision

/// Runs real Apple Vision requests against live AR camera frames and
/// publishes their actual results — no hardcoded labels or confidence
/// values, per the product spec's honesty requirement.
///
/// Two stock, zero-setup Vision requests are used: `VNClassifyImageRequest`
/// (general "what is the camera looking at" scene/object classification)
/// and `VNDetectHumanRectanglesRequest` (person detection, with real
/// bounding boxes). Both ship with Vision itself — no model bundling.
///
/// ARKit's `capturedImage` pixel buffer comes straight from the camera
/// sensor, which is always landscape regardless of how the device is held.
/// Since this app is portrait-only (see `Info.plist`), the fixed `.right`
/// `CGImagePropertyOrientation` below is the correct, standard mapping from
/// sensor space into what Vision expects for a portrait UI.
final class VisionProcessor: ObservableObject {
    struct Classification: Identifiable, Equatable {
        let id = UUID()
        let label: String
        let confidence: Float
    }

    @Published var topClassifications: [Classification] = []
    @Published var personConfidence: Float?
    @Published var personBoundingBox: CGRect?
    @Published var lastError: String?

    /// Only Vision Mode should pay the cost of running Vision requests —
    /// Spray Mode leaves this false so no CPU/battery goes to processing
    /// frames nobody is looking at.
    var isActive = false

    /// Throttles processing to roughly 8fps — comfortably inside the
    /// spec's "5-15fps" Vision guidance and well below AR's ~60fps tracking.
    private let processingInterval: TimeInterval = 0.12
    private var lastProcessedTime: TimeInterval = 0
    private var isProcessing = false

    /// Minimum confidence before a classification is worth showing —
    /// otherwise low-signal labels clutter the overlay with noise.
    private let confidenceThreshold: Float = 0.15

    private let classificationRequest = VNClassifyImageRequest()
    private let personRequest = VNDetectHumanRectanglesRequest()
    private let queue = DispatchQueue(label: "com.torienmitchell.JetSetVision.vision", qos: .userInitiated)

    /// Called from `ARSessionManager.session(_:didUpdate:)` on every AR
    /// frame; throttles and bails out immediately unless Vision Mode is on.
    func consume(frame: ARFrame) {
        guard isActive, !isProcessing else { return }
        let now = Date().timeIntervalSinceReferenceDate
        guard now - lastProcessedTime >= processingInterval else { return }
        lastProcessedTime = now
        isProcessing = true

        let pixelBuffer = frame.capturedImage
        queue.async { [weak self] in
            self?.runRequests(on: pixelBuffer)
        }
    }

    private func runRequests(on pixelBuffer: CVPixelBuffer) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])

        do {
            try handler.perform([classificationRequest, personRequest])

            let classifications = (classificationRequest.results ?? [])
                .filter { $0.confidence >= confidenceThreshold }
                .prefix(3)
                .map {
                    Classification(
                        label: $0.identifier.replacingOccurrences(of: "_", with: " ").uppercased(),
                        confidence: $0.confidence
                    )
                }
            let people = personRequest.results ?? []
            let topPerson = people.max(by: { $0.confidence < $1.confidence })

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.topClassifications = Array(classifications)
                self.personConfidence = topPerson?.confidence
                self.personBoundingBox = topPerson?.boundingBox
                self.lastError = nil
                self.isProcessing = false
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.lastError = "VISION UNAVAILABLE"
                self?.isProcessing = false
            }
        }
    }
}
