import Foundation

public struct BrightnessState: Equatable {
    public let level: Int // 0..100
    
    public init(level: Int) {
        self.level = level
    }
}
