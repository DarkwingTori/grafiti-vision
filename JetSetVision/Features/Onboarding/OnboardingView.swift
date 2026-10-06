import SwiftUI

/// A short first-launch walkthrough — shown once (gated by a `UserDefaults`
/// flag in `CameraView`), not a generic marketing carousel: each card
/// describes the actual interaction the app has, in the order a new user
/// would naturally hit it.
struct OnboardingView: View {
    let onFinish: () -> Void

    private struct Card {
        let title: String
        let body: String
        let systemImage: String
    }

    private let cards: [Card] = [
        Card(title: "SPRAY MODE", body: "Point your camera at a wall or floor. Once it's detected, tap it to spray your selected graffiti there — drag, rotate, and pinch to adjust.", systemImage: "wand.and.rays"),
        Card(title: "VISION MODE", body: "Switch to VISION to see what your camera actually recognizes in real time — live object and person detection, not canned labels.", systemImage: "eye"),
        Card(title: "CAPTURE", body: "Tap the shutter to save a photo of your creation composited into the real scene.", systemImage: "camera"),
        Card(title: "GALLERY", body: "Browse everything you've captured, then share or save it to Photos.", systemImage: "photo.stack")
    ]

    @State private var pageIndex = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                TabView(selection: $pageIndex) {
                    ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                        cardView(card).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button(pageIndex == cards.count - 1 ? "GET STARTED" : "NEXT") {
                    if pageIndex == cards.count - 1 {
                        onFinish()
                    } else {
                        withAnimation { pageIndex += 1 }
                    }
                }
                .font(.system(size: 15, weight: .black, design: .monospaced))
                .foregroundStyle(.black)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(.white, in: Capsule())
                .padding(.bottom, 32)
                .accessibilityIdentifier(pageIndex == cards.count - 1 ? "GetStarted" : "Next")
            }
        }
    }

    private func cardView(_ card: Card) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: card.systemImage)
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(.white)
            Text(card.title)
                .font(.system(size: 24, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
            Text(card.body)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
