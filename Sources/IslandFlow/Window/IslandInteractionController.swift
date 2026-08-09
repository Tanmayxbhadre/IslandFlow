import AppKit
import Combine
import SwiftUI

// MARK: — Collapse Reason

public enum CollapseReason: CustomStringConvertible, Equatable {
    case verifiedMouseExit
    case manual
    case hoverDisabled

    public var description: String {
        switch self {
        case .verifiedMouseExit: return "VERIFIED_MOUSE_EXIT"
        case .manual:            return "MANUAL_TOGGLE"
        case .hoverDisabled:     return "HOVER_DISABLED"
        }
    }
}

// MARK: — IslandInteractionController

/// Authoritative single interaction controller & state machine for IslandFlow.
///
/// Phase 10 Architecture:
///   • Fully driven by `HoverSettings`.
///   • Performs authoritative point-in-rect checks against `notchRegion` and `expandedIslandRegion`.
///   • Respects `openDelay`, `closeDelay`, `hoverGracePeriod`, `hoverSensitivity`, and HUD ignore rules.
///   • Handles smooth animation reversal and manual overrides without corrupting state.
@MainActor
public final class IslandInteractionController: ObservableObject {
    public static let shared = IslandInteractionController()

    // MARK: — Interaction state

    public enum InteractionState: Equatable {
        case collapsed
        case opening
        case expanded
        case closing

        public var isOpenOrOpening: Bool { self == .opening || self == .expanded }
    }

    @Published public private(set) var state: InteractionState = .collapsed
    @Published public private(set) var lastCollapseReason: CollapseReason?
    @Published public private(set) var isPendingOpen: Bool = false
    @Published public private(set) var isPendingClose: Bool = false

    /// Fast accessor for whether mouse is inside active interaction bounds
    public var isInsideRegion: Bool { state.isOpenOrOpening }

    // MARK: — Geometry Regions (AppKit screen coordinates, bottom-origin)

    private var cachedMetrics: ScreenMetrics?
    private var baseNotchRegion: NSRect = .zero
    private var baseExpandedRegion: NSRect = .zero

    // MARK: — Event monitors

    private var globalMonitor: Any?
    private var localMonitor: Any?

    // MARK: — Timers / Tasks

    private var openTask: Task<Void, Never>?
    private var closeTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: — Init

    private init() {
        // Observe settings changes to re-evaluate mouse position or active regions
        HoverSettings.shared.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.reevaluateSettings()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: — Setup & Region Computations

    public func setup(with metrics: ScreenMetrics) {
        cachedMetrics = metrics
        updateRegions(with: metrics)
        Logger.window.info("[Hover] Setup regions — Notch: \(String(describing: self.baseNotchRegion)), Expanded: \(String(describing: self.baseExpandedRegion))")
        startMonitoring()
    }

    public func updateRegion(with metrics: ScreenMetrics) {
        cachedMetrics = metrics
        updateRegions(with: metrics)
    }

    private func updateRegions(with metrics: ScreenMetrics) {
        let cx = metrics.topFlushPoint.x
        
        // 1. Expanded Island Region
        let ew = WindowManager.expandedWidth
        let eh = WindowManager.expandedHeight
        let ex = cx - ew / 2.0
        let ey: CGFloat = metrics.hasNotch
            ? metrics.screenFrame.maxY - eh
            : metrics.visibleFrame.maxY - eh - 4.0
        baseExpandedRegion = NSRect(x: ex, y: ey, width: ew, height: eh)

        // 2. Notch Region
        let nw = metrics.notchWidth
        let nh = metrics.safeAreaTopInset
        let nx = cx - nw / 2.0
        let ny = metrics.screenFrame.maxY - nh
        baseNotchRegion = NSRect(x: nx, y: ny, width: nw, height: nh)
    }

    /// Computes active hit region based on current state & settings (sensitivity, requireNotchHover, keepOpenInsideIsland)
    public var activeInteractionRegion: NSRect {
        let settings = HoverSettings.shared
        let hPad = settings.hoverSensitivity.horizontalPadding
        let vPad = settings.hoverSensitivity.verticalPadding

        let notchPadded = baseNotchRegion.insetBy(dx: -hPad, dy: -vPad)
        let expandedPadded = baseExpandedRegion.insetBy(dx: -hPad, dy: -vPad)

        if state == .collapsed {
            if settings.requireNotchHover {
                return notchPadded
            } else {
                return notchPadded.union(expandedPadded)
            }
        } else {
            // When open/opening/closing: apply 10pt spatial grace margin downward
            let baseRegion = settings.keepOpenInsideIsland ? notchPadded.union(expandedPadded) : notchPadded
            return NSRect(
                x: baseRegion.minX,
                y: baseRegion.minY - 10.0,
                width: baseRegion.width,
                height: baseRegion.height + 10.0
            )
        }
    }

    // MARK: — Monitoring

    private func startMonitoring() {
        guard globalMonitor == nil else { return }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        ) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                self?.checkMousePosition()
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        ) { [weak self] event in
            DispatchQueue.main.async { [weak self] in
                self?.checkMousePosition()
            }
            return event
        }

