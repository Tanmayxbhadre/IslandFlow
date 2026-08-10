# IslandFlow

> A native macOS utility bringing a fluid, context-aware floating Dynamic Island surface to Apple Silicon and Intel MacBooks.

---

## 1. Project Overview

**IslandFlow** is a native macOS utility that anchors a compact, context-aware floating surface flush to the top-center of the display (around the MacBook camera notch).

Rather than functioning as a conventional rectangular window or modal, IslandFlow operates as a lightweight system overlay. It unobtrusively surfaces real-time information—such as active media playback, hardware volume adjustments, screen brightness, battery levels, MagSafe charging status, and system notifications—expanding smoothly on spatial hover and contracting back into the notch when inactive.

Built using **SwiftUI**, **AppKit**, **CoreAudio**, **IOKit**, and **ServiceManagement**, IslandFlow is designed for zero workflow interruption, native performance, and 100% local, offline operation.

---

## 2. Why IslandFlow?

macOS exposes various system states across disparate locations (the menu bar, Control Center, full-screen HUD overlays, and notification popups). This can cause visual friction and interrupt focused work.

IslandFlow unifies contextual system events into a single, elegant surface:

- **Minimal Interruption**: Replaces disruptive full-screen hardware overlays (e.g., volume and brightness HUDs) with compact notch animations.
- **Instant Control**: Hover over the notch to immediately view and control media playback without switching active application windows.
- **Spatial Focus**: Anchored naturally at the top-center of the display, utilizing space around the camera notch.
- **Pass-Through Geometry**: Precision hit-testing ensures surrounding menu bar items, browser tabs, and desktop elements remain 100% clickable.

---

## 3. Features

| Feature | Status | Description |
| :--- | :--- | :--- |
| **MacBook Notch Integration** | ✅ Production | Anchored flush to top-center screen bounds on notch & non-notch displays |
| **Media Player Control** | ✅ Production | Play/Pause, Track Skip, Track Prev, Timeline Seeking via AppleScript |
| **Volume HUD** | ✅ Production | Real-time CoreAudio system volume monitoring and level adjustments |
| **Brightness HUD** | ✅ Production | Real-time DisplayServices hardware brightness monitoring |
| **Battery & Charging HUD** | ✅ Production | IOKit power source tracking (MagSafe connection, level %, low battery) |
| **Authoritative Hover Engine** | ✅ Production | 1 State Machine (`IslandInteractionController`) with spatial grace bounds |
| **Click-Through Hit Testing** | ✅ Production | AppKit `hitTest(_:)` pass-through for all regions outside active island |
| **Native Preferences Window** | ✅ Production | Multi-tabbed SwiftUI preferences interface with persistent settings |
| **Launch at Login** | ✅ Production | Powered by ServiceManagement (`SMAppService.mainApp`) |
| **Status Bar Menu Item** | ✅ Production | Status bar menu with state switches, simulation tools, and quit option |
| **First-Launch Onboarding** | ✅ Production | Minimal welcome guide explaining notch interactions |
| **Visual Debug Bounds Overlay** | ✅ Production | Toggleable green/red outlines showing active vs click-through bounds |
| **System Notifications** | 🛠️ In Progress | Compact notch notification presentation pipeline |
| **Multi-Display Switching** | ⚠️ Experimental | Display migration when active screen parameters change |

---

## 4. Current Status

### Current Phase
**UI/UX Refinement & Interaction Architecture Stabilization**

### Stability
Active development / Local release state. Core hardware managers (Media, Volume, Brightness, Battery) trace directly to system APIs without mock controllers.

### Release & Signing Status
- **Signing**: Ad-hoc local code signature (`codesign -s - --force`).
- **Notarization**: **Unsigned / Unnotarized** (The project is developed for local testing; no Apple Developer ID certificate is currently configured).
- **Distribution**: Packaged as `.app` and `.dmg` for private local testing. macOS Gatekeeper will require initial manual opening approval (`Right-Click -> Open` or `xattr -cr`).

---

## 5. Screenshots / Demo

> Screenshots coming soon.

*Live interactive demonstration available on the web landing page (`website/index.html`).*

---

## 6. Architecture

IslandFlow uses a unidirectional, state-driven architecture separating system event observation, state management, windowing, hit-testing, and SwiftUI rendering:

