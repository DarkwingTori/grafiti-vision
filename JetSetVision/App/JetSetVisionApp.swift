import SwiftUI

@main
struct JetSetVisionApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            CameraView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }
}
