import ARKit
import SwiftUI

/// Main camera/AR screen. Requests camera access, then hosts the live
/// AR session and surfaces its tracking/plane-detection state as the
/// SEARCHING / TRACKING LIMITED / SURFACE DETECTED banner from the spec.
/// Toggles between Spray Mode (graffiti placement) and Vision Mode
/// (live Vision-framework detections) without ever restarting the
/// underlying AR session — the camera stays the one continuous, central
/// experience per the navigation spec.
struct CameraView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var sessionManager = ARSessionManager()
    @StateObject private var placementController = GraffitiPlacementController()
    @StateObject private var visionProcessor = VisionProcessor()
    @StateObject private var captureController = ARCaptureController()
    @State private var permissionStatus: CameraPermissionService.Status = .notDetermined
    @State private var showGallery = false
    @State private var showCaptureFlash = false
    @Environment(\.scenePhase) private var scenePhase

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
        .onChange(of: scenePhase) { _, phase in
            // Save whenever the app leaves the foreground, not just on
            // explicit quit — backgrounding is the reliable signal on iOS,
            // since a process can be killed outright with no further
            // notice once it's backgrounded.
            if phase != .active {
                sessionManager.saveWorldMap()
            }
        }
    }

    private var arContent: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(
                sessionManager: sessionManager,
                placementController: placementController,
                appState: appState,
                captureController: captureController
            )
            .ignoresSafeArea()
            .onAppear { sessionManager.visionProcessor = visionProcessor }
            .onChange(of: appState.mode) { _, mode in
                visionProcessor.isActive = (mode == .vision)
            }

            if appState.mode == .vision {
                VisionModeView(processor: visionProcessor)
            }

            if placementController.hasSelection && appState.mode == .spray {
                deleteButton
            }

            topBar

            VStack(spacing: 16) {
                if let sessionError = sessionManager.sessionError {
                    errorBanner(sessionError)
                } else if let captureError = captureController.lastError {
                    errorBanner(captureError)
                } else {
                    statusBanner
                }

                if appState.mode == .spray {
                    GraffitiPicker(controller: placementController)
                }

                captureButton
            }
            .padding(.bottom, 32)

            if showCaptureFlash {
                Color.white.opacity(0.85).ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showGallery) {
            GalleryView()
        }
    }

    private var topBar: some View {
        VStack {
            HStack {
                modeToggle
                Spacer()
                galleryButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
            Spacer()
        }
    }

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeButton(title: "SPRAY", mode: .spray)
            modeButton(title: "VISION", mode: .vision)
        }
        .background(.black.opacity(0.55), in: Capsule())
    }

    private func modeButton(title: String, mode: AppState.Mode) -> some View {
        let isSelected = appState.mode == mode
        return Button {
            appState.mode = mode
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundStyle(isSelected ? .black : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.white : Color.clear, in: Capsule())
        }
        .accessibilityLabel("\(title.capitalized) mode")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var galleryButton: some View {
        Button {
            showGallery = true
        } label: {
            Image(systemName: "photo.stack.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .padding(12)
                .background(.black.opacity(0.55), in: Circle())
        }
        .accessibilityLabel("Open gallery")
    }

    private var captureButton: some View {
        Button {
            capture()
        } label: {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 64, height: 64)
                Circle()
                    .stroke(.black.opacity(0.2), lineWidth: 3)
                    .frame(width: 64, height: 64)
            }
        }
        .disabled(captureController.isCapturing)
        .accessibilityLabel("Capture scene")
    }

    private func capture() {
        captureController.capture(placementController: placementController) { _ in
            withAnimation(.easeOut(duration: 0.08)) { showCaptureFlash = true }
            withAnimation(.easeIn(duration: 0.25).delay(0.08)) { showCaptureFlash = false }
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
                .padding(.top, 110)
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

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.red.opacity(0.75), in: Capsule())
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
            return sessionManager.isRestoringPreviousSession ? "RESTORING YOUR LAST SESSION..." : "RELOCALIZING..."
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