```
                      macOS Hardware & System APIs
           (CoreAudio / DisplayServices / IOKit / AppleScript)
                                  │
                                  ▼
                        SystemStateController
                      (System Event Monitors)
                                  │
                                  ▼
                         Effective App State
            ┌─────────────────────┼─────────────────────┐
            ▼                     ▼                     ▼
    SystemHUDController      MediaManager           AppState
            │                     │                     │
            └─────────────────────┼─────────────────────┘
                                  ▼
                     IslandInteractionController
                     (Authoritative Hover Engine)
                                  ▼
                          IslandPanel (NSPanel)
                                  │
                                  ▼
                        IslandHostingContainer
                        (AppKit Pass-Through)
                                  │
                                  ▼
                         IslandContainerView
                       (LiquidIslandShape Canvas)
```

1. **System Event Monitoring**: Observes CoreAudio, IOKit power notifications, NSWorkspace notifications, and media playback state.
2. **State & Managers**: `MediaManager`, `VolumeManager`, `BrightnessManager`, and `BatteryManager` maintain reactive state models.
3. **Hover Controller**: `IslandInteractionController` evaluates mouse location against spatial regions and executes state transitions (`.collapsed` ↔ `.opening` ↔ `.expanded` ↔ `.closing`).
4. **Window Layer**: `WindowManager` maintains a single stationary `IslandPanel` (`NSPanel`) anchored top-center.
5. **Hit-Test Layer**: `IslandHostingContainer` (`NSView`) intercepts clicks *only* within the active interpolated island capsule (`paddedActiveRect`) and returns `nil` elsewhere.
6. **UI Presentation**: `IslandContainerView` renders `LiquidIslandShape` using **DesignSystem** tokens and SwiftUI views (`MediaView`, `VolumeView`, etc.).

---

## 7. Project Structure

```
IslandFlow/
├── Package.swift                 # Swift Package Manager manifest (macOS 13.0+)
├── README.md                     # Project documentation
├── RELEASE_NOTES.md              # Local build release notes
├── Resources/                    # App assets and icon sets
│   ├── AppIcon.icns
│   └── Assets.xcassets/
├── Sources/
│   └── IslandFlow/
│       ├── App/                  # App entry point & global application state
│       │   ├── AppState.swift
│       │   └── IslandFlowApp.swift
│       ├── Controllers/          # System simulation & simulation controllers
│       ├── Managers/             # Hardware managers (Audio, Display, Power, Media)
│       │   ├── BatteryManager.swift
│       │   ├── BrightnessManager.swift
│       │   ├── MediaManager.swift
│       │   └── VolumeManager.swift
│       ├── Models/               # Data structures, state models & design tokens
│       │   ├── AppSettings.swift
│       │   ├── BatteryState.swift
│       │   ├── BrightnessState.swift
│       │   ├── DesignSystem.swift
│       │   ├── HoverSettings.swift
│       │   ├── IslandState.swift
│       │   ├── MediaState.swift
│       │   └── VolumeState.swift
│       ├── Services/             # System HUD controllers & event listeners
│       │   ├── SimulationController.swift
│       │   ├── SystemHUDController.swift
│       │   └── SystemStateController.swift
│       ├── UI/                   # SwiftUI views & custom shapes
│       │   ├── BatteryView.swift
│       │   ├── BrightnessView.swift
│       │   ├── CompactIslandView.swift
│       │   ├── CompactMediaView.swift
│       │   ├── ExpandedIslandView.swift
│       │   ├── IslandContainerView.swift
│       │   ├── MediaView.swift
│       │   ├── PreferencesView.swift
│       │   ├── VolumeView.swift
│       │   ├── WelcomeView.swift
│       │   └── Components/
│       │       ├── HoverDebugView.swift
│       │       ├── LiquidIslandShape.swift
│       │       └── NotchCoverShape.swift
│       ├── Utilities/            # Logging, permission alerts & helpers
│       │   ├── Logger.swift
│       │   ├── PermissionAlert.swift
│       │   └── SystemEventSimulator.swift
│       └── Window/               # AppKit NSPanel, screen metrics & hit testing
│           ├── IslandInteractionController.swift
│           ├── IslandPanel.swift
│           ├── PreferencesWindowController.swift
│           ├── ScreenManager.swift
│           ├── WindowConfiguration.swift
│           └── WindowManager.swift
├── scripts/                      # Build and packaging shell scripts
│   ├── build-app.sh              # Compiles debug/development binary
│   ├── build-dmg.sh              # Creates DMG distribution package
│   ├── build-release.sh          # Compiles release binary with ad-hoc signature
│   └── release.sh                # Complete release packaging pipeline
└── website/                      # Product landing page & interactive demo
    ├── downloads/
    │   └── IslandFlow-1.0.0.dmg
    ├── index.html
    ├── script.js
    └── styles.css
```

