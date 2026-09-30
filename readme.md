# Jet Set Vision

> Turn the physical world into a digital graffiti canvas.

Jet Set Vision is a native iOS computer-vision and augmented-reality application inspired by the energy, visual language, and urban creativity of graffiti/skate culture and games like *Jet Set Radio*.

The app allows users to point their iPhone camera at the real world, identify suitable surfaces, place original digital graffiti onto those surfaces, and move around the environment while the graffiti remains anchored in physical space.

The project is primarily a **computer vision + on-device ML + AR systems project**, not simply a graffiti drawing application.

---

## Status

**Phases 1–9 complete — full MVP.** Users can pick a graffiti design, tap a detected wall/floor to spray it there (anchored via AR raycast, oriented to the surface), move/rotate/scale/delete it, switch to Vision Mode to see live Apple Vision detections (real scene classification + person detection, no fabricated labels), capture the AR scene as a still image, and browse/delete saved captures in the gallery.

**Vision Mode** runs `VNClassifyImageRequest` (general scene/object classification) and `VNDetectHumanRectanglesRequest` (person detection with a real bounding box) against `ARFrame.capturedImage`, throttled to ~8fps and only while Vision Mode is active, off the main thread. Whatever it shows came from an actual Vision result — if nothing is recognized, it says so rather than guessing.

**Capture** uses RealityKit's `ARView.snapshot(saveToHDR:)`, which composites the live camera feed with rendered graffiti into one image. **Persistence** is a Codable JSON index (`CaptureStore`) plus JPEGs in the app's Documents directory — no database framework, since a personal collection of captures with no relational querying doesn't need one.

Graffiti artwork lives in `Assets.xcassets` as `Graffiti_*` image sets, sourced from `~/Desktop/graffiti`. Per the developer, Sega permits non-commercial personal use of this Jet Set Radio–style artwork — this has not been independently verified, so treat this build as personal/local use only unless that's confirmed further before any public sharing, demo, or distribution.

Graffiti artwork lives in `Assets.xcassets` as `Graffiti_*` image sets, sourced from `~/Desktop/graffiti`. Per the developer, Sega permits non-commercial personal use of this Jet Set Radio–style artwork — this has not been independently verified, so treat this build as personal/local use only unless that's confirmed further before any public sharing, demo, or distribution.

## Setup

The project file is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen) from `project.yml` rather than committed by hand.

```bash
brew install xcodegen   # one-time
xcodegen generate       # regenerates JetSetVision.xcodeproj from project.yml
open JetSetVision.xcodeproj
```

## Run

1. Open `JetSetVision.xcodeproj` in Xcode.
2. Select the `JetSetVision` target > Signing & Capabilities, and set your Team to your free Personal Team (no paid Apple Developer Program account required).
3. Select your iPhone as the run destination and press Run. (A plain iOS Simulator build also works for compiling, but ARKit features in later phases require a physical device.)

---

## 1. Project Goals

The project should demonstrate practical understanding of:

* Computer vision
* On-device machine learning
* Image segmentation
* Scene understanding
* Surface/plane detection
* Camera-based perception
* AR world tracking
* Spatial anchoring
* Real-time rendering
* iOS development
* Swift / SwiftUI
* Vision
* ARKit
* RealityKit
* Mobile performance constraints
* Human-computer interaction

The project should be technically interesting enough to discuss with engineers working on Apple's Vision Systems / Computer Vision / On-Device ML teams.

The goal is **not** to recreate *Jet Set Radio*.

Instead, Jet Set Radio is the creative inspiration for an original technical project.

---

# 2. Core Product Concept

The core experience:

```text
User opens Jet Set Vision
        ↓
Camera starts
        ↓
App observes the environment
        ↓
ARKit tracks the device and environment
        ↓
Vision analyzes the camera frame
        ↓
App identifies usable surfaces
        ↓
User selects a graffiti design
        ↓
User taps a detected surface
        ↓
Graffiti is placed onto the physical surface
        ↓
ARKit maintains its position in the environment
        ↓
User moves around
        ↓
Graffiti remains anchored
        ↓
User can capture/share the result
```

