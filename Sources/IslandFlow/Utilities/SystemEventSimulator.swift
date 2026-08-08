import Foundation

@MainActor
public struct SystemEventSimulator {
    public static func simulateCharging() {
        let state = BatteryState(percentage: 85, isCharging: true, isFull: false)
        BatteryManager.shared.simulateState(state)
        SystemHUDController.shared.handleSystemEvent(.battery(state))
    }
    
    public static func simulateLowBattery() {
        let state = BatteryState(percentage: 15, isCharging: false, isFull: false, isLow: true)
        BatteryManager.shared.simulateState(state)
        SystemHUDController.shared.handleSystemEvent(.battery(state))
    }
    
    public static func simulateVolumeChange(level: Int = 72) {
        let state = VolumeState(level: level, isMuted: false)
        VolumeManager.shared.simulateState(state)
        SystemHUDController.shared.handleSystemEvent(.volume(state))
    }
    
    public static func simulateMute() {
        let state = VolumeState(level: 0, isMuted: true)
        VolumeManager.shared.simulateState(state)
        SystemHUDController.shared.handleSystemEvent(.volume(state))
    }
    
    public static func simulateBrightnessChange(level: Int = 65) {
        let state = BrightnessState(level: level)
        BrightnessManager.shared.simulateState(state)
        SystemHUDController.shared.handleSystemEvent(.brightness(state))
    }
}
