import SwiftUI

/// IslandContainerView — the single container that IS the island.
///
/// Architecture:
/// ┌──────────────────────────────────────────────────────────────┐
/// │  FluidIslandShape(cornerRadius: animatedRadius)              │
/// │    ↕ fills AND clips all content                             │
/// │  Content VStack                                              │
/// │    ↕ opacity tied to the current island size                 │
/// │    ↕ clipped by the SAME FluidIslandShape                    │
/// └──────────────────────────────────────────────────────────────┘
///
/// The notch anchor is maintained by WindowManager: it always sets
/// panel.origin.y = screenFrame.maxY − panel.height, so the top
/// edge is physically glued to the screen bezel at all times.
/// SwiftUI's own `.animation` interpolates width/height/cornerRadius
/// driving the FluidIslandShape path on every display frame.
public struct IslandContainerView: View {
    @ObservedObject var appState: AppState = AppState.shared
    @ObservedObject var mediaManager: MediaManager = MediaManager.shared
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @State private var hoverTask: Task<Void, Never>?

    // MARK: — Derived geometry from current state

    private var metrics: ScreenMetrics { ScreenManager.shared.activeScreenMetrics() }
    private var isTopFlush: Bool { metrics.hasNotch }

    private var targetSize: CGSize { appState.islandState.size }
    private var targetCornerRadius: CGFloat { appState.islandState.cornerRadius }

    // Content is visible only once the island is large enough to show it.
    // We measure "large enough" by checking if the state is bigger than notchCover.
    private var contentOpacity: Double {
        switch appState.islandState {
        case .notchCover:
            return 0.0
        case .hover:
            return 1.0
        default:
            return 1.0
        }
    }

    // Spring animation used for all geometry + content transitions.
    // Matching this in WindowManager ensures panel frame and SwiftUI shape animate in lock-step.
    private var islandAnimation: Animation {
        reduceMotion
            ? .linear(duration: 0.12)
            : .spring(response: 0.26, dampingFraction: 0.88)
    }

    // The shape that fills, strokes, and clips the island.
    private var islandShape: FluidIslandShape {
        FluidIslandShape(topFlush: isTopFlush, cornerRadius: targetCornerRadius)
    }

    // MARK: — Body

    public var body: some View {
        ZStack(alignment: .top) {
            // ── Background surface ──────────────────────────────────────────
            // ONE continuous surface. We never switch between two shapes.
            // The shape path updates every frame as targetCornerRadius animates.
            backgroundSurface

            // ── Content ────────────────────────────────────────────────────
            // Always in the hierarchy, opacity-faded when not relevant.
            // Clipped by the SAME FluidIslandShape, so content is physically
            // swallowed as the island contracts into the notch.
            contentLayer
                .clipShape(islandShape)
                .opacity(contentOpacity)
        }
        // The frame is what SwiftUI animates — width & height interpolate smoothly.
        // FluidIslandShape.path(in:) is called by SwiftUI every frame with the
        // current interpolated bounds, producing a continuously morphing shape.
        .frame(
            width: targetSize.width,
            height: targetSize.height,
            alignment: .top
        )
        .animation(islandAnimation, value: appState.islandState)
        .onHover { hovering in
            appState.setHovered(hovering)
            handleHoverChanged(hovering)
        }
        .onTapGesture {
            handleTapGesture()
        }
        .contentShape(Rectangle())
    }

    // MARK: — Background Surface

    @ViewBuilder
    private var backgroundSurface: some View {
        if appState.islandState == .notchCover {
            // Pure solid black — indistinguishable from physical MacBook notch.
            islandShape
                .fill(Color.black)
        } else {
            // Unified island surface. ONE shape, ONE material.
            islandShape
                .fill(.ultraThinMaterial)
                .overlay(islandShape.fill(Color.black.opacity(0.88)))
                .overlay(
                    islandShape.stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.20), .white.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
                )
                .shadow(
                    color: .black.opacity(0.45),
                    radius: appState.isHovered ? 10 : 5,
                    x: 0, y: 2
                )
        }
    }

    // MARK: — Content Layer

    @ViewBuilder
    private var contentLayer: some View {
        VStack(spacing: 0) {
            islandContent
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var islandContent: some View {
        Group {
            switch appState.islandState {
            case .notchCover:
                Color.clear
                    .frame(
                        width: appState.islandState.size.width,
                        height: appState.islandState.size.height
                    )

            case .hover:
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 6, height: 6)
                    Text("IslandFlow")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(height: appState.islandState.size.height)
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))

            case .compact:
                CompactIslandView(appState: appState)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.95)))

            case .expanded:
                ExpandedIslandView(appState: appState)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.98)))

            case .mediaCompact(let state):
                CompactMediaView(state: state)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))

            case .mediaExpanded(let state):
                MediaView(state: state)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.98)))

            case .battery(let state):
                BatteryView(state: state)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))

            case .volume(let state):
                VolumeView(state: state)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))

            case .brightness(let state):
                BrightnessView(state: state)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
            }
        }
    }

    // MARK: — Hover Logic

    private func handleHoverChanged(_ hovering: Bool) {
        // Cancelling hoverTask immediately stops any pending collapse,
        // letting SwiftUI reverse the current spring animation naturally.
        hoverTask?.cancel()

        if hovering {
            withAnimation(islandAnimation) {
                expandIsland()
            }
        } else {
            // Short grace period — if cursor returns, task is cancelled and island stays open.
            hoverTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 200_000_000) // 200 ms
                guard !Task.isCancelled else { return }
                withAnimation(islandAnimation) {
                    collapseIsland()
                }
            }
        }
    }

    private func expandIsland() {
        if mediaManager.isMediaActive {
            appState.islandState = .mediaExpanded(mediaManager.currentState)
        } else if appState.islandState == .notchCover || appState.islandState == .compact {
            appState.islandState = metrics.hasNotch ? .hover : .expanded
        }
    }

    private func collapseIsland() {
        if mediaManager.isMediaActive {
            appState.islandState = .mediaCompact(mediaManager.currentState)
        } else {
            appState.islandState = metrics.hasNotch ? .notchCover : .compact
        }
    }

    // MARK: — Tap Logic

    private func handleTapGesture() {
        withAnimation(islandAnimation) {
            if mediaManager.isMediaActive {
                if case .mediaExpanded = appState.islandState {
                    appState.islandState = .mediaCompact(mediaManager.currentState)
                } else {
                    appState.islandState = .mediaExpanded(mediaManager.currentState)
                }
            } else {
                if appState.islandState == .expanded {
                    appState.islandState = metrics.hasNotch ? .notchCover : .compact
                } else {
                    appState.islandState = .expanded
                }
            }
        }
    }
}
