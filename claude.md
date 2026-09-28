# Claude Code Instructions — Jet Set Vision

You are the primary engineering agent for the Jet Set Vision iOS project.

Read `README.md` before making any changes.

Your job is to build the application incrementally, keep the project compiling, explain important technical decisions, and avoid unnecessary complexity.

---

# 1. Project Context

Jet Set Vision is a native iOS computer vision + augmented reality application.

Core concept:

> Turn the physical world into a digital graffiti canvas.

The application uses:

* Swift
* SwiftUI
* ARKit
* RealityKit
* Vision
* Core ML only when useful/necessary

The project is inspired by the energy of graffiti, skate culture, photography, and games such as Jet Set Radio.



---

# 2. Primary Objective

Build a polished one-week MVP where the user can:

1. Open the camera.
2. Detect real-world surfaces.
3. Select original graffiti.
4. Place graffiti onto a detected surface.
5. Move around while the graffiti remains anchored.
6. Switch to Vision Mode.
7. View computer-vision information.
8. Capture the result.
9. View saved creations.

The application should feel like a real technical prototype rather than a tutorial.

---

# 3. Development Strategy

Always work in this order:

```text
1. Make it compile.
2. Make the basic feature work.
3. Test on a physical iPhone.
4. Handle failure states.
5. Improve architecture.
6. Improve UI.
7. Optimize performance.
```

Do not attempt to build the entire application at once.

Implement features in small, testable increments.

After meaningful changes:

* Build the project.
* Check for compiler errors.
* Fix errors before moving forward.
* Avoid leaving the repository in a broken state.

---

# 4. Important Constraint

The developer has:

* macOS
* Xcode
* VS Code
* Free Apple Developer account / Personal Team
* No paid Apple Developer Program membership

Do NOT introduce dependencies that require:

* paid Apple Developer membership
* App Store distribution
* TestFlight
* paid cloud services
* paid APIs
* paid ML APIs

The MVP must work locally.

---

# 5. Apple Framework Priority

Prefer Apple's native frameworks.

Priority:

### AR

1. ARKit
2. RealityKit

### Computer Vision

1. Vision
2. Core ML
3. Custom ML only if genuinely necessary

### UI

1. SwiftUI

Do not introduce third-party frameworks unless there is a clear technical reason.

If considering an external dependency, explain why it is needed before adding it.

---

# 6. Architecture

Use a clean but lightweight architecture.

Recommended structure:

```text
JetSetVision/
├── App/
├── Features/
│   ├── Camera/
│   ├── Spray/
│   ├── Vision/
│   └── Gallery/
├── AR/
├── Models/
├── Services/
├── UI/
└── Resources/
```

Do not create dozens of tiny files simply for the sake of abstraction.

Prefer cohesive components.

---

# 7. AR Implementation

The AR system should use:

* ARSession
* ARWorldTrackingConfiguration
* Plane detection
* Raycasting
* ARPlaneAnchor
* RealityKit entities

Initial plane detection:

```text
Horizontal
Vertical
```

The app should identify planes and allow the user to tap a plane to place graffiti.

---

# 8. Graffiti Placement

Graffiti should be represented as RealityKit entities.

The system should support:

* Position
* Rotation
* Scale
* Delete

When placing graffiti:

```text
Screen tap
    ↓
AR raycast
    ↓
World transform
    ↓
Graffiti entity
    ↓
Anchor/entity relationship
```

The graffiti should follow the orientation of the detected surface.

For example:

```text
Wall → graffiti faces wall
Floor → graffiti lies on floor
```

Do not simply place a floating 3D object in front of the camera.

---

# 9. Vision Mode

Vision Mode should demonstrate that the application is doing actual perception.

Use Apple's Vision framework where appropriate.

Potential functionality:

* Object detection
* Classification
* Segmentation
* Subject detection
* Person detection
* Confidence values

Do not implement fake detections.

Do not hard-code labels such as:

```text
"WALL 94%"
```

unless those values actually originate from a detection/model.

If a particular Vision request cannot reliably identify a desired category, communicate that honestly in the UI.

---

# 10. Performance

Do not run expensive computer-vision operations unnecessarily on every frame.

AR tracking should remain responsive.

Vision processing may be throttled.

For example:

```text
AR tracking:
continuous

Vision:
periodic
```

Use background processing where appropriate.

