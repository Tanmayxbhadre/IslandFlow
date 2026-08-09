import Foundation
import Combine
import SwiftUI

/// SystemHUDController — manages islandState (content selection) for system HUD events
/// and media state changes.
///
/// Phase 14 Architecture:
///   • Observes AppSettings.shared to check enabled HUD types and dynamic autoCollapseDuration.
///   • This controller ONLY changes islandState (what content is shown).
///   • It NEVER changes expansionProgress (island geometry).
///   • Before any collapse-triggering content state change, it calls
///     IslandInteractionController.shared.isCollapseAllowed(reason:).
///     If the cursor is inside the island region, the collapse is blocked.
///
/// Collapse invariant:
///   The island collapses ONLY for reason = VERIFIED_MOUSE_EXIT
///   (from IslandInteractionController). This class has NO collapse authority.
@MainActor
public final class SystemHUDController: ObservableObject {
    public static let shared = SystemHUDController()

    private var collapseTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        observeHardwareManagers()
    }

    private func observeHardwareManagers() {
        BatteryManager.shared.$currentState
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] batteryState in
                if AppSettings.shared.showBatteryHUD {
                    self?.handleSystemEvent(.battery(batteryState))
                }
            }
            .store(in: &cancellables)

        VolumeManager.shared.$currentState
            .receive(on: RunLoop.main)
            .dropFirst()
            .sink { [weak self] volumeState in
                let settings = AppSettings.shared
                if volumeState.isMuted && settings.showMuteHUD {
                    self?.handleSystemEvent(.volume(volumeState))
                } else if !volumeState.isMuted && settings.showVolumeHUD {
                    self?.handleSystemEvent(.volume(volumeState))
                }
            }
            .store(in: &cancellables)

        BrightnessManager.shared.$currentState
            .receive(on: RunLoop.main)
            .dropFirst()
            .sink { [weak self] brightnessState in
                if AppSettings.shared.showBrightnessHUD {
                    self?.handleSystemEvent(.brightness(brightnessState))
                }
            }
            .store(in: &cancellables)

        MediaManager.shared.$currentState
            .receive(on: RunLoop.main)
            .sink { [weak self] mediaState in
                self?.handleMediaStateChanged(mediaState)
            }
            .store(in: &cancellables)
    }

    // MARK: — System HUD events (volume / brightness / battery)

    public func handleSystemEvent(_ newState: IslandState) {
        let currentState = AppState.shared.islandState
        if currentState.priority > newState.priority { return }

        AppState.shared.islandState = newState

        collapseTask?.cancel()
        let duration = AppSettings.shared.hudDuration
        collapseTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            guard AppState.shared.islandState == newState else { return }

            let ic = IslandInteractionController.shared
            if ic.isInsideRegion {
                Logger.window.debug("""
                    [Island] HUD auto-reset: cursor inside region — \
                    updating to hover content, not collapsing
                    """)
                if MediaManager.shared.isMediaActive {
                    AppState.shared.islandState = .mediaExpanded(MediaManager.shared.currentState)
                } else {
                    let metrics = ScreenManager.shared.activeScreenMetrics()
                    AppState.shared.islandState = metrics.hasNotch ? .hover : .expanded
                }
                return
            }

            Logger.window.debug("[Island] HUD auto-reset: cursor outside → resetting content")
            let metrics = ScreenManager.shared.activeScreenMetrics()
            if MediaManager.shared.isMediaActive {
                AppState.shared.islandState = .mediaCompact(MediaManager.shared.currentState)
            } else {
                AppState.shared.islandState = metrics.hasNotch ? .notchCover : .compact
            }
        }
    }

    // MARK: — Media state changes

    private func handleMediaStateChanged(_ mediaState: MediaState) {
        let ic = IslandInteractionController.shared

        if MediaManager.shared.isMediaActive {
            if ic.isInsideRegion {
                AppState.shared.islandState = .mediaExpanded(mediaState)
            } else {
                AppState.shared.islandState = .mediaCompact(mediaState)
            }
        } else {
            if !ic.isInsideRegion {
                let metrics = ScreenManager.shared.activeScreenMetrics()
                AppState.shared.islandState = metrics.hasNotch ? .notchCover : .compact
            }
        }
    }
}
