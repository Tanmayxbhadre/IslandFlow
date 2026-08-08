import Foundation
import CoreGraphics

public enum IslandState: Equatable {
    case compact
    case expanded
    
    public var size: CGSize {
        switch self {
        case .compact:
            return CGSize(width: 140, height: 32)
        case .expanded:
            return CGSize(width: 320, height: 110)
        }
    }
    
    public var cornerRadius: CGFloat {
        switch self {
        case .compact:
            return 16.0
        case .expanded:
            return 24.0
        }
    }
}
