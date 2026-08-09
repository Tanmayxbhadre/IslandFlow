import AppKit
import SwiftUI
import Combine

/// WindowManager owns the single IslandPanel and keeps its frame anchored to the
/// top of the screen (notch) at all times.
///
/// Frame calculation:
///   originY = screenFrame.maxY − height        → top edge stays fixed to screen top
///   originX = topFlushPoint.x − width / 2      → centered on notch
///
/// The panel is sized to the *current target state* dimensions.
/// SwiftUI's .animation(value: islandState) ensures the FluidIslandShape
/// morphs continuously within that frame; the panel frame is animated by
/// NSAnimationContext to match the spring timing.
@MainActor
public final class WindowManager: ObservableObject {
    public static let shared = WindowManager()

    private var panel: IslandPanel?
    private var cancellables = Set<AnyCancellable>()

    // Animation spring that MATCHES IslandContainerView's islandAnimation.
    // Duration ≈ spring response (0.26s). This keeps panel frame and SwiftUI shape in sync.
    private let animationDuration: TimeInterval = 0.26

    private init() {}

    public func setupWindow() {
        guard panel == nil else { return }

        let metrics = ScreenManager.shared.activeScreenMetrics()
        let initialState: IslandState = metrics.hasNotch ? .notchCover : .compact
        AppState.shared.islandState = initialState

        let frame = panelFrame(for: initialState, metrics: metrics)

        let panel = IslandPanel(contentRect: frame)
        let hostingView = NSHostingView(rootView: IslandContainerView())
        hostingView.frame = CGRect(origin: .zero, size: frame.size)
        panel.contentView = hostingView
        panel.orderFrontRegardless()
        self.panel = panel

        // Observe state changes and update panel frame to match.
        AppState.shared.$islandState
            .receive(on: RunLoop.main)
            .sink { [weak self] newState in
                self?.updatePanelFrame(for: newState)
            }
            .store(in: &cancellables)

        let collapsedFrame = panelFrame(for: .notchCover, metrics: metrics)
        let expandedFrame = panelFrame(for: .mediaExpanded(MediaState()), metrics: metrics)

        print("""
        ============================================================
        ISLANDFLOW DIAGNOSTIC GEOMETRY REPORT
        ============================================================
        SCREEN FRAME: x:\(metrics.screenFrame.origin.x) y:\(metrics.screenFrame.origin.y) width:\(metrics.screenFrame.width) height:\(metrics.screenFrame.height)
        VISIBLE FRAME: x:\(metrics.visibleFrame.origin.x) y:\(metrics.visibleFrame.origin.y) width:\(metrics.visibleFrame.width) height:\(metrics.visibleFrame.height)
        SCALE FACTOR: \(metrics.targetScreen.backingScaleFactor)
        HAS NOTCH: \(metrics.hasNotch)
        SAFE AREA TOP INSET: \(metrics.safeAreaTopInset)
        COMPUTED NOTCH WIDTH: \(metrics.notchWidth)
        
        ISLAND COLLAPSED STATE (.notchCover): \(IslandState.notchCover.size)
        ISLAND COLLAPSED FRAME: \(collapsedFrame)
        
        ISLAND MEDIA COMPACT STATE: \(IslandState.mediaCompact(MediaState()).size)
        ISLAND MEDIA COMPACT FRAME: \(panelFrame(for: .mediaCompact(MediaState()), metrics: metrics))
        
        ISLAND EXPANDED STATE (.mediaExpanded): \(IslandState.mediaExpanded(MediaState()).size)
        ISLAND EXPANDED FRAME: \(expandedFrame)
        
        INITIAL PANEL FRAME: \(frame)
        ============================================================
        """)

        Logger.window.info("""
            [IslandFlow] Setup — screen:\(String(describing: metrics.screenFrame)) \
            hasNotch:\(metrics.hasNotch) notchW:\(metrics.notchWidth) \
            safeTop:\(metrics.safeAreaTopInset) initialFrame:\(String(describing: frame))
            """)
    }

    public func updatePanelFrame(for state: IslandState) {
        guard let panel = panel else { return }
        let metrics = ScreenManager.shared.activeScreenMetrics()
        let newFrame = panelFrame(for: state, metrics: metrics)

        Logger.window.debug("""
            [IslandFlow] State→\(String(describing: state)) \
            frame:\(String(describing: newFrame))
            """)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = animationDuration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            ctx.allowsImplicitAnimation = true
            panel.animator().setFrame(newFrame, display: true, animate: true)
        }
    }

    // MARK: — Frame calculation

    /// Compute the NSPanel frame for a given state.
    /// Top edge is always anchored to screenFrame.maxY (the physical display top border).
    private func panelFrame(for state: IslandState, metrics: ScreenMetrics) -> CGRect {
        let size = state.size
        let centerX = metrics.topFlushPoint.x        // horizontal center of notch
        let x = centerX - size.width / 2.0
        let y: CGFloat

        if metrics.hasNotch {
            // For all notch-display states: pin top edge flush to display top.
            y = metrics.screenFrame.maxY - size.height
        } else {
            // External / non-notch display: float below menu bar.
            y = metrics.visibleFrame.maxY - size.height - 4.0
        }

        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}
