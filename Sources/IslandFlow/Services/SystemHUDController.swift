import Foundation
import Combine
import SwiftUI

@MainActor
public final class SystemHUDController: ObservableObject {
    public static let shared = SystemHUDController()
    
    private var collapseTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private let autoCollapseDuration: TimeInterval = 2.2
    
    private init() {
        observeHardwareManagers()
    }
    
    private func observeHardwareManagers() {
        BatteryManager.shared.$currentState
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] batteryState in
                self?.handleSystemEvent(.battery(batteryState))
            }
            .store(in: &cancellables)
            
        VolumeManager.shared.$currentState
            .receive(on: RunLoop.main)
            .dropFirst()
            .sink { [weak self] volumeState in
                self?.handleSystemEvent(.volume(volumeState))
            }
            .store(in: &cancellables)
            
        BrightnessManager.shared.$currentState
            .receive(on: RunLoop.main)
            .dropFirst()
            .sink { [weak self] brightnessState in
                self?.handleSystemEvent(.brightness(brightnessState))
            }
            .store(in: &cancellables)
    }
    
    public func handleSystemEvent(_ newState: IslandState) {
        let currentState = AppState.shared.islandState
        
        if currentState == .expanded {
            return
        }
        
        if currentState.priority > newState.priority {
            return
        }
        
        withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
            AppState.shared.islandState = newState
        }
        
        collapseTask?.cancel()
        collapseTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(autoCollapseDuration * 1_000_000_000))
            if !Task.isCancelled {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    if AppState.shared.islandState == newState {
                        AppState.shared.islandState = .compact
                    }
                }
            }
        }
    }
}
