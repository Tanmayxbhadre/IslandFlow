import Foundation
import Combine

@MainActor
public final class SystemStateController: ObservableObject {
    public static let shared = SystemStateController()

    @Published public private(set) var actualVolume: VolumeState = VolumeState(level: 50, isMuted: false)
    @Published public private(set) var actualBrightness: BrightnessState = BrightnessState(level: 75)
    @Published public private(set) var actualBattery: BatteryState = BatteryState(percentage: 85, isCharging: true, isFull: false)
    @Published public private(set) var actualMedia: MediaState = MediaState()

    private var cancellables = Set<AnyCancellable>()

    private init() {
        observeManagers()
    }

    private func observeManagers() {
        VolumeManager.shared.$currentState
            .sink { [weak self] state in
                guard let self = self else { return }
                self.actualVolume = state
                if SimulationController.shared.simulatedVolume == nil {
                    SystemHUDController.shared.handleSystemEvent(.volume(state))
                }
            }
            .store(in: &cancellables)

        BrightnessManager.shared.$currentState
            .sink { [weak self] state in
                guard let self = self else { return }
                self.actualBrightness = state
                if SimulationController.shared.simulatedBrightness == nil {
                    SystemHUDController.shared.handleSystemEvent(.brightness(state))
                }
            }
            .store(in: &cancellables)

        BatteryManager.shared.$currentState
            .compactMap { $0 }
            .sink { [weak self] state in
                guard let self = self else { return }
                self.actualBattery = state
                if SimulationController.shared.simulatedBattery == nil {
                    SystemHUDController.shared.handleSystemEvent(.battery(state))
                }
            }
            .store(in: &cancellables)

        MediaManager.shared.$currentState
            .sink { [weak self] state in
                guard let self = self else { return }
                self.actualMedia = state
            }
            .store(in: &cancellables)

        SimulationController.shared.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: — Effective States

    public var effectiveVolume: VolumeState {
        SimulationController.shared.simulatedVolume ?? actualVolume
    }

    public var effectiveBrightness: BrightnessState {
        SimulationController.shared.simulatedBrightness ?? actualBrightness
    }

    public var effectiveBattery: BatteryState {
        SimulationController.shared.simulatedBattery ?? actualBattery
    }

    public var effectiveMedia: MediaState {
        SimulationController.shared.simulatedMedia ?? actualMedia
    }

    public func publishEffectiveStates() {
        SystemHUDController.shared.handleSystemEvent(.volume(effectiveVolume))
        SystemHUDController.shared.handleSystemEvent(.brightness(effectiveBrightness))
        SystemHUDController.shared.handleSystemEvent(.battery(effectiveBattery))
        MediaManager.shared.updateStateFromEffective(effectiveMedia)
    }
}
