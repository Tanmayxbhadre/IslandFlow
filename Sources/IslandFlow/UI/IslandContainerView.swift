import SwiftUI
import Combine

/// IslandContainerView — the entire island rendered inside the stationary NSPanel canvas.
///
/// Phase 10 Model:
///   • Animation spring parameters derived from HoverSettings.shared.animationSpeed.
///   • Expansion progress is synchronized with AppState.shared for debug monitoring.
///   • HoverDebugView overlay conditionally displayed when debugHoverState is enabled.
public struct IslandContainerView: View {
    @ObservedObject private var appState:              AppState                    = AppState.shared
    @ObservedObject private var mediaManager:          MediaManager                = MediaManager.shared
    @ObservedObject private var interactionController: IslandInteractionController = IslandInteractionController.shared
    @ObservedObject private var settings:             HoverSettings               = HoverSettings.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: — Master expansion state

    @State private var expansionProgress: CGFloat = 0.0

    // MARK: — Fixed geometry constants

    private var metrics:         ScreenMetrics { ScreenManager.shared.activeScreenMetrics() }
    private var collapsedWidth:  CGFloat       { metrics.notchWidth }
    private var collapsedHeight: CGFloat       { metrics.safeAreaTopInset }
    private let expandedWidth:   CGFloat       = WindowManager.expandedWidth
    private let expandedHeight:  CGFloat       = WindowManager.expandedHeight
    private let collapsedRadius: CGFloat       = 10.0
    private let expandedRadius:  CGFloat       = 22.0
    private var contentHeight:   CGFloat       { expandedHeight - collapsedHeight }

    // MARK: — Shape

    private var islandShape: LiquidIslandShape {
        LiquidIslandShape(
            progress:        expansionProgress,
            collapsedWidth:  collapsedWidth,
            collapsedHeight: collapsedHeight,
            expandedWidth:   expandedWidth,
            expandedHeight:  expandedHeight,
            collapsedRadius: collapsedRadius,
            expandedRadius:  expandedRadius
        )
    }

    // MARK: — Animation

    private var islandAnimation: Animation {
        if reduceMotion {
            return .linear(duration: 0.12)
        }
        let speed = settings.animationSpeed
        return .spring(response: speed.response, dampingFraction: speed.dampingFraction)
    }

    // MARK: — Derived appearance

    private var surfaceDecorationOpacity: Double {
        max(0, min(1, (Double(expansionProgress) - 0.35) / 0.55))
    }

    private var contentOpacity: Double {
        max(0, min(1, (Double(expansionProgress) - 0.45) / 0.30))
    }

    // MARK: — Body

    public var body: some View {
        ZStack(alignment: .top) {
            backgroundSurface
            contentLayer
            
            if settings.debugHoverState {
                VStack {
                    Spacer()
                    HStack {
                        HoverDebugView()
                        Spacer()
                    }
                }
                .padding(8)
            }
        }
        .frame(width: expandedWidth, height: expandedHeight)
        .animation(islandAnimation, value: expansionProgress)
        .onChange(of: expansionProgress) { newValue in
            appState.expansionProgress = newValue
            if newValue >= 0.999 {
                interactionController.notifyExpandedComplete()
            }
        }
        .onReceive(interactionController.$state) { newState in
            handleInteractionStateChanged(newState)
        }
        .onReceive(appState.$islandState) { newState in
            handleContentStateChanged(newState)
        }
        .contentShape(Rectangle())
        .onTapGesture { handleTapGesture() }
    }

    // MARK: — Background Surface

    @ViewBuilder
    private var backgroundSurface: some View {
        ZStack {
            islandShape
                .fill(Color.black)

            islandShape
                .fill(.ultraThinMaterial)
                .overlay(islandShape.fill(Color.black.opacity(0.88)))
                .overlay(
                    islandShape.stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.18), .white.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
                )
                .shadow(color: .black.opacity(0.50), radius: 12, x: 0, y: 5)
                .opacity(surfaceDecorationOpacity)
        }
    }

    // MARK: — Content Layer

    @ViewBuilder
    private var contentLayer: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: collapsedHeight)

            ZStack {
                MediaView(state: mediaManager.currentState)
                    .opacity(mediaManager.isMediaActive ? 1.0 : 0.0)

                islandHoverHint
                    .opacity(mediaManager.isMediaActive ? 0.0 : 1.0)
            }
            .frame(width: expandedWidth, height: contentHeight)
        }
        .frame(width: expandedWidth, height: expandedHeight, alignment: .top)
        .opacity(contentOpacity)
        .clipShape(islandShape)
    }

    @ViewBuilder
    private var islandHoverHint: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.20))
                    .frame(width: 32, height: 32)
                Image(systemName: "waveform")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.cyan)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("IslandFlow")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("No media playing")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.50))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: expandedWidth, height: contentHeight)
    }

    // MARK: — Interaction State Handler

    private func handleInteractionStateChanged(
        _ newState: IslandInteractionController.InteractionState
    ) {
        switch newState {
        case .opening:
            appState.setHovered(true)
            expandContentState()
            withAnimation(islandAnimation) {
                expansionProgress = 1.0
            }
            Logger.window.info("[Island] geometry: expanding progress=1.0")

        case .closing, .collapsed:
            appState.setHovered(false)
            collapseContentState()
            withAnimation(islandAnimation) {
                expansionProgress = 0.0
            }
            Logger.window.info("[Island] geometry: collapsing progress=0.0 reason=VERIFIED_MOUSE_EXIT")

        case .expanded:
            break
        }
    }

    // MARK: — Content State Handler

    private func handleContentStateChanged(_ state: IslandState) {
        switch state {
        case .notchCover, .compact:
            if interactionController.isInsideRegion {
                Logger.window.warning("""
                    [Island] Content state → collapsed while cursor inside region. \
                    Ignored: geometry unchanged.
                    """)
            }
        default:
            break
        }
    }

    // MARK: — Content state helpers

    private func expandContentState() {
        if mediaManager.isMediaActive {
            appState.islandState = .mediaExpanded(mediaManager.currentState)
        } else {
            appState.islandState = metrics.hasNotch ? .hover : .expanded
        }
    }

    private func collapseContentState() {
        if mediaManager.isMediaActive {
            appState.islandState = .mediaCompact(mediaManager.currentState)
        } else {
            appState.islandState = metrics.hasNotch ? .notchCover : .compact
        }
    }

    // MARK: — Tap Logic

    private func handleTapGesture() {
        if mediaManager.isMediaActive {
            if case .mediaExpanded = appState.islandState {
                appState.islandState = .mediaCompact(mediaManager.currentState)
            } else {
                appState.islandState = .mediaExpanded(mediaManager.currentState)
            }
        }
    }
}
