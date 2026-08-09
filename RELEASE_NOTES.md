# IslandFlow v1.0.0 Release Notes

**Release Date:** August 9, 2026  
**Target Platform:** macOS 13.0 (Ventura) or newer  
**Supported Architectures:** Apple Silicon (arm64) & Intel (x86_64)

---

## Highlights

IslandFlow v1.0.0 is a native macOS Dynamic Island utility designed specifically for Apple Silicon and Intel MacBooks.

### Key Capabilities

- **Notch-Anchored Liquid Surface**: Permanent stationary top-center panel morphing smoothly between collapsed notch geometry (161x32pt) and full expanded island (350x145pt).
- **Authoritative Hover Engine**: Single interaction state machine (`IslandInteractionController`) supporting customizable open/close delays, spatial grace hit-testing, and interruptible spring animations.
- **Production Media Control**: Atomic track updates, artwork crossfading, non-blocking image loading, time remaining displays, and tactile playback control feedback.
- **Native System HUDs**: Real-time Volume, Brightness, and Battery indicators coexisting with media playback without altering island geometry or causing accidental collapse.
- **Native Preferences Window**: Multi-tabbed SwiftUI preferences interface (**General**, **Island**, **Hover**, **Media**, **System HUD**, **Appearance**, **Advanced**).
- **First-Launch Onboarding**: Minimal native welcome guide explaining notch interactions and menu bar controls.
- **ServiceManagement Launch at Login**: Powered by `SMAppService.mainApp` for native system startup control.

---

## Package Artifacts

- **App Bundle:** `build/releases/IslandFlow.app`
- **ZIP Release Package:** `build/releases/IslandFlow-1.0.0.zip`

---

## Verification & Integrity

To verify the SHA-256 checksum of your release ZIP archive:

```bash
shasum -a 256 build/releases/IslandFlow-1.0.0.zip
```
