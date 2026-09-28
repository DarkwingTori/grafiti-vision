import ARKit
import SwiftUI

/// Main camera/AR screen. Requests camera access, then hosts the live
/// AR session and surfaces its tracking/plane-detection state as the
/// SEARCHING / TRACKING LIMITED / SURFACE DETECTED banner from the spec.
struct CameraView: View {
    @StateObject private var sessionManager = ARSessionManager()
    @StateObject private var placementController = GraffitiPlacementController()
    @State private var permissionStatus: CameraPermissionService.Status = .notDetermined

    var body: some View {
        ZStack {
            switch permissionStatus {
            case .authorized:
                arContent
            case .denied:
                permissionDeniedView
            case .notDetermined:
                Color.black.ignoresSafeArea()
            }
        }
        .onAppear(perform: resolvePermission)
    }

    private var arContent: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(sessionManager: sessionManager, placementController: placementController)
                .ignoresSafeArea()

            if placementController.hasSelection {
                deleteButton
            }

            VStack(spacing: 16) {
                statusBanner
                GraffitiPicker(controller: placementController)
            }
            .padding(.bottom, 32)
        }
    }

    private var deleteButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    placementController.deleteSelected()
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(.red.opacity(0.85), in: Circle())
                }
                .accessibilityLabel("Delete selected graffiti")
                .padding(.trailing, 20)
                .padding(.top, 56)
            }
            Spacer()
        }
    }

    private var statusBanner: some View {
        VStack(spacing: 8) {
            Text(statusTitle)
                .font(.system(size: 15, weight: .black, design: .monospaced))
            if let statusSubtitle {
                Text(statusSubtitle)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .opacity(0.7)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.black.opacity(0.55), in: Capsule())
        .animation(.easeInOut(duration: 0.2), value: statusTitle)
    }

    private var statusTitle: String {
        switch sessionManager.trackingStatus {
        case .searching:
            return "SEARCHING FOR SURFACE..."
        case .limited:
            return "TRACKING LIMITED"
        case .normal:
            switch sessionManager.targetedSurface {
            case .floor:
                return "FLOOR DETECTED"
            case .wall:
                return "WALL DETECTED"
            case nil:
                return "NO USABLE SURFACE"
            }
        }
    }

    private var statusSubtitle: String? {
        switch sessionManager.trackingStatus {
        case .searching:
            return nil
        case .limited(let reason):
            return limitedReasonMessage(reason)
        case .normal:
            return sessionManager.targetedSurface == nil ? "TRY A FLAT WALL OR FLOOR" : "TAP TO SPRAY"
        }
    }

    private func limitedReasonMessage(_ reason: ARCamera.TrackingState.Reason) -> String {
        switch reason {
        case .excessiveMotion:
            return "MOVE YOUR PHONE SLOWLY"
        case .insufficientFeatures:
            return "POINT AT A TEXTURED SURFACE"
        case .initializing:
            return "STARTING UP..."
        case .relocalizing:
            return "RELOCALIZING..."
        @unknown default:
            return "MOVE YOUR PHONE SLOWLY"
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Text("CAMERA ACCESS NEEDED")
                .font(.system(size: 22, weight: .black, design: .rounded))
            Text("Jet Set Vision uses your camera to detect real-world surfaces and place AR graffiti on them. Enable camera access in Settings to continue.")
                .font(.system(size: 14, weight: .medium))
                .multilineTextAlignment(.center)
                .opacity(0.7)
                .padding(.horizontal, 32)
            Button("OPEN SETTINGS") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .padding()
            .background(.white, in: Capsule())
            .foregroundStyle(.black)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }

    private func resolvePermission() {
        switch CameraPermissionService.currentStatus {
        case .authorized:
            permissionStatus = .authorized
        case .denied:
            permissionStatus = .denied
        case .notDetermined:
            CameraPermissionService.requestAccess { granted in
                permissionStatus = granted ? .authorized : .denied
            }
        }
    }
}

#Preview {
    CameraView()
        .environmentObject(AppState())
}
