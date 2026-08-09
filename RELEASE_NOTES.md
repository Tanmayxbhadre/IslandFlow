# IslandFlow v1.0.0 Release Notes

**Release Type:** Private / Local Build  
**Release Date:** August 9, 2026  
**Target Platform:** macOS 13.0 (Ventura) or newer  
**Supported Architecture:** Apple Silicon (arm64)

---

## Important Security Note for Local Release

> [!NOTE]  
> This build is intended for local/private use on your Mac. It is code-signed using an ad-hoc local identity and is not Developer ID signed or notarized by Apple.

### Launching on another Mac
If copying the application bundle or DMG to another Mac, macOS Gatekeeper may display an unverified developer warning. To run the app:
1. Open **Finder**, navigate to `/Applications/IslandFlow.app`.
2. Right-click (or Control-click) `IslandFlow.app` and select **Open**.
3. Click **Open** in the dialog prompt.

Alternatively, remove the quarantine attribute via Terminal:
```bash
xattr -cr /Applications/IslandFlow.app
```

---

## Features & Highlights

- **Notch-Anchored Liquid Surface**: Permanent stationary top-center panel morphing smoothly between collapsed notch geometry (161x32pt) and full expanded island (350x145pt).
- **Authoritative Hover Engine**: Single interaction state machine (`IslandInteractionController`) supporting customizable open/close delays, spatial grace hit-testing, and interruptible spring animations.
- **Production Media Control**: Atomic track updates, artwork crossfading, non-blocking image loading, time remaining displays, and tactile playback control feedback.
- **Native System HUDs**: Real-time Volume, Brightness, and Battery indicators coexisting with media playback without altering island geometry or causing accidental collapse.
- **Native Preferences Window**: Multi-tabbed SwiftUI preferences interface (**General**, **Island**, **Hover**, **Media**, **System HUD**, **Appearance**, **Advanced**).
- **First-Launch Onboarding**: Minimal native welcome guide explaining notch interactions and menu bar controls.
- **ServiceManagement Launch at Login**: Powered by `SMAppService.mainApp` for native system startup control.

---

## Package Artifacts & Checksums

- **App Bundle:** `build/releases/IslandFlow.app`
- **DMG Package:** `build/releases/IslandFlow-1.0.0.dmg`
- **ZIP Package:** `build/releases/IslandFlow-1.0.0.zip`

### Verifying SHA-256 Hashes

```bash
shasum -a 256 build/releases/IslandFlow-1.0.0.dmg
shasum -a 256 build/releases/IslandFlow-1.0.0.zip
```