The experience should feel like:

> "What if my camera could turn the real world into a graffiti canvas?"

---

# 3. MVP

The first version should prioritize a polished, reliable MVP over excessive features.

## MVP Features

### 3.1 Camera / AR View

The main screen displays the live camera feed with an AR scene.

Requirements:

* Rear camera
* ARKit world tracking
* Camera permissions
* Plane detection
* Real-world tracking
* Basic environment understanding

---

### 3.2 Surface Detection

The app should identify surfaces that are appropriate for graffiti placement.

Initial supported surfaces:

* Walls
* Floors
* Tables
* Doors
* Other large flat surfaces

The MVP can initially rely heavily on ARKit's plane detection.

The interface should visually communicate when a usable surface has been detected.

Example:

```text
┌──────────────────────────────────┐
│                                  │
│       CAMERA VIEW                │
│                                  │
│      ┌───────────────┐           │
│      │ SURFACE       │           │
│      │ DETECTED      │           │
│      └───────────────┘           │
│                                  │
│                                  │
│                                  │
│   ● Wall detected                │
│                                  │
│        [ SPRAY ]                 │
└──────────────────────────────────┘
```

---

### 3.3 Graffiti Selection

Users should be able to choose from a collection of original graffiti designs.

Example categories:

* Tags
* Characters
* Symbols
* Arrows
* Abstract shapes
* Stickers
* Typography
* Patterns

Do NOT use copyrighted Jet Set Radio artwork, characters, logos, fonts, or extracted assets.

Create an original visual identity inspired by:

* 2000s street art
* Skate culture
* Sticker art
* Urban typography
* Graffiti
* Bright graphic shapes
* Music/game UI energy

---

### 3.4 Graffiti Placement

The user should be able to:

1. Select graffiti.
2. Point at a detected surface.
3. Tap the surface.
4. Place the graffiti.
5. Adjust its position.
6. Rotate it.
7. Scale it.

Minimum MVP controls:

```text
Move
Rotate
Scale
Delete
```

---

### 3.5 Persistent AR Anchoring

Once graffiti is placed:

* It should remain attached to the detected surface.
* Moving the camera should not cause the graffiti to float independently.
* Walking around the graffiti should preserve its spatial position.

ARKit/RealityKit should handle the spatial tracking.

---

### 3.6 Screenshot / Capture

Users should be able to capture the AR scene.

The result should show:

```text
Real-world environment
+
Digital graffiti
```

The capture should be suitable for sharing.

---

# 4. Vision Mode

Vision Mode is the feature that makes the application more explicitly computer-vision focused.

The user can toggle:

```text
SPRAY MODE
VISION MODE
```

In Vision Mode, the app provides visual information about what the camera is seeing.

Example:

```text
┌──────────────────────────────────┐
│ VISION MODE                      │
│                                  │
│        [ CAMERA ]                │
│                                  │
│     ┌──────────────┐             │
│     │ WALL         │             │
│     │ 94%          │             │
│     └──────────────┘             │
│                                  │
│     ┌──────────────┐             │
│     │ PERSON       │             │
│     │ 87%          │             │
│     └──────────────┘             │
│                                  │
│ Surface: Vertical                │
│ Tracking: Stable                 │
│                                  │
│        [ SPRAY ]                 │
└──────────────────────────────────┘
```

The exact Vision functionality can evolve based on what is practical using Apple's frameworks.

Potential Vision features:

* Object detection
* Object classification
* Image segmentation
* Subject lifting
* Person detection
* Human body/pose detection
* Visual similarity
* Image analysis

Do not implement unnecessary ML models simply to make the app appear more sophisticated.

Prefer Apple's native frameworks when they provide the necessary capability.

---

# 5. Technical Architecture

## Technology Stack

### Language

Swift

### UI