Never perform expensive processing synchronously on the main UI thread.

Watch for:

* frame drops
* excessive memory usage
* unnecessary image conversions
* repeated model initialization
* excessive Vision requests

---

# 11. UI

The UI should feel:

* Bold
* Experimental
* Playful
* Urban
* Graphic
* Modern

Avoid generic:

* AI dashboards
* Corporate UI
* Default SwiftUI forms
* Excessive gradients
* Generic chatbot aesthetics

Use original visual design inspired by:

* graffiti
* stickers
* photography
* skate culture
* early-2000s gaming interfaces



---

# 12. Main Navigation

The application should have a simple structure.

Suggested:

```text
                Jet Set Vision
                       |
          ┌────────────┴────────────┐
          ↓                         ↓
      SPRAY MODE                VISION MODE
          |
          ↓
      GRAFFITI
          |
          ↓
       CAPTURE
          |
          ↓
       GALLERY
```

Do not overcomplicate navigation.

The camera should remain the central experience.

---

# 13. User Feedback

The application must communicate state clearly.

Examples:

### Searching

```text
SEARCHING FOR SURFACE...
```

### Surface found

```text
SURFACE DETECTED
TAP TO SPRAY
```

### Tracking issue

```text
TRACKING LIMITED
MOVE YOUR PHONE SLOWLY
```

### No surface

```text
NO USABLE SURFACE
TRY A FLAT WALL
```

### Camera permission

Explain why camera access is needed.

---

# 14. Accessibility

Use SwiftUI accessibility APIs where appropriate.

Buttons should have:

* Accessibility labels
* Accessibility hints when useful

Do not rely solely on color to communicate state.

Text should remain readable.

---

# 15. Error Handling

Do not allow failures to silently happen.

Handle:

* Camera permission denied
* AR session failure
* Tracking unavailable
* No plane detected
* Raycast failure
* Vision failure
* Invalid image
* Capture failure

The app should fail gracefully.

---

# 16. Data Persistence

The MVP should use local persistence.

Do not build a backend.

Potential options:

* UserDefaults for lightweight settings
* Local files for captured images
* Codable models for metadata

Keep persistence simple.

---

# 17. Original Assets

If visual assets are needed:

Create simple original assets.

Examples:

```text
Graffiti01
Graffiti02
Graffiti03
Graffiti04
Arrow01
Sticker01
Tag01
Symbol01
```

Use simple vector/raster assets that can be bundled with the app.


---

# 18. Code Quality

Write production-quality Swift where practical.

Prefer:

* clear naming
* small functions
* predictable state management
* explicit responsibilities
* comments for non-obvious AR/Vision mathematics
* minimal global state

Avoid:

* giant view files
* magic numbers
* duplicated logic
* unnecessary singletons
* force unwraps when avoidable
* abandoned experimental code

---

# 19. AR / Vision Documentation

When implementing technically complex functionality, add concise comments explaining:

### AR

* coordinate systems
* raycasting
* anchors
* plane transforms
* orientation

### Vision

* request type
* image orientation
* coordinate conversion
* confidence interpretation
* processing frequency

These comments will make the project useful as a learning artifact.

---

# 20. Testing

When possible, test on a physical iPhone.

Important scenarios:

### Wall

```text
Detect wall
↓
Tap wall
↓
Place graffiti
↓
Walk around
```

### Floor

```text
Detect floor
↓
Place graffiti
↓
Move around
```

### Poor tracking

```text
Move too quickly
↓
Tracking degrades
↓
UI explains problem
```

### No surface

```text
Point at sky / clutter
↓
No surface
↓
UI communicates state
```

---

# 21. Git Strategy

Make logical commits.

Example:

```text
feat: add AR camera experience
feat: add plane detection
feat: add graffiti placement
feat: add graffiti controls
feat: add vision mode
feat: add capture gallery
style: polish camera interface
perf: throttle vision processing
docs: add architecture documentation
```

Do not create meaningless commits after every tiny edit.

---

# 22. README Maintenance

Keep `README.md` updated as the implementation changes.

Document:

* What the app does
* Architecture
* Technologies
* Setup
* How to run
* Vision features
* AR features
* Performance considerations
* Future improvements

Do not claim functionality that has not been implemented.

---

# 23. Development Phases

Follow these phases unless there is a strong reason to change them.

## Phase 1

