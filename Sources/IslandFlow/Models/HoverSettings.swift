import Foundation
import SwiftUI
import Combine

public enum AnimationSpeed: String, CaseIterable, Identifiable, Codable {
    case veryFast = "Very Fast"
    case fast     = "Fast"
    case natural  = "Natural"
    case slow     = "Slow"

    public var id: String { rawValue }

    public var response: Double {
        switch self {
        case .veryFast: return 0.18
        case .fast:     return 0.22
        case .natural:  return 0.28
        case .slow:     return 0.38
        }
    }

    public var dampingFraction: Double {
        switch self {
        case .veryFast: return 0.95
        case .fast:     return 0.94
        case .natural:  return 0.92
        case .slow:     return 0.90
        }
    }
}

public enum HoverSensitivity: String, CaseIterable, Identifiable, Codable {
    case low    = "Low"
    case normal = "Normal"
    case high   = "High"

    public var id: String { rawValue }

    /// Horizontal padding around notch/island in points
    public var horizontalPadding: CGFloat {
        switch self {
        case .low:    return -4.0
        case .normal: return 12.0
        case .high:   return 24.0
        }
    }

    /// Vertical padding around notch/island in points
    public var verticalPadding: CGFloat {
        switch self {
        case .low:    return 0.0
        case .normal: return 4.0
        case .high:   return 8.0
        }
    }
}

@MainActor
public final class HoverSettings: ObservableObject {
    public static let shared = HoverSettings()

    private let defaults = UserDefaults.standard

    // Keys
    private enum Key {
        static let hoverEnabled          = "hoverEnabled"
        static let openOnNotchHover      = "openOnNotchHover"
        static let collapseOnMouseExit   = "collapseOnMouseExit"
        static let openDelay             = "openDelay"
        static let closeDelay            = "closeDelay"
        static let hoverGracePeriod       = "hoverGracePeriod"
        static let animationSpeed        = "animationSpeed"
        static let hoverSensitivity      = "hoverSensitivity"
        static let requireNotchHover     = "requireNotchHover"
        static let keepOpenInsideIsland  = "keepOpenInsideIsland"
        static let ignoreVolumeHUD       = "ignoreVolumeHUD"
        static let ignoreBrightnessHUD   = "ignoreBrightnessHUD"
        static let ignoreMediaUpdates     = "ignoreMediaUpdates"
        static let ignoreSpaceChanges    = "ignoreSpaceChanges"
        static let debugHoverState       = "debugHoverState"
    }

    @Published public var hoverEnabled: Bool {
        didSet { defaults.set(hoverEnabled, forKey: Key.hoverEnabled) }
    }
    @Published public var openOnNotchHover: Bool {
        didSet { defaults.set(openOnNotchHover, forKey: Key.openOnNotchHover) }
    }
    @Published public var collapseOnMouseExit: Bool {
        didSet { defaults.set(collapseOnMouseExit, forKey: Key.collapseOnMouseExit) }
    }

    @Published public var openDelay: Int {
        didSet { defaults.set(openDelay, forKey: Key.openDelay) }
    }
    @Published public var closeDelay: Int {
        didSet { defaults.set(closeDelay, forKey: Key.closeDelay) }
    }
    @Published public var hoverGracePeriod: Int {
        didSet { defaults.set(hoverGracePeriod, forKey: Key.hoverGracePeriod) }
    }

    @Published public var animationSpeed: AnimationSpeed {
        didSet { defaults.set(animationSpeed.rawValue, forKey: Key.animationSpeed) }
    }
    @Published public var hoverSensitivity: HoverSensitivity {
        didSet { defaults.set(hoverSensitivity.rawValue, forKey: Key.hoverSensitivity) }
    }

    @Published public var requireNotchHover: Bool {
        didSet { defaults.set(requireNotchHover, forKey: Key.requireNotchHover) }
    }
    @Published public var keepOpenInsideIsland: Bool {
        didSet { defaults.set(keepOpenInsideIsland, forKey: Key.keepOpenInsideIsland) }
    }

