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
            expandedRadius:  expandedRadius,
            topFlush:        metrics.hasNotch
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
        max(0, min(1, (Double(expansionProgress) - 0.25) / 0.75))
    }

    private var contentOpacity: Double {
        max(0, min(1, (Double(expansionProgress) - 0.40) / 0.40))
    }

    // MARK: — Body

    public var body: some View {
        let content = ZStack(alignment: .top) {
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
                .overlay(
                    Rectangle()
                        .stroke(Color.red.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .overlay(
                            Text("CLICK-THROUGH OUTER BOUNDS")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.red.opacity(0.7))
                                .padding(2),
                            alignment: .bottomTrailing
                        )
                )
            }
        }
        .frame(width: expandedWidth, height: expandedHeight)
        .animation(islandAnimation, value: expansionProgress)
        .onReceive(interactionController.$state) { newState in
            handleInteractionStateChanged(newState)
        }
        .contentShape(islandShape)
        .onTapGesture { handleTapGesture() }

        if #available(macOS 14.0, *) {
            content.onChange(of: expansionProgress) { _, newValue in
                appState.expansionProgress = newValue
                if newValue >= 0.999 {
                    interactionController.notifyExpandedComplete()
                } else if newValue <= 0.001 {
                    interactionController.notifyCollapsedComplete()
                }
            }
        } else {
            content.onChange(of: expansionProgress) { newValue in
                appState.expansionProgress = newValue
                if newValue >= 0.999 {
                    interactionController.notifyExpandedComplete()
                } else if newValue <= 0.001 {
                    interactionController.notifyCollapsedComplete()
                }
            }
        }
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
                switch appState.islandState {
                case .volume(let volumeState):
                    VolumeView(state: volumeState)
                        .transition(.opacity)
                case .brightness(let brightnessState):
                    BrightnessView(state: brightnessState)
                        .transition(.opacity)
                case .battery(let batteryState):
                    BatteryView(state: batteryState)
                        .transition(.opacity)
                default:
                    if mediaManager.isMediaActive {
                        MediaView(state: mediaManager.currentState)
                            .transition(.opacity)
                    } else {
                        islandHoverHint
                            .transition(.opacity)
                    }
                }
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
        case .opening, .expanded:
            appState.setHovered(true)
            expandContentState()
            expansionProgress = 1.0
            Logger.window.info("[Island] geometry: expanding target progress=1.0")

        case .closing, .collapsed:
            appState.setHovered(false)
            collapseContentState()
            expansionProgress = 0.0
            Logger.window.info("[Island] geometry: collapsing target progress=0.0")
        }
    }

    // MARK: — Content state helpers

    private func expandContentState() {
        if case .volume = appState.islandState { return }
        if case .brightness = appState.islandState { return }
        if case .battery = appState.islandState { return }

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
