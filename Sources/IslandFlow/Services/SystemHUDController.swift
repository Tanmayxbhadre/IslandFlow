import Foundation
import Combine
import SwiftUI

/// SystemHUDController — manages islandState (content selection) for system HUD events
/// and media state changes.
///
/// Phase 9 architecture:
///   • This controller ONLY changes islandState (what content is shown).
///   • It NEVER changes expansionProgress (island geometry).
///   • Before any collapse-triggering content state change, it calls
///     IslandInteractionController.shared.isCollapseAllowed(reason:).
///     If the cursor is inside the island region, the collapse is blocked.
///   • Volume / brightness / battery events:
///       - If cursor is INSIDE the island → update content only, no auto-collapse.
///       - If cursor is OUTSIDE → still no geometry change (geometry is separate).
///   • Media changes NEVER collapse the island.
///
/// Collapse invariant:
///   The island collapses ONLY for reason = VERIFIED_MOUSE_EXIT
///   (from IslandInteractionController). This class has NO collapse authority.
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

    // MARK: — System HUD events (volume / brightness / battery)

    /// Updates content state for system HUD events.
    /// Does NOT collapse the island — geometry is owned by IslandInteractionController.
    public func handleSystemEvent(_ newState: IslandState) {
        let currentState = AppState.shared.islandState
        if currentState.priority > newState.priority { return }

        // Update the content state shown inside the island.
        // IslandContainerView observes this but does NOT change geometry from it.
        AppState.shared.islandState = newState

        // Schedule content auto-reset after the HUD display duration.
        // IMPORTANT: This ONLY resets the content state (islandState).
        // It NEVER collapses the island if the cursor is still inside.
        collapseTask?.cancel()
        collapseTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(autoCollapseDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            guard AppState.shared.islandState == newState else { return }

            // Guard: do not reset content if cursor is still inside the island.
            // The island's expanded content should remain appropriate for hover.
            let ic = IslandInteractionController.shared
            if ic.isInsideRegion {
                // Cursor still inside: update content to match hover state
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

            // Cursor is outside: safe to reset content to collapsed state.
            // Note: geometry (expansionProgress) is already at 0 if cursor left,
            // because IslandInteractionController handled that separately.
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

    /// Handles media playback changes (track change, play/pause, artwork update).
    /// NEVER collapses the island — only updates the content state.
    private func handleMediaStateChanged(_ mediaState: MediaState) {
        let ic = IslandInteractionController.shared

        if MediaManager.shared.isMediaActive {
            // Update content to match current hover state.
            if ic.isInsideRegion {
                AppState.shared.islandState = .mediaExpanded(mediaState)
            } else {
                AppState.shared.islandState = .mediaCompact(mediaState)
            }
        } else {
            // Media stopped — only update content if cursor is outside.
            // If cursor is inside, keep the island at hover/expanded state.
            if !ic.isInsideRegion {
                let metrics = ScreenManager.shared.activeScreenMetrics()
                AppState.shared.islandState = metrics.hasNotch ? .notchCover : .compact
            }
            // If inside: leave islandState as-is (cursor will determine what to show)
        }
    }
}