SwiftUI

### Computer Vision

Apple Vision framework

### AR

ARKit

### 3D / Rendering

RealityKit

### Development Environment

Xcode

### Target

iPhone

### Backend

None for MVP.

The MVP should be primarily on-device.

---

# 6. Architecture

Use a modular architecture.

Suggested structure:

```text
JetSetVision/
│
├── App/
│   ├── JetSetVisionApp.swift
│   └── AppState.swift
│
├── Features/
│   ├── Camera/
│   │   ├── CameraView.swift
│   │   └── CameraViewModel.swift
│   │
│   ├── Spray/
│   │   ├── SprayView.swift
│   │   ├── GraffitiPicker.swift
│   │   └── GraffitiPlacementController.swift
│   │
│   ├── Vision/
│   │   ├── VisionModeView.swift
│   │   ├── VisionProcessor.swift
│   │   └── DetectionOverlay.swift
│   │
│   └── Gallery/
│       ├── GalleryView.swift
│       └── CaptureManager.swift
│
├── AR/
│   ├── ARViewContainer.swift
│   ├── ARSessionManager.swift
│   ├── PlaneDetector.swift
│   └── GraffitiAnchor.swift
│
├── Models/
│   ├── GraffitiAsset.swift
│   ├── SurfaceDetection.swift
│   └── VisionDetection.swift
│
├── Services/
│   ├── VisionService.swift
│   └── ImageCaptureService.swift
│
├── UI/
│   ├── Components/
│   ├── Theme/
│   └── Modifiers/
│
├── Assets/
│   └── Graffiti/
│
└── Resources/
```

The exact organization can change if Claude Code determines a cleaner Swift architecture.

Do not create unnecessary abstractions.

---

# 7. Data Flow

## AR Flow

```text
iPhone Camera
      ↓
ARSession
      ↓
World Tracking
      ↓
Plane Detection
      ↓
Detected ARPlaneAnchor
      ↓
User taps surface
      ↓
Raycast
      ↓
World position
      ↓
RealityKit Entity
      ↓
Graffiti anchored in world
```

---

## Vision Flow

```text
Camera Frame
      ↓
Vision Request
      ↓
VNImageRequestHandler
      ↓
Vision Model / Request
      ↓
Detection Results
      ↓
Confidence / Bounding Box
      ↓
SwiftUI Overlay
```

---

# 8. Design Philosophy

The application should feel like a mixture of:

* Modern Apple software
* Street art
* Skateboarding culture
* Experimental photography
* Urban exploration
* AR
* Gaming UI

Do not make it look like a generic enterprise computer-vision demo.

Avoid:

* Generic blue gradients
* Generic AI chatbot aesthetics
* Excessive glassmorphism
* Corporate dashboard design
* Default SwiftUI styling everywhere
* Overly complicated HUDs

---

# 9. Visual Direction

The visual identity should use:

* High-contrast typography
* Bold graphic elements
* Sticker-like UI
* Graffiti-inspired shapes
* Sharp geometric layouts
* Playful animations
* Motion
* Urban photography
* Experimental typography

The UI can take inspiration from early-2000s gaming interfaces without copying any specific game's assets.

Potential visual language:

```text
SCAN
SPRAY
TAG
VISION
CAPTURE
```

Buttons should feel physical and tactile.

Example:

```text
        SPRAY
   ┌─────────────┐
   │      +      │
   └─────────────┘
```

---

# 10. Interaction Design

The application should prioritize camera-first interaction.

The primary interaction loop should be:

```text
Look
↓
Detect
↓
Select
↓
Spray
↓
Move
↓
Capture
```

The user should not have to navigate through multiple screens to place graffiti.

---

# 11. Modes

## Spray Mode

Primary experience.

Purpose:

Place graffiti into the real world.

---

## Vision Mode

Technical showcase.

Purpose:

Show what the computer vision system understands.

Possible overlays:

```text
Surface
Vertical plane
Tracking
Object
Confidence
```

