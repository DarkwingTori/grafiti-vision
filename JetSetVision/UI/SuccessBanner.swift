import SwiftUI

/// The success-toast counterpart to `ErrorBanner` — same shape and
/// placement conventions, green instead of red, for brief confirmations
/// like "SAVED TO PHOTOS".
struct SuccessBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.green.opacity(0.75), in: Capsule())
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isStaticText)
    }
}
