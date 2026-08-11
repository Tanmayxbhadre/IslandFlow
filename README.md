<div align="center">

# IslandFlow

### A native macOS Dynamic Island experience for MacBook

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-000000?style=flat-square&logo=apple&logoColor=white)](https://islandflow.netlify.app/)
[![Swift](https://img.shields.io/badge/Swift-5.9-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-Apple%20Silicon%20%7C%20Intel-147EFB?style=flat-square)](https://islandflow.netlify.app/)

**[Live Website](https://islandflow.netlify.app/)** · **[GitHub](https://github.com/Tanmayxbhadre/IslandFlow)** · **[Portfolio](https://www.createwithtanmay.in/)**

</div>

---

## Overview

IslandFlow is a native macOS utility that anchors a compact, fluid overlay to the top-center of your MacBook display — around the camera notch area — and surfaces real-time system information without interrupting your workflow.

Rather than a conventional window or HUD panel, IslandFlow operates as a lightweight system overlay. It collapses into the notch area when idle and expands smoothly on hover to reveal media playback controls, volume levels, brightness, battery status, and charging information.

Every detail — geometry, hit-testing, animation timing, state transitions — is designed to stay out of the way.

---

## Why IslandFlow?

macOS surfaces system state across too many places: menu bar, Control Center, full-screen HUDs, notification banners. Volume changes trigger a large overlay that blocks content. Brightness adjustments are invisible until you look at the menu bar. Media controls require switching focus.

IslandFlow unifies these events into a single, compact surface anchored to the space you already look at — the top-center of your screen:

- **Replaces disruptive HUDs** — volume and brightness changes appear as compact notch-adjacent indicators instead of full-screen overlays
- **Media control without focus switching** — hover to control playback without leaving your current app
- **Uses idle space** — the camera notch area is always visible but rarely useful; IslandFlow changes that
- **Click-through geometry** — when not in use, the island is invisible to clicks; menu bar items, browser tabs, and desktop elements remain fully interactive

---

## Features

**Media**
- Album artwork display with crossfade transitions
- Song title and artist name
- Playback progress bar with timeline seeking
- Play / Pause, Previous Track, Next Track controls
- Compact media strip visible without expanding the island

**System HUDs**
- Real-time volume monitoring and visual level indicator
- Brightness level monitoring and display
- Mute state detection
- HUD display duration configurable per event type

**Battery & Charging**
- Live battery percentage via IOKit
- MagSafe / USB-C charging state detection
- Low battery and critical battery alerts
- Charge status without opening Control Center

**Hover & Interaction**
- Configurable open delay and close delay
- Spatial grace bounds — the island does not collapse on minor cursor drift
- Interruptible spring animations — expansion/collapse can be reversed mid-animation
- Single authoritative state machine (`IslandInteractionController`) drives all transitions

**Click-Through**
- AppKit `hitTest(_:)` pass-through for all regions outside the active island
- Surrounding menu bar items, browser tabs, and window controls remain fully clickable
- Zero input interference when the island is collapsed

**Preferences**
- Multi-tab native preferences window (General, Island, Hover, Media, System HUD, Appearance, Advanced)
- Launch at Login via `SMAppService.mainApp`
- Status bar menu item with state controls and simulation tools
- Per-user settings persisted via `UserDefaults`

**First Launch**
- Minimal onboarding guide explaining notch interactions and menu bar controls
- No account required, no internet connection required

---

## Demo

**[→ islandflow.netlify.app](https://islandflow.netlify.app/)**

---

## Screenshots

> Screenshots coming soon.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9 |
| UI Framework | SwiftUI + AppKit |
| System Audio | CoreAudio |
| Hardware Sensors | IOKit |
| Brightness | DisplayServices |
| Media Control | AppleScript / MediaRemote |
| Launch at Login | ServiceManagement (`SMAppService`) |
| Window Management | NSPanel (above menu bar level) |
| Packaging | Swift Package Manager |

---

## Architecture

IslandFlow uses a unidirectional, state-driven architecture separating system observation, state modeling, windowing, hit-testing, and rendering:

```
macOS Hardware & System APIs
(CoreAudio / IOKit / DisplayServices / AppleScript)
          │
     System Managers
(MediaManager / VolumeManager / BrightnessManager / BatteryManager)
          │
     IslandState (enum)
(notchCover / hover / compact / expanded /
 mediaCompact / mediaExpanded / volume / brightness / battery)
          │
    IslandInteractionController
(state machine: collapsed → opening → expanded → closing)
          │
    WindowManager + IslandPanel
(NSPanel above menu bar, AppKit hit-testing, screen metrics)
          │
    SwiftUI Island Views
(IslandContainerView → ExpandedIslandView / MediaView /
 VolumeView / BrightnessView / BatteryView)
```

State priority determines which event pre-empts another — critical battery overrides volume, which overrides brightness — without manual ordering logic.

---

## Requirements

- macOS 13.0 Ventura or newer
- Apple Silicon (arm64) — primary development target
- Intel Macs — compatible via Rosetta 2, not independently tested

---

## Installation

### From the DMG (easiest)

1. Download `IslandFlow-1.0.0.dmg` from the repository's build artifacts
2. Open the DMG and drag `IslandFlow.app` to `/Applications`
3. Right-click `IslandFlow.app` → **Open** to bypass Gatekeeper on first launch

Or via Terminal to clear the quarantine attribute:

```bash
xattr -cr /Applications/IslandFlow.app
open /Applications/IslandFlow.app
```

### Build from Source

Requires Xcode 15+ or Swift 5.9 toolchain.

```bash
git clone https://github.com/Tanmayxbhadre/IslandFlow.git
cd IslandFlow
swift build -c release
```

Or open in Xcode:

```bash
open Package.swift
```

Then `Product → Run` (⌘R).

---

## Permissions

IslandFlow requires no special system permissions.

- No microphone access
- No screen recording
- No accessibility permissions
- No network access

All system information is read through macOS APIs. No data leaves the device.

---

## Privacy

IslandFlow is entirely local and offline. It reads system state from macOS APIs — CoreAudio for volume, IOKit for battery, AppleScript for media metadata — and renders it locally. No analytics, no telemetry, no network requests.

---

## Current Status

**v1.0.0** — Active development / local release state

| Component | Status |
|---|---|
| Notch overlay & hit-testing | Production |
| Media control (play/pause/skip/seek) | Production |
| Volume HUD | Production |
| Brightness HUD | Production |
| Battery & charging HUD | Production |
| Preferences window | Production |
| Launch at login | Production |
| System notifications | In progress |
| Multi-display support | Experimental |

---

## Roadmap

- System notification pipeline (compact notch banners)
- Stable multi-display switching
- App-specific media source selection
- Calendar / reminder glimpse mode

---

## Contributing

Issues and pull requests are welcome. Please open an issue to discuss significant changes before submitting a PR.

---

## License

License not currently specified.

---

## Project Links

| | |
|---|---|
| Live Website | https://islandflow.netlify.app/ |
| GitHub | https://github.com/Tanmayxbhadre/IslandFlow |
| Portfolio | https://www.createwithtanmay.in/ |