Project setup.

Goal:

```text
App launches on physical iPhone.
```

---

## Phase 2

AR camera.

Goal:

```text
Live camera + AR session.
```

---

## Phase 3

Plane detection.

Goal:

```text
Walls/floors/tables can be detected.
```

---

## Phase 4

Graffiti placement.

Goal:

```text
Tap surface → graffiti appears.
```

---

## Phase 5

Graffiti controls.

Goal:

```text
Move
Rotate
Scale
Delete
```

---

## Phase 6

Vision Mode.

Goal:

```text
Camera → Vision → useful visual information.
```

---

## Phase 7

Capture.

Goal:

```text
AR scene → saved image.
```

---

## Phase 8

Gallery.

Goal:

```text
Saved creations can be viewed.
```

---

## Phase 9

Polish.

Goal:

```text
Feels like a cohesive product.
```

---

# 24. Scope Control

This is extremely important.

If a feature is not required for the MVP, do not let it derail development.

Do NOT prioritize:

* User authentication
* Social feeds
* Cloud databases
* Multiplayer AR
* Location-based persistence
* Custom trained object detectors
* Advanced generative AI
* Complex 3D modeling
* Custom Metal rendering
* Full spatial mapping
* Web dashboards

These can be documented as future work.

---

# 25. Technical Depth

Although the MVP should remain achievable in one week, the implementation should create opportunities to discuss deeper engineering concepts.

Important concepts to understand:

```text
Computer Vision
      ↓
Perception
      ↓
Scene Understanding
      ↓
Spatial Coordinates
      ↓
AR Anchoring
      ↓
Real-Time Rendering
```

The project should make these relationships visible in the architecture.

---

# 26. Engineering Questions to Keep in Mind

During implementation, consider:

### Computer Vision

* What information does Vision provide?
* What does it not provide?
* How reliable are predictions?
* How should confidence be displayed?

### AR

* How does ARKit know where the device is?
* How are planes represented?
* How does raycasting work?
* How is a surface's orientation determined?

### Performance

* How often should Vision run?
* What processing happens on the main thread?
* How can latency be reduced?
* How does memory usage scale?

### On-Device ML

* Why process locally?
* What are the latency benefits?
* What are the privacy benefits?
* What are the power constraints?

These questions matter more than simply adding more features.

---

# 27. If Something Doesn't Work

Do not immediately rewrite the architecture.

Follow:

```text
1. Identify the error.
2. Determine whether it is:
   - Swift/compiler
   - ARKit
   - RealityKit
   - Vision
   - permissions
   - device limitation
   - coordinate system
3. Make the smallest correction.
4. Build again.
5. Test again.
```

If an Apple API behaves differently than expected, check current Apple documentation before inventing a workaround.

---

# 28. Current Task Protocol

Whenever given a new task:

### Step 1

Read the relevant existing code.

### Step 2

Understand the current architecture.

### Step 3

Identify the smallest implementation needed.

### Step 4

Implement it.

### Step 5

Build the project.

### Step 6

Fix compiler errors.

### Step 7

Summarize:

```text
What changed
Why it changed
How to test it
Any known limitations
```

Do not rewrite unrelated files.

---

# 29. Do Not Overengineer

The goal is not to demonstrate how much code can be written.

The goal is:

> Build a technically meaningful computer-vision/AR experience that actually works.

Prefer:

```text
100 lines that work
```

over:

```text
500 lines of unnecessary architecture
```

---

# 30. Definition of Done

A feature is done when:

* It compiles.
* It runs on a physical device when applicable.
* The primary interaction works.
* Failure states are handled.
* The code is reasonably organized.
* No obvious debug artifacts remain.
* README documentation is accurate.

---

# 31. Final Product Principle

Always remember:

**The graffiti is not the main technical achievement.**

The technical achievement is the pipeline:

```text
CAMERA
   ↓
PERCEPTION
   ↓
UNDERSTANDING
   ↓
SPATIAL INTERACTION
   ↓
REAL-TIME RENDERING
```

Build the application so that this pipeline is obvious.

The finished project should give the developer something meaningful to discuss with Apple engineers working in:

* Computer Vision
* Vision Systems
* On-Device ML
* AR
* Spatial Computing
* Camera/Imaging
* ML Systems

Focus on making the experience **technically real, visually distinctive, and easy to explain.**
