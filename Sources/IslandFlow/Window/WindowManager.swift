import AppKit
import SwiftUI
import Combine

/// WindowManager owns the single IslandPanel and keeps it permanently anchored
/// flush to the physical screen top (notch).
///
/// ┌─────────────────────────────────────────────────────────────────────────┐
/// │  PHASE 7 ARCHITECTURE                                                   │
/// │                                                                         │
/// │  The NSPanel is ALWAYS sized to the maximum expanded island dimensions  │
/// │  (expandedWidth × expandedHeight). It NEVER resizes during interaction. │
/// │                                                                         │
/// │  All visible morphing — from collapsed notch to full island — happens   │
/// │  100% within SwiftUI via LiquidIslandShape(progress: expansionProgress) │
/// │                                                                         │
/// │  Panel frame only changes on:                                           │
/// │    • Screen parameters changed (display connect / disconnect)           │
/// │    • Space transition lock released                                     │
/// │                                                                         │
/// │  Frame formula (permanent):                                             │
/// │    panelX = notchCenterX − expandedWidth / 2                           │
/// │    panelY = screenFrame.maxY − expandedHeight    ← top locked to bezel │
/// │    panelW = expandedWidth                                               │
/// │    panelH = expandedHeight                                              │
/// └─────────────────────────────────────────────────────────────────────────┘
@MainActor
public final class WindowManager: ObservableObject {
    public static let shared = WindowManager()

    // MARK: — Expanded island dimensions (panel is always this size)

    /// Maximum expanded island width. The panel is always this wide.
    public static let expandedWidth:  CGFloat = 350.0
    /// Maximum expanded island height. The panel is always this tall.
    public static let expandedHeight: CGFloat = 145.0

    // MARK: — Private state

    private var panel: IslandPanel?
    private var cancellables = Set<AnyCancellable>()

    /// When true, space transition is in progress — skip repositioning to avoid jitter.
    private var isSpaceTransitioning: Bool = false
    private var spaceLockTask: Task<Void, Never>?

    // MARK: — Init

    private init() {
        observeSystemEvents()
    }

    // MARK: — System event observers

    private func observeSystemEvents() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSpaceChanged),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func handleSpaceChanged() {
        Task { @MainActor in
            Logger.window.info("[IslandFlow][SPACE] Active space transition detected")
            isSpaceTransitioning = true
            spaceLockTask?.cancel()
            spaceLockTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 400_000_000) // 400 ms lock
                guard !Task.isCancelled else { return }
                isSpaceTransitioning = false
                Logger.window.info("[IslandFlow][SPACE] Lock released — re-verifying alignment")
                repositionPanel()
            }
        }
    }

    @objc private func handleScreenParametersChanged() {
        Task { @MainActor in
            Logger.window.info("[IslandFlow][SCREEN] Parameters changed — invalidating cache")
            ScreenManager.shared.invalidateCache()
            repositionPanel()
        }
    }

    // MARK: — Setup

    /// Create and show the IslandPanel. Called once at app launch.
    public func setupWindow() {
        guard panel == nil else { return }

        let metrics = ScreenManager.shared.activeScreenMetrics()

        // Set initial island state (content selection only — not geometry)
        AppState.shared.islandState = metrics.hasNotch ? .notchCover : .compact

        let frame = panelFrame(metrics: metrics)
        let panel = IslandPanel(contentRect: frame)

        // ── View hierarchy ────────────────────────────────────────────────────
        // IslandHostingContainer (NSView — owns stable NSTrackingArea)
        //   └── NSHostingView<IslandContainerView> (SwiftUI root)
        let container = IslandHostingContainer(frame: CGRect(origin: .zero, size: frame.size))
        container.autoresizingMask = [.width, .height]

        let hostingView = NSHostingView(rootView: IslandContainerView())
        hostingView.frame = container.bounds
        hostingView.autoresizingMask = [.width, .height]
        container.addSubview(hostingView)

        panel.contentView = container

        // Wire hover events → Notification → IslandContainerView
        container.onHoverChanged = { hovering in
            NotificationCenter.default.post(
                name: .islandHoverChanged,
                object: hovering
            )
        }

        panel.orderFrontRegardless()
        self.panel = panel

        printDiagnostics(metrics: metrics, frame: frame)
    }

    // MARK: — Repositioning (screen/space changes only)

    /// Reposition the stationary panel to match current screen metrics.
    /// Only called from screen-parameter or space-transition handlers.
    /// NEVER called during hover interaction.
    public func repositionPanel() {
        guard let panel = panel, !isSpaceTransitioning else { return }
        let metrics = ScreenManager.shared.activeScreenMetrics()
        let newFrame = panelFrame(metrics: metrics)
        panel.setFrame(newFrame, display: true)

        // Verify top edge invariant
        let delta = abs(newFrame.maxY - metrics.screenFrame.maxY)
        Logger.window.info("""
            [IslandFlow][REPOSITION] frame:\(String(describing: newFrame)) \
            topDelta:\(delta)
            """)
    }

    // MARK: — Frame calculation

    /// Compute the NSPanel frame. The panel is always expandedWidth × expandedHeight,
    /// with the top edge locked flush to screenFrame.maxY (physical display top).
    private func panelFrame(metrics: ScreenMetrics) -> CGRect {
        let w = WindowManager.expandedWidth
        let h = WindowManager.expandedHeight
        let centerX = metrics.topFlushPoint.x   // horizontal center of notch
        let x = centerX - w / 2.0

        let y: CGFloat
        if metrics.hasNotch {
            // Notch display: pin top edge absolutely flush with screen top bezel.
            y = metrics.screenFrame.maxY - h
        } else {
            // External display: float below menu bar with small gap.
            y = metrics.visibleFrame.maxY - h - 4.0
        }

        return CGRect(x: x, y: y, width: w, height: h)
    }

    // MARK: — Diagnostics

    private func printDiagnostics(metrics: ScreenMetrics, frame: CGRect) {
        let topDelta = abs(frame.maxY - metrics.screenFrame.maxY)
        print("""
        ============================================================
        ISLANDFLOW PHASE 7 — STATIONARY PANEL GEOMETRY REPORT
        ============================================================
        SCREEN FRAME:        \(metrics.screenFrame)
        VISIBLE FRAME:       \(metrics.visibleFrame)
        HAS NOTCH:           \(metrics.hasNotch)
        SAFE AREA TOP INSET: \(metrics.safeAreaTopInset)  ← collapsed height
        NOTCH WIDTH:         \(metrics.notchWidth)         ← collapsed width
        NOTCH CORNER RADIUS: 10.0 pt                      ← collapsed radius
        EXPANDED WIDTH:      \(WindowManager.expandedWidth)
        EXPANDED HEIGHT:     \(WindowManager.expandedHeight)
        EXPANDED RADIUS:     22.0 pt
        PANEL FRAME:         \(frame)
        PANEL TOP (AppKit):  \(frame.maxY)   ← must equal SCREEN TOP
        SCREEN TOP (AppKit): \(metrics.screenFrame.maxY)
        TOP DELTA:           \(topDelta)     ← must be 0.0
        ============================================================
        """)
    }
}