---

## 8. UI / UX Design Philosophy

IslandFlow's design language is defined in `DesignSystem.swift`:

- **Restraint & Hierarchy**: Uses deep obsidian black (`Color.black.opacity(0.94)`) with `.ultraThinMaterial` backdrop blur.
- **Physical Coherence**: The island morphs fluidly between a compact notch capsule (161×32pt) and an expanded panel (350×145pt) using `LiquidIslandShape`.
- **Refined Typography**: Bright white primary titles with muted secondary labels (`Color.white.opacity(0.60)`). Tail truncation prevents text overflow.
- **Tactile Micro-Interactions**: Controls feature physical spring scale feedback on click (`scaleEffect(0.92)`). Primary Play/Pause features a 36px white circle with dark icon.
- **Edge Highlight**: A subtle 0.75pt translucent stroke (`LinearGradient([.white.opacity(0.18), .white.opacity(0.03)])`) provides depth without heavy borders.

---

## 9. Interaction Model

```
 ┌───────────┐     Hover Notch     ┌──────────────┐     Move Inside     ┌───────────┐
 │ Collapsed │ ──────────────────► │ HoverEnter   │ ──────────────────► │ Expanded  │
 │  Capsule  │ ◄────────────────── │ (Open Delay) │                     │ Controls  │
 └───────────┘     Cursor Exits    └──────────────┘                     └─────┬─────┘
       ▲                                                                      │
       │                         Grace Period Expir.                          │
       └──────────────────────────────────────────────────────────────────────┘
```

1. **Collapsed State**: IslandFlow rests quietly inside/around the physical notch area (or top-center bar on non-notch displays).
2. **Hover Detection**: `IslandInteractionController` observes global mouse position. If the cursor enters the notch region, an `openDelay` timer initiates.
3. **Spring Expansion**: Upon trigger, the island smoothly morphs into the expanded state using SwiftUI spring physics (`response: 0.36`, `dampingFraction: 0.78`).
4. **Active Interaction**: The user can play/pause, skip tracks, scrub the progress timeline, or adjust hardware sliders.
5. **Grace Collapse**: When the cursor exits the active island bounds, a configurable `closeDelay + hoverGracePeriod` timer starts. If the cursor re-enters during this window, collapse is cancelled instantly.

---

## 10. Supported States

- **`notchCover`**: Default collapsed state on MacBooks with physical camera notch.
- **`compact`**: Default collapsed state on displays without a notch.
- **`mediaExpanded`**: Active media player showing artwork, title, artist, timeline scrubber, and playback controls.
- **`mediaCompact`**: Collapsed media pill showing mini artwork, track name, and animated waveform.
- **`volume`**: Hardware volume HUD displaying speaker icon, percentage value, and volume level bar.
- **`brightness`**: Hardware brightness HUD displaying sun icon, percentage value, and display level bar.
- **`battery`**: Power HUD showing battery percentage, power source status, and MagSafe charging indicators.
- **`hover`**: Expanded state when hovering over notch without active media playing (shows "No media playing" status).

---

## 11. Window & Hit-Test Architecture

