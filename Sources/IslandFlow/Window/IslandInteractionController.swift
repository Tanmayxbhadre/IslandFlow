import AppKit
import Combine

// MARK: — IslandInteractionController

/// Single authoritative source of truth for island hover/expansion interaction.
///
/// ┌─────────────────────────────────────────────────────────────────────────┐
/// │  PHASE 9 INTERACTION ARCHITECTURE                                       │
/// │                                                                         │
/// │  Problem with NSTrackingArea (Phase 7/8):                               │
/// │    NSHostingView child views (SwiftUI buttons, text, etc.) interfere    │
/// │    with the parent container's tracking area. AppKit generates          │
/// │    mouseExited on the container when cursor enters a child view,        │
/// │    even when the cursor never left the panel bounds. This caused        │
/// │    spurious isHovered=false → collapse bugs.                            │
/// │                                                                         │
/// │  Solution (Phase 9):                                                    │
/// │    Use a global+local NSEvent monitor to capture every cursor movement. │
/// │    On each event, call NSEvent.mouseLocation and check against a stable │
/// │    interactionRegion: NSRect. No child-view interference possible.      │
/// │                                                                         │
/// │  interactionRegion = expanded panel bounds in screen coordinates        │
/// │    (AppKit bottom-origin). Computed once, updated only on               │
/// │    screen/space changes. NEVER changes during hover animation.          │
/// │                                                                         │
/// │  State machine:                                                         │
/// │    .collapsed  cursor outside, progress=0.0                             │
/// │    .opening    cursor entered, progress 0→1 (animation running)         │
/// │    .expanded   cursor inside, progress=1.0 (animation complete)         │
/// │    .closing    cursor exited, grace period, progress 1→0               │
/// │                                                                         │
/// │  Only this controller can trigger expand/collapse geometry changes.     │
/// │  SystemHUDController, MediaManager, SpaceTransitions — NONE of these   │
/// │  can collapse the island directly. They use isCollapseAllowed() guard.  │
/// └─────────────────────────────────────────────────────────────────────────┘
@MainActor
public final class IslandInteractionController: ObservableObject {
    public static let shared = IslandInteractionController()

    // MARK: — Interaction state

    public enum InteractionState: Equatable {
        case collapsed
        case opening
        case expanded
        case closing

        /// True while the island is or is becoming open.
        var isOpenOrOpening: Bool { self == .opening || self == .expanded }
    }

    @Published public private(set) var state: InteractionState = .collapsed

    /// Convenience accessor for external components needing a simple bool.
    public var isInsideRegion: Bool { state.isOpenOrOpening }

    // MARK: — Stable interaction region (AppKit screen coordinates, bottom-origin)

    private var interactionRegion: NSRect = .zero

    // MARK: — Event monitors (one of each, never duplicated)

    private var globalMonitor: Any?
    private var localMonitor: Any?

    // MARK: — Single close-grace task (cancelled on re-entry)

    private var closeTask: Task<Void, Never>?

    // MARK: — Init

    private init() {}

    // MARK: — Setup (called once from WindowManager.setupWindow)

    public func setup(with metrics: ScreenMetrics) {
        interactionRegion = computeRegion(from: metrics)
        Logger.window.info("[Island][INTERACT] Setup region: \(String(describing: self.interactionRegion))")
        startMonitoring()
    }

    /// Update interaction region after screen/space repositioning.
    /// Must NOT change interactionState — repositioning is transparent to hover.
    public func updateRegion(with metrics: ScreenMetrics) {
        interactionRegion = computeRegion(from: metrics)
        Logger.window.debug("[Island][INTERACT] Updated region: \(String(describing: self.interactionRegion))")
    }

