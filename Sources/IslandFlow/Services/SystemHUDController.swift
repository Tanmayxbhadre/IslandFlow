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
            
        MediaManager.shared.$currentState
            .receive(on: RunLoop.main)
            .sink { [weak self] mediaState in
                self?.handleMediaStateChanged(mediaState)
            }
            .store(in: &cancellables)
    }
    
    public func handleSystemEvent(_ newState: IslandState) {
        let currentState = AppState.shared.islandState
        
        if case .expanded = currentState { return }
        if case .mediaExpanded = currentState { return }
        if currentState.priority > newState.priority { return }
        
        withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
            AppState.shared.islandState = newState
        }
        
        collapseTask?.cancel()
        collapseTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(autoCollapseDuration * 1_000_000_000))
            if !Task.isCancelled && AppState.shared.islandState == newState {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    if MediaManager.shared.isMediaActive {
                        if AppState.shared.isHovered {
                            AppState.shared.islandState = .mediaExpanded(MediaManager.shared.currentState)
                        } else {
                            AppState.shared.islandState = .mediaCompact(MediaManager.shared.currentState)
                        }
                    } else {
                        let metrics = ScreenManager.shared.activeScreenMetrics()
                        AppState.shared.islandState = metrics.hasNotch ? .notchCover : .compact
                    }
                }
            }
        }
    }
    
    private func handleMediaStateChanged(_ mediaState: MediaState) {
        let currentState = AppState.shared.islandState
        
        if currentState.priority >= 30 { return }
        
        if MediaManager.shared.isMediaActive {
            if case .mediaExpanded = currentState {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
                    AppState.shared.islandState = .mediaExpanded(mediaState)
                }
            } else {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
                    AppState.shared.islandState = .mediaCompact(mediaState)
                }
            }
        } else {
            let metrics = ScreenManager.shared.activeScreenMetrics()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                AppState.shared.islandState = metrics.hasNotch ? .notchCover : .compact
            }
        }
    }
}
