import SwiftUI

/// Phase 1 placeholder screen. The live AR camera session (ARSession,
/// world tracking, plane detection) is introduced in Phase 2 — for now
/// this just establishes the app's entry point and navigation shell.
struct CameraView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                Text("JET SET VISION")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("CAMERA COMING IN PHASE 2")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}

#Preview {
    CameraView()
        .environmentObject(AppState())
}