    private func computeRegion(from metrics: ScreenMetrics) -> NSRect {
        let w = WindowManager.expandedWidth
        let h = WindowManager.expandedHeight
        let cx = metrics.topFlushPoint.x
        let x = cx - w / 2.0
        let y: CGFloat = metrics.hasNotch
            ? metrics.screenFrame.maxY - h
            : metrics.visibleFrame.maxY - h - 4.0
        return NSRect(x: x, y: y, width: w, height: h)
    }

    // MARK: — Monitoring (started once, never duplicated)

    private func startMonitoring() {
        guard globalMonitor == nil else { return } // Idempotent

        // Global monitor: fires for cursor events delivered to OTHER applications.
        // Since IslandFlow uses .accessory activation policy, it is never the
        // frontmost app. All cursor movements over other apps fire this monitor.
        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        ) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                self?.checkMousePosition()
            }
        }

        // Local monitor: fires for cursor events delivered to OUR application
        // (e.g., when cursor is over our NSPanel with acceptsMouseMovedEvents=true).
        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        ) { [weak self] event in
            DispatchQueue.main.async { [weak self] in
                self?.checkMousePosition()
            }
            return event
        }

        Logger.window.info("[Island][INTERACT] Mouse monitoring started (global + local)")
    }

    // MARK: — Authoritative position check (called on every cursor movement)

    public func checkMousePosition() {
        guard !interactionRegion.isEmpty else { return }
        let loc    = NSEvent.mouseLocation
        let inside = interactionRegion.contains(loc)

        switch state {
        case .collapsed:
            if inside  { didEnter() }
        case .opening:
            if !inside { didExit() }
        case .expanded:
            if !inside { didExit() }
        case .closing:
            if inside  { cancelClose() }
        }
    }

    // MARK: — State transitions

    private func didEnter() {
        guard state == .collapsed else { return }
        closeTask?.cancel()
        closeTask = nil
        state = .opening
        Logger.window.info("[Island] event=mouseEntered state→opening")
    }

    /// Call when the expansion animation completes (progress reached 1.0).
    public func notifyExpandedComplete() {
        if state == .opening { state = .expanded }
    }

    private func didExit() {
        guard state == .opening || state == .expanded else { return }
        state = .closing

        closeTask?.cancel()
        closeTask = Task { @MainActor in
            Logger.window.debug("[Island] event=closeScheduled gracePeriod=200ms")

            try? await Task.sleep(nanoseconds: 200_000_000) // 200 ms grace
            guard !Task.isCancelled else {
                Logger.window.debug("[Island] event=closeCancelled reason=taskCancelled")
                return
            }

            // Final authoritative check: only collapse if cursor genuinely outside.
            let loc = NSEvent.mouseLocation
            if self.interactionRegion.contains(loc) {
                Logger.window.debug("[Island] event=closeCancelled reason=cursorReturnedDuringGrace")
                self.state = .expanded
                return
            }

            Logger.window.info("[Island] event=closing reason=VERIFIED_MOUSE_EXIT")
            self.state = .collapsed
        }
    }

    private func cancelClose() {
        closeTask?.cancel()
        closeTask = nil
        state = .expanded
        Logger.window.debug("[Island] event=closeCancelled reason=mouseEnteredDuringGrace")
    }

    // MARK: — External collapse guard

    /// Returns `true` only when an external component (HUD, media, space)
    /// is permitted to update island content state toward collapse.
    ///
    /// This is called by SystemHUDController before updating islandState.
    /// If the cursor is inside the interaction region, any collapse is blocked.
    ///
    /// The island collapses ONLY for reason = VERIFIED_MOUSE_EXIT.
    public func isCollapseAllowed(reason: String) -> Bool {
        let loc = NSEvent.mouseLocation
        if interactionRegion.contains(loc) {
            Logger.window.warning("[Island] Ignored collapse request: reason=\(reason) cursor=insideRegion")
            return false
        }
        if state.isOpenOrOpening {
            Logger.window.warning("[Island] Ignored collapse request: reason=\(reason) state=\(String(describing: self.state))")
            return false
        }
        return true
    }
}
