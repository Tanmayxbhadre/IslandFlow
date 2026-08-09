import Foundation
import Combine

@MainActor
public final class SimulationController: ObservableObject {
    public static let shared = SimulationController()

    @Published public var simulatedVolume: VolumeState?
    @Published public var simulatedBrightness: BrightnessState?
    @Published public var simulatedBattery: BatteryState?
    @Published public var simulatedMedia: MediaState?

    public var isSimulatingAny: Bool {
        simulatedVolume != nil || simulatedBrightness != nil || simulatedBattery != nil || simulatedMedia != nil
    }

    private init() {}

    public func setSimulatedVolume(level: Int, isMuted: Bool = false) {
        let state = VolumeState(level: min(max(level, 0), 100), isMuted: isMuted)
        simulatedVolume = state
        SystemHUDController.shared.handleSystemEvent(.volume(state))
    }

    public func setSimulatedBrightness(level: Int) {
        let state = BrightnessState(level: min(max(level, 0), 100))
        simulatedBrightness = state
        SystemHUDController.shared.handleSystemEvent(.brightness(state))
    }

    public func setSimulatedBattery(percentage: Int, isCharging: Bool = false, isFull: Bool = false) {
        let isLow = percentage <= 20
        let state = BatteryState(percentage: min(max(percentage, 0), 100), isCharging: isCharging, isFull: isFull, isLow: isLow)
        simulatedBattery = state
        SystemHUDController.shared.handleSystemEvent(.battery(state))
    }

    public func setSimulatedMedia(title: String = "Somewhere Only We Know", artist: String = "Gustixa", album: String = "Chill Beats", isPlaying: Bool = true) {
        let playbackState: MediaPlaybackState = isPlaying ? .playing : .paused
        let state = MediaState(
            title: title,
            artist: artist,
            album: album,
            isPlaying: isPlaying,
            currentTime: isPlaying ? 45 : 0,
            duration: 180,
            sourceName: "Simulation",
            playbackState: playbackState
        )
        simulatedMedia = state
        MediaManager.shared.updateStateFromEffective(state)
    }

    public func setSimulatedMediaStopped() {
        let state = MediaState(
            title: "No Track",
            artist: "Unknown Artist",
            isPlaying: false,
            playbackState: .stopped
        )
        simulatedMedia = state
        MediaManager.shared.updateStateFromEffective(state)
    }

    public func resetVolumeSimulation() {
        simulatedVolume = nil
        let actual = SystemStateController.shared.actualVolume
        SystemHUDController.shared.handleSystemEvent(.volume(actual))
    }

    public func resetBrightnessSimulation() {
        simulatedBrightness = nil
        let actual = SystemStateController.shared.actualBrightness
        SystemHUDController.shared.handleSystemEvent(.brightness(actual))
    }

    public func resetBatterySimulation() {
        simulatedBattery = nil
        let actual = SystemStateController.shared.actualBattery
        SystemHUDController.shared.handleSystemEvent(.battery(actual))
    }

    public func resetMediaSimulation() {
        simulatedMedia = nil
        let actual = SystemStateController.shared.actualMedia
        MediaManager.shared.updateStateFromEffective(actual)
    }

    public func resetAll() {
        simulatedVolume = nil
        simulatedBrightness = nil
        simulatedBattery = nil
        simulatedMedia = nil
        
        SystemStateController.shared.publishEffectiveStates()
        Logger.app.info("[Simulation] Reset all simulations to live system state")
    }
}
