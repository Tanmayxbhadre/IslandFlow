import Foundation

public struct BatteryState: Equatable {
    public let percentage: Int
    public let isCharging: Bool
    public let isFull: Bool
    public let isLow: Bool
    public let isCritical: Bool
    
    public init(percentage: Int, isCharging: Bool, isFull: Bool, isLow: Bool = false, isCritical: Bool = false) {
        self.percentage = percentage
        self.isCharging = isCharging
        self.isFull = isFull
        self.isLow = isLow || (percentage <= 20 && !isCharging)
        self.isCritical = isCritical || (percentage <= 10 && !isCharging)
    }
}