To allow seamless usage of Chrome tabs, menu bar icons, and underlying windows around the top of the display, IslandFlow uses an explicit AppKit hit-testing pass-through architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                 macOS MENU BAR / DESKTOP                    │
│                                                             │
│       [ PASS-THROUGH ]      ┌──────────────┐     [ PASS-THROUGH ]
│     Clicks pass straight    │  IslandFlow  │   Clicks pass straight
│      to Chrome / Finder     │  Interactive │    to Chrome / Finder
│                             └──────────────┘                │
│       [ PASS-THROUGH ]                            [ PASS-THROUGH ]
└─────────────────────────────────────────────────────────────┘
```

- **Canvas Frame**: `IslandPanel` maintains a fixed `350 × 145 pt` frame anchored at the top-center of the screen.
- **AppKit Coordinate System**: AppKit Y=0 starts at the bottom of the container. The top flush edge is `Y = bounds.height` (145pt).
- **Dynamic Hit Test (`IslandHostingContainer`)**:
  ```swift
  override func hitTest(_ point: NSPoint) -> NSView? {
      let currentWidth = collapsedWidth + (expandedWidth - collapsedWidth) * progress
      let currentHeight = collapsedHeight + (expandedHeight - collapsedHeight) * progress

      let minX = (bounds.width - currentWidth) / 2.0
      let minY = bounds.height - currentHeight

      let activeIslandRect = NSRect(x: minX, y: minY, width: currentWidth, height: currentHeight)
      let paddedActiveRect = activeIslandRect.insetBy(dx: -4.0, dy: -4.0)

      if paddedActiveRect.contains(point) {
          return super.hitTest(point)
      }
      return nil // Clicks pass straight through to underlying applications
  }
  ```

---

## 12. Animation Architecture

- **Spring Physics**: Dynamic island morphing uses spring physics (`Animation.spring(response: 0.36, dampingFraction: 0.78)`).
- **Coordinated Interpolation**: `LiquidIslandShape` calculates continuous corner radiuses and control points based on `expansionProgress` (0.0 → 1.0).
- **Interruptible State Transitions**: Re-entering the notch during a collapse animation immediately cancels closing and reverses direction smoothly.
- **Reduced Motion Support**: Listens to `@Environment(\.accessibilityReduceMotion)`. When enabled, complex morphing transitions fall back to simple linear opacity crossfades (`duration: 0.12s`).

---

## 13. System Integration

- **Media Control**: Executes native AppleScript commands to control Apple Music and Spotify (`playpause`, `next track`, `previous track`, `set player position`).
- **CoreAudio Integration**: Monitors audio hardware output changes via AudioObjectPropertyListeners (`kAudioHardwarePropertyDefaultOutputDevice`, `kAudioDevicePropertyVolumeScalar`).
- **DisplayServices Integration**: Manages hardware display brightness via macOS `DisplayServices` private APIs.
- **IOKit Power Integration**: Monitors MagSafe connection state and battery percentage via `IOPSCopyPowerSourcesInfo()` and `IOPSGetPowerSourceDescription()`.
- **ServiceManagement**: Configures launch at system startup using `SMAppService.mainApp`.

---

## 14. Requirements

- **Operating System**: macOS 13.0 (Ventura) or newer
- **Architecture**: Universal Binary (Apple Silicon M1/M2/M3/M4 & Intel Mac)
- **Swift Version**: Swift 5.9+
- **Dependencies**: **Zero** external third-party dependencies. Uses 100% native Apple SDK frameworks (AppKit, SwiftUI, CoreAudio, IOKit, ServiceManagement).

---

## 15. Installation

Clone or open the project from your local repository:

```bash
git clone https://github.com/Tanmayxbhadre/IslandFlow.git
cd IslandFlow
```

---

## 16. Development Setup

1. Open terminal inside the `IslandFlow` directory.
2. Verify Swift toolchain: `swift --version`.
3. Build the development executable: `bash scripts/build-app.sh`.
4. Launch `IslandFlow.app`.
5. Check Terminal output or Console logs for diagnostic messages.

---

## 17. Running Locally

To compile and launch the development build directly:

```bash
bash scripts/build-app.sh
open IslandFlow.app
```

Alternatively, run via Swift Package Manager:

```bash
swift run
```

---

## 18. Building

IslandFlow provides dedicated build scripts in the `scripts/` directory:

| Script | Purpose |
| :--- | :--- |
| `scripts/build-app.sh` | Compiles debug/development `.app` bundle in root directory |
| `scripts/build-release.sh` | Compiles optimized release `IslandFlow.app` in `build/releases/` with ad-hoc signing |
| `scripts/build-dmg.sh` | Packages release `.app` into `IslandFlow-1.0.0.dmg` with ad-hoc signature |
| `scripts/release.sh` | Full release pipeline (cleans, builds release, creates DMG & ZIP, generates SHA-256 hashes) |

---

## 19. Debugging

### Visual Interaction Bounds
To verify hit-testing bounds and active hover regions visually:

1. Open **IslandFlow Status Bar Menu** -> **Preferences** -> **Hover**.
2. Enable **Show Debug Interaction Bounds**.
3. A visual overlay will render:
   - **Green Outline**: Active interactive region (`paddedActiveRect`).
   - **Red Dashed Outline**: Click-through window canvas bounds (`350×145`).

### Inspecting Logs
IslandFlow uses `os.Logger` for structured logging:

```bash
log stream --predicate 'subsystem == "com.islandflow.app"' --level debug
```

---

## 20. Testing Matrix

| Test | Procedure | Expected Result |
| :--- | :--- | :--- |
| **Notch Hover** | Move mouse over physical notch | Island expands smoothly to expanded state |
| **Mouse Exit** | Move mouse away from expanded island | Island collapses after grace period delay |
| **Click-Through (Left/Right)** | Click Chrome tabs or menu bar near notch | Mouse click registers on Chrome/Menu Bar |
| **Media Play/Pause** | Click Play/Pause button | Audio toggles play/pause state in active player |
| **Timeline Scrub** | Drag progress bar timeline | Player position seeks to target timestamp |
| **Volume Hardware Key** | Press Volume Up/Down on keyboard | Island surfaces volume percentage HUD |
| **Space Switch** | Switch macOS Spaces (Control + Left/Right) | Island stays top-center without drifting |
| **Input Monitoring** | Revoke Input Monitoring in System Settings | App prompts with permission alert dialog |

---

## 21. Known Issues

- **Unsigned Distribution**: Because an Apple Developer ID certificate is not configured, macOS Gatekeeper will block direct execution on external Macs until allowed via `Right-Click -> Open` or `xattr -cr`.
- **Input Monitoring Permission**: Global mouse movement tracking outside the panel canvas requires macOS **Input Monitoring** permission. If revoked, hover expansion pauses until granted.
- **External Displays**: Island placement defaults to the primary screen top-center; multi-monitor dragging is experimental.

---

## 22. Roadmap

- [x] **Phase 1**: Core Executable & Windowing Pipeline
- [x] **Phase 2**: Hardware Managers (Audio, Display, Battery)
- [x] **Phase 3**: Production Media Player (Spotify & Apple Music)
- [x] **Phase 4**: Authoritative Hover State Machine
- [x] **Phase 5**: Native SwiftUI Preferences & Onboarding
- [x] **Phase 6**: AppKit Hit-Test Pass-Through Architecture
- [x] **Phase 7**: UI/UX Apple-Grade Design System Overhaul
- [ ] **Phase 8**: System Notification Presentation Pipeline
- [ ] **Phase 9**: Multi-Display Docking Enhancements

---

## 23. Release / DMG

To generate the distribution package:

```bash
bash scripts/build-dmg.sh
```

Package output locations:
- `build/releases/IslandFlow.app`
- `build/releases/IslandFlow-1.0.0.dmg`
- `website/downloads/IslandFlow-1.0.0.dmg`

*Note: Builds are ad-hoc signed (`codesign -s -`). Running on external Mac machines requires initial Gatekeeper approval.*

---

## 24. Security & Privacy

IslandFlow is built with strict privacy and security principles:

- **100% Offline & Local**: Operates completely offline. Zero telemetry, zero analytics, zero network requests.
- **Minimum Permissions**: Requests only necessary macOS permissions (Accessibility for system keys, Input Monitoring for hover tracking).
- **Zero Disk Persistence**: Media artwork and state details are processed in memory and never written to disk or sent remotely.
- **System Integrity**: Does not modify macOS Gatekeeper, SIP, or system security settings.

---

## 25. Contributing

1. Fork or clone the repository locally.
2. Create a feature branch: `git checkout -b feature/my-feature`.
3. Make focused changes and verify using `bash scripts/build-app.sh`.
4. Test hardware HUDs and media playback.
5. Submit pull request for review.

---

## 26. License

License has not yet been selected.

---

## 27. Credits

- **IslandFlow**: Developed by Tanmay and contributors.
- **Apple Frameworks**: Powered by AppKit, SwiftUI, CoreAudio, IOKit, and ServiceManagement.