---

## Gallery

Show captured creations.

Possible future functionality:

* Favorites
* Tags
* Location
* Creation date
* Revisit AR creations

---

# 12. Future Features

These are NOT required for the first MVP.

Possible future features:

### Advanced Surface Understanding

Distinguish:

```text
Wall
Floor
Table
Door
Window
Sign
```

---

### Smart Graffiti Placement

Automatically determine:

* Surface orientation
* Surface boundaries
* Best placement location
* Perspective
* Scale

---

### Visual Style Transfer

Allow a photograph to influence graffiti appearance.

Example:

```text
Photo
 ↓
Vision analysis
 ↓
Color palette
 ↓
Graffiti generation
```

---

### Visual Similarity

Allow users to photograph an existing graffiti design and find visually similar saved designs.

---

### Social Layer

Users could eventually:

* Share creations
* Follow artists
* View public graffiti
* Discover nearby creations

This should NOT be part of the MVP.

---

### Location-Based Graffiti

Graffiti could persist at a physical location.

Potential architecture:

```text
Physical Location
      ↓
Cloud Anchor / Spatial Persistence
      ↓
Graffiti
      ↓
Other users discover it
```

This requires backend/cloud infrastructure and should be treated as a future feature.

---

# 13. Performance Requirements

Because this is a mobile computer-vision application, performance matters.

Prioritize:

* Low latency
* Stable frame rate
* Low memory usage
* Battery awareness
* Efficient Vision requests
* Avoiding unnecessary image processing
* Avoiding processing every camera frame if unnecessary

Vision processing should be throttled when appropriate.

For example:

```text
Camera:
60 FPS

Vision:
5–15 FPS depending on workload
```

AR tracking should remain responsive even if Vision processing is throttled.

Do not block the main UI thread with expensive computer-vision operations.

---

# 14. Privacy

The application should process camera data locally whenever possible.

MVP architecture:

```text
Camera
  ↓
On-device processing
  ↓
Vision
  ↓
ARKit
  ↓
RealityKit
```

No images should be uploaded to a server.

No account should be required.

No backend should be required.

---

# 15. Apple-Specific Engineering Goals

This project should demonstrate understanding of Apple's ecosystem.

Important concepts:

* Swift
* SwiftUI
* ARKit
* RealityKit
* Vision
* Core ML where appropriate
* Metal where appropriate
* Apple Silicon
* On-device ML
* Camera processing
* Spatial computing

The project should make it possible to discuss questions such as:

> How do you balance model accuracy against latency and power consumption on a mobile device?

> How does perception feed into an AR system?

> How do you keep computer vision processing from interfering with real-time rendering?

> How do you handle uncertainty in computer-vision predictions?

> What belongs on the CPU, GPU, or Neural Engine?

The project does not need to implement all of these systems itself.

The goal is to understand the engineering tradeoffs.

---

# 16. One-Week Development Plan

## Day 1 — Foundation

* Create Xcode project
* Configure SwiftUI
* Configure camera permissions
* Create basic camera/AR screen
* Verify app runs on physical iPhone
* Establish project architecture

Deliverable:

Camera/AR screen running on device.

---

## Day 2 — AR Tracking

Implement:

* ARSession
* World tracking
* Horizontal plane detection
* Vertical plane detection
* Plane visualization
* Raycasting

Deliverable:

User can point at a wall/table/floor and see detected surfaces.

---

## Day 3 — Graffiti

Implement:

* Graffiti asset model
* Graffiti picker
* Place graffiti
* Scale
* Rotate
* Move
* Delete

Deliverable:

User can place original graffiti onto a real surface.

---

## Day 4 — Vision

Implement:

* Vision processing
* Detection
* Confidence display
* Vision overlay
* Performance throttling

Deliverable:

App can visually communicate what the system understands.

---

## Day 5 — Capture / Persistence

Implement:

* Screenshot capture
* Local gallery
* Creation metadata
* Delete creation
* Basic persistence

