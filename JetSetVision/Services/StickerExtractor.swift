import UIKit
import Vision

/// Turns a photo into a sticker by cutting out its foreground subject with
/// a transparent background — the same subject-lifting capability iOS
/// itself uses when you drag a subject off a photo in Messages/Photos,
/// built directly on Apple's `VNGenerateForegroundInstanceMaskRequest`
/// rather than a third-party cutout library.
enum StickerExtractor {
    enum ExtractionError: Error {
        case noSubjectFound
        case invalidImage
        case processingFailed
    }

    static func extractSticker(from image: UIImage) throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw ExtractionError.invalidImage
        }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.cgImagePropertyOrientation, options: [:])

        do {
            try handler.perform([request])
        } catch {
            throw ExtractionError.processingFailed
        }

        guard let result = request.results?.first, !result.allInstances.isEmpty else {
            throw ExtractionError.noSubjectFound
        }

        let maskBuffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
        let maskImage = CIImage(cvPixelBuffer: maskBuffer)
        let sourceImage = CIImage(cgImage: cgImage)

        // Scale the mask (sized to the processed image) up to the source
        // image's resolution before compositing.
        let scaleX = sourceImage.extent.width / maskImage.extent.width
        let scaleY = sourceImage.extent.height / maskImage.extent.height
        let scaledMask = maskImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let cutout = sourceImage.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputMaskImageKey: scaledMask
        ])

        let context = CIContext()
        guard let outputCGImage = context.createCGImage(cutout, from: sourceImage.extent) else {
            throw ExtractionError.processingFailed
        }

        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: .up)
    }
}

private extension UIImage {
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
