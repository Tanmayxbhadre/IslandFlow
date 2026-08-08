import Foundation

public struct VolumeState: Equatable {
    public let level: Int // 0..100
    public let isMuted: Bool
    
    public init(level: Int, isMuted: Bool) {
        self.level = level
        self.isMuted = isMuted
    }
}
