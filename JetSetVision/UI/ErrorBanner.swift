import SwiftUI

/// Shared styling for every inline error message in the app (AR session
/// failures, capture failures, sticker-extraction failures) so they all
/// read as the same "something went wrong" affordance rather than each
/// screen inventing its own look.
struct ErrorBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.red.opacity(0.75), in: Capsule())
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isStaticText)
    }
}
