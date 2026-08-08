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
        switch self {
        case .notchCover:
            let metrics = ScreenManager.shared.activeScreenMetrics()
            let w = metrics.hasNotch ? max(metrics.notchWidth + 4.0, 180.0) : 140.0
            let h = metrics.hasNotch ? max(metrics.safeAreaTopInset, 34.0)  : 32.0
            return CGSize(width: w, height: h)
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

    // MARK: — Corner Radius
    //
    // These values form a smooth progression from the physical notch shape to
    // the full rounded island. SwiftUI's animatableData on FluidIslandShape
    // interpolates the radius continuously between states, so every intermediate
    // frame produces a different curve — no sudden corner appearance.

    public var cornerRadius: CGFloat {
        switch self {
        case .notchCover:   return 10.0   // matches physical notch bottom curve
        case .hover:        return 16.0
        case .compact:      return 16.0
        case .mediaCompact: return 18.0
        case .battery,
             .volume,
             .brightness:   return 20.0
        case .expanded,
             .mediaExpanded: return 24.0
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
