import Foundation
import CoreGraphics

public enum IslandState: Equatable {
    case compact
    case expanded
    case battery(BatteryState)
    case volume(VolumeState)
    case brightness(BrightnessState)
    
    public var size: CGSize {
        switch self {
        case .compact:
            return CGSize(width: 140, height: 32)
        case .expanded:
            return CGSize(width: 320, height: 110)
        case .battery:
            return CGSize(width: 220, height: 42)
        case .volume:
            return CGSize(width: 240, height: 42)
        case .brightness:
            return CGSize(width: 240, height: 42)
        }
    }
    
    public var cornerRadius: CGFloat {
        switch self {
        case .compact:
            return 16.0
        case .expanded:
            return 24.0
        case .battery, .volume, .brightness:
            return 21.0
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
        case .expanded:
            return 20
        case .compact:
            return 0
        }
    }
}
