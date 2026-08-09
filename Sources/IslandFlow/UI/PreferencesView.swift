import SwiftUI
import AppKit

public struct PreferencesView: View {
    @ObservedObject private var appSettings   = AppSettings.shared
    @ObservedObject private var hoverSettings = HoverSettings.shared
    @State private var showingResetAlert      = false
    @State private var selectedTab: PrefTab   = .general

    public enum PrefTab: String, CaseIterable, Identifiable {
        case general    = "General"
        case island     = "Island"
        case hover      = "Hover"
        case media      = "Media"
        case hud        = "System HUD"
        case appearance = "Appearance"
        case advanced   = "Advanced"

        public var id: String { rawValue }

        public var iconName: String {
            switch self {
            case .general:    return "gearshape"
            case .island:     return "macbook.gen2"
            case .hover:      return "cursorarrow.rays"
            case .media:      return "music.note"
            case .hud:        return "speaker.wave.2"
            case .appearance: return "paintbrush"
            case .advanced:   return "slider.horizontal.3"
            }
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                generalSection
                    .tabItem { Label(PrefTab.general.rawValue, systemImage: PrefTab.general.iconName) }
                    .tag(PrefTab.general)

                islandSection
                    .tabItem { Label(PrefTab.island.rawValue, systemImage: PrefTab.island.iconName) }
                    .tag(PrefTab.island)

                hoverSection
                    .tabItem { Label(PrefTab.hover.rawValue, systemImage: PrefTab.hover.iconName) }
                    .tag(PrefTab.hover)

                mediaSection
                    .tabItem { Label(PrefTab.media.rawValue, systemImage: PrefTab.media.iconName) }
                    .tag(PrefTab.media)

                hudSection
                    .tabItem { Label(PrefTab.hud.rawValue, systemImage: PrefTab.hud.iconName) }
                    .tag(PrefTab.hud)

                appearanceSection
                    .tabItem { Label(PrefTab.appearance.rawValue, systemImage: PrefTab.appearance.iconName) }
                    .tag(PrefTab.appearance)

                advancedSection
                    .tabItem { Label(PrefTab.advanced.rawValue, systemImage: PrefTab.advanced.iconName) }
                    .tag(PrefTab.advanced)
            }
            .padding(20)

            Divider()

            HStack {
                Button(role: .destructive, action: { showingResetAlert = true }) {
                    Text("Reset to Defaults…")
                }
                .alert("Reset IslandFlow Settings?", isPresented: $showingResetAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Reset", role: .destructive) {
                        appSettings.resetAllSettings()
                    }
                } message: {
                    Text("This will restore all IslandFlow preferences to their default values.")
                }

                Spacer()

                Text("IslandFlow v1.0.0")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 520, height: 420)
    }

    // MARK: — Sections

    private var generalSection: some View {
        Form {
            Section {
                Toggle("Enable IslandFlow", isOn: $appSettings.islandEnabled)
                Toggle("Launch IslandFlow at Login", isOn: $appSettings.launchAtLogin)
                Toggle("Show Status Bar Icon", isOn: $appSettings.showStatusItem)
            } header: {
                Text("General Settings").font(.headline)
            }
        }
    }

    private var islandSection: some View {
        Form {
            Section {
                Toggle("Enable Island Feature", isOn: $appSettings.islandEnabled)
                Toggle("Keep Attached to MacBook Notch", isOn: $appSettings.keepAttachedToNotch)
                Toggle("Allow Manual Expansion (⌘E)", isOn: $appSettings.allowManualToggle)
            } header: {
                Text("Notch & Island Geometry").font(.headline)
            }
        }
    }

    private var hoverSection: some View {
        Form {
            Section {
                Toggle("Enable Hover Interaction", isOn: $hoverSettings.hoverEnabled)
                Toggle("Open on Notch Hover", isOn: $hoverSettings.openOnNotchHover)
                Toggle("Collapse on Mouse Exit", isOn: $hoverSettings.collapseOnMouseExit)
                Toggle("Require Initial Notch Hover", isOn: $hoverSettings.requireNotchHover)
                Toggle("Keep Open Inside Island Area", isOn: $hoverSettings.keepOpenInsideIsland)
            } header: {
                Text("Hover Behavior").font(.headline)
            }

            Section {
                Stepper("Open Delay: \(hoverSettings.openDelay) ms", value: $hoverSettings.openDelay, in: 0...500, step: 20)
                Stepper("Close Delay: \(hoverSettings.closeDelay) ms", value: $hoverSettings.closeDelay, in: 50...1000, step: 20)
                Stepper("Hover Grace Period: \(hoverSettings.hoverGracePeriod) ms", value: $hoverSettings.hoverGracePeriod, in: 50...1000, step: 20)

                Picker("Hover Sensitivity", selection: $hoverSettings.hoverSensitivity) {
                    ForEach(HoverSensitivity.allCases) { sens in
                        Text(sens.rawValue).tag(sens)
                    }
                }
            } header: {
                Text("Timing & Tolerance").font(.headline)
            }
        }
    }

    private var mediaSection: some View {
        Form {
            Section {
                Toggle("Show Artwork", isOn: $appSettings.showMediaArtwork)
                Toggle("Show Track Title", isOn: $appSettings.showSongTitle)
                Toggle("Show Artist Name", isOn: $appSettings.showArtist)
                Toggle("Show Progress Bar", isOn: $appSettings.showProgress)
                Toggle("Show Playback Controls", isOn: $appSettings.showPlaybackControls)
            } header: {
                Text("Media Player Elements").font(.headline)
            }
        }
    }

    private var hudSection: some View {
        Form {
            Section {
                Toggle("Show Volume HUD Events", isOn: $appSettings.showVolumeHUD)
                Toggle("Show Brightness HUD Events", isOn: $appSettings.showBrightnessHUD)
                Toggle("Show Mute HUD Events", isOn: $appSettings.showMuteHUD)
                Toggle("Show Battery HUD Events", isOn: $appSettings.showBatteryHUD)
            } header: {
                Text("System HUD Display").font(.headline)
            }

            Section {
                Slider(value: $appSettings.hudDuration, in: 1.0...5.0, step: 0.2) {
                    Text("HUD Display Duration: \(String(format: "%.1f", appSettings.hudDuration))s")
                }
            } header: {
                Text("HUD Timeout").font(.headline)
            }
        }
    }

    private var appearanceSection: some View {
        Form {
            Section {
                Picker("Appearance Mode", selection: $appSettings.appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                Picker("Animation Speed", selection: $hoverSettings.animationSpeed) {
                    ForEach(AnimationSpeed.allCases) { speed in
                        Text(speed.rawValue).tag(speed)
                    }
                }

                Toggle("Respect macOS Reduce Motion", isOn: $appSettings.respectReduceMotion)
            } header: {
                Text("Appearance & Animation").font(.headline)
            }
        }
    }

    private var advancedSection: some View {
        Form {
            Section {
                Toggle("Enable Debug Overlay", isOn: $hoverSettings.debugHoverState)
                Toggle("Enable Debug Logging", isOn: $appSettings.debugLogging)
                Toggle("Enable Geometry Logging", isOn: $appSettings.geometryLogging)
                Toggle("Enable Event Logging", isOn: $appSettings.eventLogging)
            } header: {
                Text("Development & Debugging").font(.headline)
            }
        }
    }
}
