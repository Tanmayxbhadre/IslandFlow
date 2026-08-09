import Foundation
import CoreGraphics

/// IslandState defines the visual target for every island mode.
/// WindowManager and IslandContainerView both read `.size` and `.cornerRadius`
/// to derive panel geometry and FluidIslandShape parameters respectively.
/// SwiftUI animates those values via `.animation(value: islandState)`.
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

    // MARK: — Size

    public var size: CGSize {
        let metrics = ScreenManager.shared.activeScreenMetrics()
        switch self {
        case .notchCover, .mediaCompact:
            let w = metrics.hasNotch ? metrics.notchWidth : 140.0
            let h = metrics.hasNotch ? metrics.safeAreaTopInset : 32.0
            return CGSize(width: w, height: h)
        case .hover:
            let w = metrics.hasNotch ? max(metrics.notchWidth + 40.0, 220.0) : 220.0
            let h = metrics.hasNotch ? max(metrics.safeAreaTopInset + 8.0, 40.0) : 38.0
            return CGSize(width: w, height: h)
        case .compact:
            return CGSize(width: 140.0, height: 32.0)
        case .expanded:
            return CGSize(width: 320.0, height: 125.0)
        case .mediaExpanded:
            return CGSize(width: 350.0, height: 145.0)
        case .battery:
            return CGSize(width: 230.0, height: 40.0)
        case .volume:
            return CGSize(width: 240.0, height: 40.0)
        case .brightness:
            return CGSize(width: 240.0, height: 40.0)
        }
    }

    // MARK: — Corner Radius

    public var cornerRadius: CGFloat {
        switch self {
        case .notchCover,
             .mediaCompact: return 10.0   // matches physical notch bottom curve
        case .hover:        return 16.0
        case .compact:      return 16.0
        case .battery,
             .volume,
             .brightness:   return 20.0
        case .expanded,
             .mediaExpanded: return 22.0
        }
    }

    // MARK: — Top Flush
    //
    // All states on a notched display anchor to the screen top.
    // This means originY = screenFrame.maxY - height at all times,
    // so expansion always grows DOWNWARD and collapse shrinks UPWARD.

    public var isTopFlush: Bool {
        return ScreenManager.shared.activeScreenMetrics().hasNotch
    }

    // MARK: — Priority (for system event pre-emption)

    public var priority: Int {
        switch self {
        case .battery(let s): return s.isCritical ? 100 : (s.isLow ? 80 : 60)
        case .volume:         return 40
        case .brightness:     return 30
        case .mediaExpanded:  return 25
        case .expanded:       return 20
        case .mediaCompact:   return 15
        case .hover:          return 10
        case .notchCover, .compact: return 0
        }
    }
}
