# IslandFlow 

**IslandFlow** is a native macOS menu-bar utility that brings a physically coherent, Dynamic Island-style experience to Apple Silicon and Intel MacBooks featuring the camera notch.

---

## Key Features

- **MacBook Notch Integration**: Top-center anchored, liquid-interpolating surface physically locked to the MacBook camera notch.
- **Authoritative Hover Engine**: Single state machine (`IslandInteractionController`) driving smooth hover expansion, configurable exit delays, spatial grace bounds, and interruptible spring animations.
- **Production Media Experience**: Atomic media updates, smooth artwork crossfade transitions, non-blocking asynchronous artwork loading, time formatting (MM:SS & HH:MM:SS), and tactile playback control feedback.
- **Native System HUDs**: Real-time Volume, Brightness, and Battery indicators coexisting with media playback without altering island geometry or causing accidental collapse.
- **Live & Reactive Status Bar Menu**: Native macOS menu bar status item displaying live effective system status, simulation testing tools, and quick controls.
- **Native Preferences Window**: Multi-tabbed SwiftUI preferences interface (**General**, **Island**, **Hover**, **Media**, **System HUD**, **Appearance**, **Advanced**) with persistent settings.
- **First-Launch Onboarding**: Minimal native welcome guide explaining notch interactions and menu bar controls.
- **Native Launch at Login**: Powered by ServiceManagement (`SMAppService.mainApp`).

---

## Requirements

- **Operating System**: macOS 13.0 (Ventura) or newer
- **Architecture**: Apple Silicon (M1/M2/M3/M4) or Intel Mac
- **Dependencies**: None (Uses 100% native AppKit + SwiftUI + CoreAudio + IOKit + ServiceManagement)

---

## Build & Run Instructions

### Building from Source

```bash
bash scripts/build-app.sh
```

This compiles the Swift package into `IslandFlow.app` in the root directory.

### Running Locally

```bash
open IslandFlow.app
```

---

## Architecture Overview

```
                          macOS Systems
                    (Audio / Display / Power / Media)
                                 │
                     ┌───────────┴───────────┐
                     ↓                       ↓
             SystemStateController   SimulationController
                     └───────────┬───────────┘
                                 ↓
                         Effective State
                                 │
          ┌──────────────────────┼──────────────────────┐
          ↓                      ↓                      ↓
SystemHUDController         MediaManager         AppState / UI
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 ↓
                    IslandInteractionController
                    (Authoritative Hover Engine)
                                 ↓
                     IslandContainerView
                  (LiquidIslandShape Canvas)
```

---

## License

Copyright © 2026. All rights reserved.
