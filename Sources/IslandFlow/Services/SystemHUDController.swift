import Foundation
import Combine
import SwiftUI

/// SystemHUDController — manages island expansion for system HUD events
/// (volume, brightness, battery) and media state changes.
///
/// In Phase 7, this controller sets AppState.islandState (content selection)
/// and relies on IslandContainerView's .onReceive(appState.$islandState)
/// to trigger the corresponding expansionProgress change.
/// It does NOT directly resize the NSPanel — that is permanently stationary.
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

    /// Handle a system HUD event (volume / brightness / battery).
    /// Sets islandState for content selection; IslandContainerView expands via progress.
    public func handleSystemEvent(_ newState: IslandState) {
        let currentState = AppState.shared.islandState

        // Don't interrupt user-initiated expansion (hover) or higher-priority HUD
        if AppState.shared.isHovered { return }
        if case .expanded = currentState { return }
        if case .mediaExpanded = currentState { return }
        if currentState.priority > newState.priority { return }

        // Set content state — IslandContainerView observes and expands
        AppState.shared.islandState = newState

        // Auto-collapse after display duration
        collapseTask?.cancel()
        collapseTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(autoCollapseDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            guard !AppState.shared.isHovered else { return }
            guard AppState.shared.islandState == newState else { return }

            let metrics = ScreenManager.shared.activeScreenMetrics()
            if MediaManager.shared.isMediaActive {
                AppState.shared.islandState = .mediaCompact(MediaManager.shared.currentState)
            } else {
                AppState.shared.islandState = metrics.hasNotch ? .notchCover : .compact
            }
        }
    }

    private func handleMediaStateChanged(_ mediaState: MediaState) {
        let currentState = AppState.shared.islandState

        // Don't interrupt higher-priority HUD events
        if currentState.priority >= 30 { return }

        if MediaManager.shared.isMediaActive {
            if AppState.shared.isHovered {
                AppState.shared.islandState = .mediaExpanded(mediaState)
            } else {
                AppState.shared.islandState = .mediaCompact(mediaState)
            }
        } else {
            let metrics = ScreenManager.shared.activeScreenMetrics()
            AppState.shared.islandState = metrics.hasNotch ? .notchCover : .compact
        }
    }
}
