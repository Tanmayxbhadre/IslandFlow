import AppKit
import SwiftUI
import Combine

/// WindowManager owns the single IslandPanel and keeps it permanently anchored
/// flush to the physical screen top (notch).
///
/// Phase 9 additions:
///   • Calls IslandInteractionController.shared.setup(with:) after panel creation.
///   • Calls IslandInteractionController.shared.updateRegion(with:) after every
///     repositioning so the interaction region stays in sync with the panel.
///   • NO longer wires onHoverChanged from IslandHostingContainer (removed in Phase 9).
@MainActor
public final class WindowManager: ObservableObject {
    public static let shared = WindowManager()

    // MARK: — Expanded island dimensions (panel is always this size)

    /// Maximum expanded island width — panel is always exactly this wide.
    public static let expandedWidth:  CGFloat = 350.0
    /// Maximum expanded island height — panel is always exactly this tall.
    public static let expandedHeight: CGFloat = 145.0

    // MARK: — Private state

    private var panel: IslandPanel?
    private var cancellables = Set<AnyCancellable>()

    /// Lock that prevents repositioning during a Space transition.
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
                try? await Task.sleep(nanoseconds: 400_000_000) // 400 ms
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

    // MARK: — Setup (called once at app launch)

    public func setupWindow() {
        guard panel == nil else { return }

        let metrics = ScreenManager.shared.activeScreenMetrics()

        // Initial content state
        AppState.shared.islandState = metrics.hasNotch ? .notchCover : .compact

        let frame = panelFrame(metrics: metrics)
        let panel = IslandPanel(contentRect: frame)

        // ── View hierarchy ─────────────────────────────────────────────────
        // IslandHostingContainer (NSView — plain pass-through in Phase 9)
        //   └── NSHostingView<IslandContainerView> (SwiftUI root)
        let container = IslandHostingContainer(
            frame: CGRect(origin: .zero, size: frame.size)
        )
        container.autoresizingMask = [.width, .height]

        let hostingView = NSHostingView(rootView: IslandContainerView())
        hostingView.frame = container.bounds
        hostingView.autoresizingMask = [.width, .height]
        container.addSubview(hostingView)

        panel.contentView = container

        // Phase 9: No onHoverChanged wiring — IslandInteractionController owns hover.

        panel.orderFrontRegardless()
        self.panel = panel

        // ── Wire interaction controller ─────────────────────────────────────
        // Must happen AFTER the panel frame is established, so the interaction
        // region is computed from the final screen coordinates.
        IslandInteractionController.shared.setup(with: metrics)

        printDiagnostics(metrics: metrics, frame: frame)
    }

    // MARK: — Repositioning (screen/space changes only — NEVER during hover)

    public func repositionPanel() {
        guard let panel = panel, !isSpaceTransitioning else { return }
        let metrics = ScreenManager.shared.activeScreenMetrics()
        let newFrame = panelFrame(metrics: metrics)

        panel.setFrame(newFrame, display: true)

        // Keep interaction region in sync — transparent to IslandInteractionController.state.
        // This does NOT reset hover or trigger any animation.
        IslandInteractionController.shared.updateRegion(with: metrics)

        let delta = abs(newFrame.maxY - metrics.screenFrame.maxY)
        Logger.window.info("""
            [IslandFlow][REPOSITION] frame:\(String(describing: newFrame)) topDelta:\(delta)
            """)
    }

    // MARK: — Frame calculation

    private func panelFrame(metrics: ScreenMetrics) -> CGRect {
        let w = WindowManager.expandedWidth
        let h = WindowManager.expandedHeight
        let cx = metrics.topFlushPoint.x
        let x = cx - w / 2.0
        let y: CGFloat = metrics.hasNotch
            ? metrics.screenFrame.maxY - h
            : metrics.visibleFrame.maxY - h - 4.0
        return CGRect(x: x, y: y, width: w, height: h)
    }

    // MARK: — Diagnostics

    private func printDiagnostics(metrics: ScreenMetrics, frame: CGRect) {
        let topDelta = abs(frame.maxY - metrics.screenFrame.maxY)
        print("""
        ============================================================
        ISLANDFLOW PHASE 9 — STATIONARY PANEL GEOMETRY REPORT
        ============================================================
        SCREEN FRAME:        \(metrics.screenFrame)
        VISIBLE FRAME:       \(metrics.visibleFrame)
        HAS NOTCH:           \(metrics.hasNotch)
        SAFE AREA TOP INSET: \(metrics.safeAreaTopInset)  ← collapsed height
        NOTCH WIDTH:         \(metrics.notchWidth)         ← collapsed width
        EXPANDED WIDTH:      \(WindowManager.expandedWidth)
        EXPANDED HEIGHT:     \(WindowManager.expandedHeight)
        CONTENT HEIGHT:      \(WindowManager.expandedHeight - metrics.safeAreaTopInset)  ← below notch
        PANEL FRAME:         \(frame)
        PANEL TOP (AppKit):  \(frame.maxY)   ← must equal SCREEN TOP
        SCREEN TOP (AppKit): \(metrics.screenFrame.maxY)
        TOP DELTA:           \(topDelta)     ← must be 0.0
        ============================================================
        """)
    }
}
