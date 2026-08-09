import Foundation
import SwiftUI
import Combine
import ServiceManagement

public enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
    case system = "System"
    case dark   = "Dark"
    case light  = "Light"

    public var id: String { rawValue }
}

@MainActor
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let launchAtLogin           = "launchAtLogin"
        static let showStatusItem         = "showStatusItem"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"

        static let islandEnabled          = "islandEnabled"
        static let keepAttachedToNotch    = "keepAttachedToNotch"
        static let allowManualToggle      = "allowManualToggle"

        static let showMediaArtwork       = "showMediaArtwork"
        static let showSongTitle          = "showSongTitle"
        static let showArtist             = "showArtist"
        static let showProgress           = "showProgress"
        static let showPlaybackControls   = "showPlaybackControls"

        static let showVolumeHUD          = "showVolumeHUD"
        static let showBrightnessHUD      = "showBrightnessHUD"
        static let showMuteHUD            = "showMuteHUD"
        static let showBatteryHUD         = "showBatteryHUD"
        static let hudDuration            = "hudDuration"

        static let appearanceMode         = "appearanceMode"
        static let respectReduceMotion    = "respectReduceMotion"

        static let debugLogging           = "debugLogging"
        static let geometryLogging        = "geometryLogging"
        static let eventLogging          = "eventLogging"
    }

    // MARK: — General

    @Published public var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Key.launchAtLogin)
            applyLaunchAtLogin(launchAtLogin)
        }
    }

    @Published public var showStatusItem: Bool {
        didSet { defaults.set(showStatusItem, forKey: Key.showStatusItem) }
    }

    @Published public var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Key.hasCompletedOnboarding) }
    }

    // MARK: — Island

    @Published public var islandEnabled: Bool {
        didSet { defaults.set(islandEnabled, forKey: Key.islandEnabled) }
    }

    @Published public var keepAttachedToNotch: Bool {
        didSet { defaults.set(keepAttachedToNotch, forKey: Key.keepAttachedToNotch) }
    }

    @Published public var allowManualToggle: Bool {
        didSet { defaults.set(allowManualToggle, forKey: Key.allowManualToggle) }
    }

    // MARK: — Media Display

    @Published public var showMediaArtwork: Bool {
        didSet { defaults.set(showMediaArtwork, forKey: Key.showMediaArtwork) }
    }

    @Published public var showSongTitle: Bool {
        didSet { defaults.set(showSongTitle, forKey: Key.showSongTitle) }
    }

    @Published public var showArtist: Bool {
        didSet { defaults.set(showArtist, forKey: Key.showArtist) }
    }

    @Published public var showProgress: Bool {
        didSet { defaults.set(showProgress, forKey: Key.showProgress) }
    }

    @Published public var showPlaybackControls: Bool {
        didSet { defaults.set(showPlaybackControls, forKey: Key.showPlaybackControls) }
    }

    // MARK: — System HUD

    @Published public var showVolumeHUD: Bool {
        didSet { defaults.set(showVolumeHUD, forKey: Key.showVolumeHUD) }
    }

    @Published public var showBrightnessHUD: Bool {
        didSet { defaults.set(showBrightnessHUD, forKey: Key.showBrightnessHUD) }
    }

    @Published public var showMuteHUD: Bool {
        didSet { defaults.set(showMuteHUD, forKey: Key.showMuteHUD) }
    }

    @Published public var showBatteryHUD: Bool {
        didSet { defaults.set(showBatteryHUD, forKey: Key.showBatteryHUD) }
    }

    @Published public var hudDuration: Double {
        didSet { defaults.set(hudDuration, forKey: Key.hudDuration) }
    }

    // MARK: — Appearance & Animation

    @Published public var appearanceMode: AppearanceMode {
        didSet { defaults.set(appearanceMode.rawValue, forKey: Key.appearanceMode) }
    }

    @Published public var respectReduceMotion: Bool {
        didSet { defaults.set(respectReduceMotion, forKey: Key.respectReduceMotion) }
    }

    // MARK: — Debug

    @Published public var debugLogging: Bool {
        didSet { defaults.set(debugLogging, forKey: Key.debugLogging) }
    }

    @Published public var geometryLogging: Bool {
        didSet { defaults.set(geometryLogging, forKey: Key.geometryLogging) }
    }

    @Published public var eventLogging: Bool {
        didSet { defaults.set(eventLogging, forKey: Key.eventLogging) }
    }

    private init() {
        let d = UserDefaults.standard

        self.launchAtLogin           = d.object(forKey: Key.launchAtLogin) != nil ? d.bool(forKey: Key.launchAtLogin) : false
        self.showStatusItem         = d.object(forKey: Key.showStatusItem) != nil ? d.bool(forKey: Key.showStatusItem) : true
        self.hasCompletedOnboarding = d.object(forKey: Key.hasCompletedOnboarding) != nil ? d.bool(forKey: Key.hasCompletedOnboarding) : false

        self.islandEnabled          = d.object(forKey: Key.islandEnabled) != nil ? d.bool(forKey: Key.islandEnabled) : true
        self.keepAttachedToNotch    = d.object(forKey: Key.keepAttachedToNotch) != nil ? d.bool(forKey: Key.keepAttachedToNotch) : true
        self.allowManualToggle      = d.object(forKey: Key.allowManualToggle) != nil ? d.bool(forKey: Key.allowManualToggle) : true

        self.showMediaArtwork       = d.object(forKey: Key.showMediaArtwork) != nil ? d.bool(forKey: Key.showMediaArtwork) : true
        self.showSongTitle          = d.object(forKey: Key.showSongTitle) != nil ? d.bool(forKey: Key.showSongTitle) : true
        self.showArtist             = d.object(forKey: Key.showArtist) != nil ? d.bool(forKey: Key.showArtist) : true
        self.showProgress           = d.object(forKey: Key.showProgress) != nil ? d.bool(forKey: Key.showProgress) : true
        self.showPlaybackControls   = d.object(forKey: Key.showPlaybackControls) != nil ? d.bool(forKey: Key.showPlaybackControls) : true

        self.showVolumeHUD          = d.object(forKey: Key.showVolumeHUD) != nil ? d.bool(forKey: Key.showVolumeHUD) : true
        self.showBrightnessHUD      = d.object(forKey: Key.showBrightnessHUD) != nil ? d.bool(forKey: Key.showBrightnessHUD) : true
        self.showMuteHUD            = d.object(forKey: Key.showMuteHUD) != nil ? d.bool(forKey: Key.showMuteHUD) : true
        self.showBatteryHUD         = d.object(forKey: Key.showBatteryHUD) != nil ? d.bool(forKey: Key.showBatteryHUD) : true
        self.hudDuration            = d.object(forKey: Key.hudDuration) != nil ? d.double(forKey: Key.hudDuration) : 2.2

        if let modeRaw = d.string(forKey: Key.appearanceMode), let mode = AppearanceMode(rawValue: modeRaw) {
            self.appearanceMode = mode
        } else {
            self.appearanceMode = .system
        }

        self.respectReduceMotion    = d.object(forKey: Key.respectReduceMotion) != nil ? d.bool(forKey: Key.respectReduceMotion) : true

        self.debugLogging           = d.object(forKey: Key.debugLogging) != nil ? d.bool(forKey: Key.debugLogging) : false
        self.geometryLogging        = d.object(forKey: Key.geometryLogging) != nil ? d.bool(forKey: Key.geometryLogging) : false
        self.eventLogging          = d.object(forKey: Key.eventLogging) != nil ? d.bool(forKey: Key.eventLogging) : false
    }

    public func resetAllSettings() {
        launchAtLogin           = false
        showStatusItem         = true
        islandEnabled          = true
        keepAttachedToNotch    = true
        allowManualToggle      = true

        showMediaArtwork       = true
        showSongTitle          = true
        showArtist             = true
        showProgress           = true
        showPlaybackControls   = true

        showVolumeHUD          = true
        showBrightnessHUD      = true
        showMuteHUD            = true
        showBatteryHUD         = true
        hudDuration            = 2.2

        appearanceMode         = .system
        respectReduceMotion    = true

        debugLogging           = false
        geometryLogging        = false
        eventLogging          = false

        HoverSettings.shared.resetToDefaults()
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    Logger.app.info("Launch at login registered")
                } else {
                    try SMAppService.mainApp.unregister()
                    Logger.app.info("Launch at login unregistered")
                }
            } catch {
                Logger.app.error("Failed to update Launch at Login: \(error.localizedDescription)")
            }
        }
    }
}
