import SwiftUI

/// Overlay shown while `AppState.mode == .vision`: renders whatever
/// `VisionProcessor` actually detected, honestly — no fabricated labels or
/// confidence values, and an explicit message when nothing is recognizable
/// rather than a silent blank screen.
struct VisionModeView: View {
    @ObservedObject var processor: VisionProcessor

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                if let box = processor.personBoundingBox {
                    personBox(box, in: proxy.size)
                }
            }
        }
        .allowsHitTesting(false)
        .animation(.easeOut(duration: 0.15), value: processor.personBoundingBox)
        .overlay(alignment: .top) {
            detectionList
                .padding(.top, 12)
                .animation(.easeInOut(duration: 0.2), value: processor.topClassifications)
                .animation(.easeInOut(duration: 0.2), value: processor.personConfidence)
        }
    }

    private var detectionList: some View {
        VStack(spacing: 8) {
            Text("VISION MODE")
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(.black.opacity(0.6), in: Capsule())

            if let error = processor.lastError {
                detectionChip(label: error, confidence: nil)
            } else if processor.topClassifications.isEmpty && processor.personConfidence == nil {
                detectionChip(label: "NO DETECTIONS YET", confidence: nil)
            } else {
                ForEach(processor.topClassifications) { classification in
                    detectionChip(label: classification.label, confidence: classification.confidence)
                }
                if let personConfidence = processor.personConfidence {
                    detectionChip(label: "PERSON", confidence: personConfidence)
                }
            }
        }
    }

    private func detectionChip(label: String, confidence: Float?) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
            if let confidence {
                Text("\(Int(confidence * 100))%")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .opacity(0.8)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.black.opacity(0.55), in: Capsule())
    }

    /// Vision's bounding boxes are normalized with a bottom-left origin;
    /// SwiftUI views use a top-left origin, so the y-axis is flipped here.
    private func personBox(_ box: CGRect, in size: CGSize) -> some View {
        let rect = CGRect(
            x: box.minX * size.width,
            y: (1 - box.maxY) * size.height,
            width: box.width * size.width,
            height: box.height * size.height
        )
        return RoundedRectangle(cornerRadius: 8)
            .stroke(Color.yellow, lineWidth: 2)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }
}