Deliverable:

User can save and review creations.

---

## Day 6 — Polish

Improve:

* Animations
* Typography
* UI
* Loading states
* Error handling
* Surface detection feedback
* Accessibility
* Performance

---

## Day 7 — Demo

Create:

* README
* Architecture diagram
* Demo video
* Screenshots
* Technical explanation
* GitHub cleanup

Demo should be approximately:

60–90 seconds.

---

# 17. Demo Flow

Recommended demo:

### 0–10 seconds

Show app launch.

Text:

> "What if your camera could turn the real world into a graffiti canvas?"

### 10–25 seconds

Point camera at a wall.

Show surface detection.

### 25–40 seconds

Select graffiti.

Tap wall.

Graffiti appears.

### 40–55 seconds

Move around the graffiti.

Show that it remains anchored.

### 55–70 seconds

Open Vision Mode.

Show detections/confidence.

### 70–85 seconds

Capture result.

Show saved creation.

### 85–90 seconds

Show architecture:

```text
SwiftUI
+
Vision
+
ARKit
+
RealityKit
```

---

# 18. Engineering Principles

Claude Code should follow these principles:

### Build the smallest working version first.

Do not spend hours building abstractions before the basic experience works.

### Prefer native Apple APIs.

Use:

* Vision
* ARKit
* RealityKit
* SwiftUI

before introducing external libraries.

### Keep the app on-device.

No backend unless explicitly requested.

### Avoid unnecessary ML training.

Use Apple's existing models/frameworks unless custom ML is specifically necessary.

### Optimize for a physical-device demo.

The simulator is not the primary target.

### Make failures understandable.

If:

* no surface is detected
* tracking is limited
* camera permission is denied
* Vision returns no results

the UI should communicate what happened.

---

# 19. Constraints

The developer currently has:

* Mac
* Xcode
* VS Code
* Free Apple Developer account / Personal Team
* No paid Apple Developer Program membership

Therefore:

* Do not require paid Apple Developer Program features.
* Do not require App Store distribution.
* Do not require TestFlight.
* Do not require cloud infrastructure.
* Do not require paid APIs.
* Do not require a backend.
* Do not require a paid ML API.

The app should be buildable and testable locally.

---

# 20. What Success Looks Like

The MVP is successful if a person can:

1. Open Jet Set Vision.
2. Point the camera at a wall.
3. See that the surface is recognized.
4. Select graffiti.
5. Place it onto the wall.
6. Move around the environment.
7. See the graffiti remain spatially anchored.
8. Switch to Vision Mode.
9. See useful computer-vision information.
10. Capture the result.

The project should feel like a **real Apple-platform computer vision prototype**, not a tutorial project.

---

# 21. Project Positioning

When discussing this project professionally:

> Jet Set Vision is an iOS computer vision and AR prototype that uses Vision, ARKit, and RealityKit to understand physical surfaces and anchor digital graffiti in real-world environments.

Emphasize:

* Computer vision
* On-device processing
* Spatial understanding
* AR
* Real-time systems
* Mobile constraints
* Human-computer interaction

Do not describe it simply as:

> "A graffiti app."

---

# 22. Future Technical Questions

As development progresses, document engineering decisions around:

* Why use ARKit plane detection?
* Why use Vision?
* How frequently should Vision process frames?
* How is the raycast performed?
* How are coordinates transformed?
* How is graffiti orientation calculated?
* How are anchors managed?
* What happens when tracking quality decreases?
* How does the application handle occlusion?
* How can inference latency be reduced?
* How could Core ML models be integrated?
* How could Metal improve rendering?
* How could the application take advantage of Apple Neural Engine hardware?

These questions are part of the educational value of the project.

---

# 23. Final Principle

The most important idea:

> **Jet Set Vision should demonstrate how software can perceive the physical world, understand it, and interact with it.**

The graffiti is the interface.

The real project is:

**Perception → Understanding → Spatial Interaction → Real-Time Rendering**