        Logger.window.info("[Hover] Mouse monitoring started")
    }

    // MARK: — Position Verification

    public func checkMousePosition() {
        let settings = HoverSettings.shared
        guard settings.hoverEnabled else {
            if isPendingOpen || isPendingClose {
                openTask?.cancel()
                openTask = nil
                closeTask?.cancel()
                closeTask = nil
                isPendingOpen = false
                isPendingClose = false
            }
            return
        }

        let region = activeInteractionRegion
        guard !region.isEmpty else { return }

        let mouseLoc = NSEvent.mouseLocation
        let inside = region.contains(mouseLoc)

        switch state {
        case .collapsed:
            if inside {
                scheduleOpen()
            } else if isPendingOpen {
                cancelOpenDelay(reason: "cursorExitedBeforeOpenDelay")
            }
        case .opening, .expanded:
            if !inside {
                if settings.collapseOnMouseExit {
                    scheduleClose()
                }
            } else if isPendingClose {
                cancelClose(reason: "cursorReturnedDuringGrace")
            }
        case .closing:
            if inside {
                cancelClose(reason: "mouseEnteredDuringClosing")
            }
        }
    }

    // MARK: — Open Sequence (with Open Delay)

    private func scheduleOpen() {
        let settings = HoverSettings.shared
        guard settings.openOnNotchHover else { return }
        guard state == .collapsed else { return }
        guard !isPendingOpen else { return }

        closeTask?.cancel()
        closeTask = nil
        isPendingClose = false

        if settings.openDelay <= 0 {
            executeOpen()
            return
        }

        isPendingOpen = true
        Logger.window.debug("[Hover] OPEN_DELAY_STARTED delay=\(settings.openDelay)ms")

        openTask?.cancel()
        openTask = Task { @MainActor in
            let ns = UInt64(settings.openDelay) * 1_000_000
            try? await Task.sleep(nanoseconds: ns)

            guard !Task.isCancelled else { return }
            self.isPendingOpen = false

            // Verify cursor is still inside
            let loc = NSEvent.mouseLocation
            if self.activeInteractionRegion.contains(loc) {
                self.executeOpen()
            } else {
                Logger.window.debug("[Hover] OPEN_DELAY_CANCELLED reason=cursorLeftBeforeDelayEnded")
            }
        }
    }

    private func cancelOpenDelay(reason: String) {
        openTask?.cancel()
        openTask = nil
        if isPendingOpen {
            isPendingOpen = false
            Logger.window.debug("[Hover] OPEN_DELAY_CANCELLED reason=\(reason)")
        }
    }

    private func executeOpen() {
        openTask?.cancel()
        openTask = nil
        isPendingOpen = false
        state = .opening
        Logger.window.info("[Hover] ENTER_NOTCH -> OPENING")
    }

    public func notifyExpandedComplete() {
        if state == .opening {
            state = .expanded
            Logger.window.info("[Hover] EXPANDED")
        }
    }

    // MARK: — Close Sequence (with Close Delay + Grace Period)

    private func scheduleClose() {
        let settings = HoverSettings.shared
        guard state == .opening || state == .expanded else { return }
        guard !isPendingClose else { return }

        openTask?.cancel()
        openTask = nil
        isPendingOpen = false

        let totalDelayMs = settings.closeDelay + settings.hoverGracePeriod
        isPendingClose = true
        state = .closing
        Logger.window.debug("[Hover] EXIT_DETECTED -> CLOSE_DELAY_STARTED totalMs=\(totalDelayMs)")

        closeTask?.cancel()
        closeTask = Task { @MainActor in
            let ns = UInt64(totalDelayMs) * 1_000_000
            try? await Task.sleep(nanoseconds: ns)

            guard !Task.isCancelled else {
                Logger.window.debug("[Hover] CLOSE_CANCELLED reason=taskCancelled")
                return
            }

            self.isPendingClose = false

            // Authoritative final position verification
            let loc = NSEvent.mouseLocation
            if self.activeInteractionRegion.contains(loc) {
                Logger.window.debug("[Hover] CLOSE_CANCELLED reason=cursorReturnedDuringGrace")
                self.state = .expanded
                return
            }

            self.executeCollapse(reason: .verifiedMouseExit)
        }
    }

    private func cancelClose(reason: String) {
        closeTask?.cancel()
        closeTask = nil
        if isPendingClose || state == .closing {
            isPendingClose = false
            state = .expanded
            Logger.window.debug("[Hover] CLOSE_CANCELLED reason=\(reason)")
        }
    }

    public func executeCollapse(reason: CollapseReason) {
        closeTask?.cancel()
        closeTask = nil
        openTask?.cancel()
        openTask = nil
        isPendingOpen = false
        isPendingClose = false

        lastCollapseReason = reason
        state = .collapsed
        Logger.window.info("[Hover] COLLAPSE reason=\(reason.description)")
    }

    // MARK: — Manual Toggle (⌘E)

    public func toggleManual() {
        openTask?.cancel()
        openTask = nil
        closeTask?.cancel()
        closeTask = nil
        isPendingOpen = false
        isPendingClose = false

        if state.isOpenOrOpening {
            executeCollapse(reason: .manual)
        } else {
            state = .opening
            Logger.window.info("[Hover] MANUAL_TOGGLE -> OPENING")
        }
    }

    // MARK: — External Collapse Guard

    public func isCollapseAllowed(reason: String) -> Bool {
        let settings = HoverSettings.shared

        // Specific setting checks
        if reason.lowercased().contains("volume") && settings.ignoreVolumeHUD {
            Logger.window.warning("[Hover] IGNORED_INVALID_COLLAPSE reason=VOLUME_CHANGE")
            return false
        }
        if reason.lowercased().contains("brightness") && settings.ignoreBrightnessHUD {
            Logger.window.warning("[Hover] IGNORED_INVALID_COLLAPSE reason=BRIGHTNESS_CHANGE")
            return false
        }
        if reason.lowercased().contains("media") && settings.ignoreMediaUpdates {
            Logger.window.warning("[Hover] IGNORED_INVALID_COLLAPSE reason=MEDIA_UPDATE")
            return false
        }
        if reason.lowercased().contains("space") && settings.ignoreSpaceChanges {
            Logger.window.warning("[Hover] IGNORED_INVALID_COLLAPSE reason=SPACE_CHANGE")
            return false
        }

        let loc = NSEvent.mouseLocation
        if activeInteractionRegion.contains(loc) {
            Logger.window.warning("[Hover] IGNORED_INVALID_COLLAPSE reason=\(reason) (cursor inside region)")
            return false
        }

        if state.isOpenOrOpening && !settings.collapseOnMouseExit {
            Logger.window.warning("[Hover] IGNORED_INVALID_COLLAPSE reason=\(reason) (collapseOnMouseExit disabled)")
            return false
        }

        return true
    }

    private func reevaluateSettings() {
        if let metrics = cachedMetrics {
            updateRegions(with: metrics)
        }
        checkMousePosition()
    }
}