    @Published public var ignoreVolumeHUD: Bool {
        didSet { defaults.set(ignoreVolumeHUD, forKey: Key.ignoreVolumeHUD) }
    }
    @Published public var ignoreBrightnessHUD: Bool {
        didSet { defaults.set(ignoreBrightnessHUD, forKey: Key.ignoreBrightnessHUD) }
    }
    @Published public var ignoreMediaUpdates: Bool {
        didSet { defaults.set(ignoreMediaUpdates, forKey: Key.ignoreMediaUpdates) }
    }
    @Published public var ignoreSpaceChanges: Bool {
        didSet { defaults.set(ignoreSpaceChanges, forKey: Key.ignoreSpaceChanges) }
    }

    @Published public var debugHoverState: Bool {
        didSet { defaults.set(debugHoverState, forKey: Key.debugHoverState) }
    }

    private init() {
        let d = UserDefaults.standard
        
        self.hoverEnabled          = d.object(forKey: Key.hoverEnabled) != nil ? d.bool(forKey: Key.hoverEnabled) : true
        self.openOnNotchHover      = d.object(forKey: Key.openOnNotchHover) != nil ? d.bool(forKey: Key.openOnNotchHover) : true
        self.collapseOnMouseExit   = d.object(forKey: Key.collapseOnMouseExit) != nil ? d.bool(forKey: Key.collapseOnMouseExit) : true
        
        self.openDelay             = d.object(forKey: Key.openDelay) != nil ? d.integer(forKey: Key.openDelay) : 80
        self.closeDelay            = d.object(forKey: Key.closeDelay) != nil ? d.integer(forKey: Key.closeDelay) : 220
        self.hoverGracePeriod       = d.object(forKey: Key.hoverGracePeriod) != nil ? d.integer(forKey: Key.hoverGracePeriod) : 180

        if let speedRaw = d.string(forKey: Key.animationSpeed), let speed = AnimationSpeed(rawValue: speedRaw) {
            self.animationSpeed = speed
        } else {
            self.animationSpeed = .natural
        }

        if let sensRaw = d.string(forKey: Key.hoverSensitivity), let sens = HoverSensitivity(rawValue: sensRaw) {
            self.hoverSensitivity = sens
        } else {
            self.hoverSensitivity = .normal
        }

        self.requireNotchHover     = d.object(forKey: Key.requireNotchHover) != nil ? d.bool(forKey: Key.requireNotchHover) : true
        self.keepOpenInsideIsland  = d.object(forKey: Key.keepOpenInsideIsland) != nil ? d.bool(forKey: Key.keepOpenInsideIsland) : true

        self.ignoreVolumeHUD       = d.object(forKey: Key.ignoreVolumeHUD) != nil ? d.bool(forKey: Key.ignoreVolumeHUD) : true
        self.ignoreBrightnessHUD   = d.object(forKey: Key.ignoreBrightnessHUD) != nil ? d.bool(forKey: Key.ignoreBrightnessHUD) : true
        self.ignoreMediaUpdates     = d.object(forKey: Key.ignoreMediaUpdates) != nil ? d.bool(forKey: Key.ignoreMediaUpdates) : true
        self.ignoreSpaceChanges    = d.object(forKey: Key.ignoreSpaceChanges) != nil ? d.bool(forKey: Key.ignoreSpaceChanges) : true

        self.debugHoverState       = d.object(forKey: Key.debugHoverState) != nil ? d.bool(forKey: Key.debugHoverState) : false
    }

    public func resetToDefaults() {
        hoverEnabled          = true
        openOnNotchHover      = true
        collapseOnMouseExit   = true
        openDelay             = 80
        closeDelay            = 220
        hoverGracePeriod       = 180
        animationSpeed        = .natural
        hoverSensitivity      = .normal
        requireNotchHover     = true
        keepOpenInsideIsland  = true
        ignoreVolumeHUD       = true
        ignoreBrightnessHUD   = true
        ignoreMediaUpdates     = true
        ignoreSpaceChanges    = true
        debugHoverState       = false
    }
}
