import Foundation
import CoreGraphics

public enum IslandState: Equatable {
    case notchCover
    case hover
    case compact
    case expanded
    case mediaCompact(MediaState)
    case mediaExpanded(MediaState)
    case battery(BatteryState)
    case volume(VolumeState)
    case brightness(BrightnessState)
    
    public var size: CGSize {
        switch self {
        case .notchCover:
            let metrics = ScreenManager.shared.activeScreenMetrics()
            let width = metrics.hasNotch ? max(metrics.notchWidth + 4.0, 180.0) : 140.0
            let height = metrics.hasNotch ? max(metrics.safeAreaTopInset, 34.0) : 32.0
            return CGSize(width: width, height: height)
        case .hover:
            return CGSize(width: 240, height: 44)
        case .compact:
            return CGSize(width: 140, height: 32)
        case .expanded:
            return CGSize(width: 330, height: 110)
        case .mediaCompact:
            return CGSize(width: 210, height: 36)
        case .mediaExpanded:
            return CGSize(width: 360, height: 155)
        case .battery:
            return CGSize(width: 230, height: 42)
        case .volume:
            return CGSize(width: 240, height: 42)
        case .brightness:
            return CGSize(width: 240, height: 42)
        }
    }
    
    public var cornerRadius: CGFloat {
        switch self {
        case .notchCover:
            return 14.0
        case .hover:
            return 16.0
        case .compact:
            return 16.0
        case .expanded, .mediaExpanded:
            return 24.0
        case .mediaCompact:
            return 18.0
        case .battery, .volume, .brightness:
            return 21.0
        }
    }
    
    public var isTopFlush: Bool {
        let metrics = ScreenManager.shared.activeScreenMetrics()
        guard metrics.hasNotch else { return false }
        switch self {
        case .notchCover, .hover, .mediaCompact, .battery, .volume, .brightness:
            return true
        case .compact, .expanded, .mediaExpanded:
            return false
        }
    }
    
    public var priority: Int {
        switch self {
        case .battery(let state):
            return state.isCritical ? 100 : (state.isLow ? 80 : 60)
        case .volume:
            return 40
        case .brightness:
            return 30
        case .mediaExpanded:
            return 25
        case .mediaCompact:
            return 15
        case .expanded:
            return 20
        case .hover:
            return 10
        case .notchCover, .compact:
            return 0
        }
    }
}
