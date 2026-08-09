import SwiftUI
import Combine

/// IslandContainerView — the entire island rendered inside the stationary NSPanel canvas.
///
/// ┌─────────────────────────────────────────────────────────────────────────────┐
/// │  PHASE 7 ARCHITECTURE                                                       │
/// │                                                                             │
/// │  The NSPanel is always 350×145 pt. This view fills it completely.          │
/// │  The VISIBLE island surface is determined by LiquidIslandShape(progress:). │
/// │                                                                             │
/// │  ONE master value drives everything:                                        │
/// │    expansionProgress: CGFloat   (0.0 = notch, 1.0 = full island)          │
/// │                                                                             │
/// │  At progress = 0.0:                                                         │
/// │    Visible shape = notchWidth × notchHeight, center-horizontal, top-flush  │
/// │    Appearance = pure black (matches physical camera cutout)                 │
/// │    Content opacity = 0.0                                                    │
/// │                                                                             │
/// │  At progress = 1.0:                                                         │
/// │    Visible shape = 350 × 145, full island                                  │
/// │    Appearance = dark glass + subtle stroke + drop shadow                   │
/// │    Content opacity = 1.0                                                    │
/// │                                                                             │
/// │  All intermediate values are continuous interpolations. No branching.      │
/// │                                                                             │
/// │  Hover detection: stable NSTrackingArea on IslandHostingContainer          │
/// │    → NotificationCenter → handleHoverChanged()                             │
/// │    → withAnimation(spring) { expansionProgress = target }                  │
/// │    → SwiftUI calls LiquidIslandShape.path(in:) every display frame        │
/// └─────────────────────────────────────────────────────────────────────────────┘
public struct IslandContainerView: View {
    @ObservedObject private var appState:      AppState      = AppState.shared
    @ObservedObject private var mediaManager:  MediaManager  = MediaManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: — Master expansion state

    /// The ONLY value that drives geometry and appearance.
    /// Set only via withAnimation — never naked assignment from outside.
    @State private var expansionProgress: CGFloat = 0.0

    /// Grace-period task for hover exit (prevents collapse on brief cursor overshoot).
    @State private var hoverTask: Task<Void, Never>?

    // MARK: — Fixed geometry constants

    private var metrics: ScreenMetrics { ScreenManager.shared.activeScreenMetrics() }

    private var collapsedWidth:  CGFloat { metrics.notchWidth }
    private var collapsedHeight: CGFloat { metrics.safeAreaTopInset }
    private let expandedWidth:   CGFloat = WindowManager.expandedWidth
    private let expandedHeight:  CGFloat = WindowManager.expandedHeight
    private let collapsedRadius: CGFloat = 10.0
    private let expandedRadius:  CGFloat = 22.0

    // MARK: — Shape derived from progress

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
        reduceMotion
            ? .linear(duration: 0.12)
            : .spring(response: 0.28, dampingFraction: 0.90)
    }

    // MARK: — Derived appearance values

    /// Material overlay and decoration opacity.
    /// Fades in as the island expands so the collapsed state is pure solid black.
    private var surfaceDecorationOpacity: Double {
        // Decoration starts appearing at progress 0.1, fully visible at 0.7
        let t = max(0.0, min(1.0, (Double(expansionProgress) - 0.10) / 0.60))
        return t
    }

    /// Media content opacity.
    /// Content begins revealing at 0.25, fully visible at 1.0.
    private var contentOpacity: Double {
        let t = max(0.0, min(1.0, (Double(expansionProgress) - 0.25) / 0.75))
        return t
    }

    // MARK: — Body

    public var body: some View {
        ZStack(alignment: .top) {
            backgroundSurface
            contentLayer
        }
        // Fill the entire panel canvas (always 350×145).
        // LiquidIslandShape draws the actual visible region inside this canvas.
        .frame(width: expandedWidth, height: expandedHeight)
        // ONE animation modifier drives the entire morph.
        // SwiftUI propagates the spring to LiquidIslandShape.animatableData.
        .animation(islandAnimation, value: expansionProgress)
        // Hover events from stable NSTrackingArea via NotificationCenter
        .onReceive(
            NotificationCenter.default.publisher(for: .islandHoverChanged)
        ) { note in
            guard let hovering = note.object as? Bool else { return }
            handleHoverChanged(hovering)
        }
        // HUD / media state changes (content only — geometry stays with progress)
        .onReceive(appState.$islandState) { newState in
            handleIslandStateChanged(newState)
        }
        // Tap gesture for manual expand/collapse
        .contentShape(Rectangle())
        .onTapGesture {
            handleTapGesture()
        }
    }

    // MARK: — Background Surface

    /// Single continuous surface. Never branches. Two layers always in hierarchy:
    ///   1. Solid black fill — always present, physically matches notch cutout at rest.
    ///   2. Glass material + decoration — opacity-driven by surfaceDecorationOpacity.
    @ViewBuilder
    private var backgroundSurface: some View {
        ZStack {
            // ── Layer 1: Permanent solid black ─────────────────────────────
            // At progress=0 this exactly covers the physical notch and is invisible
            // (black on black). As the island expands it transitions to visible content.
            islandShape
                .fill(Color.black)

            // ── Layer 2: Glass material + stroke + shadow ───────────────────
            // Fades in as island grows, giving depth and polish to the expanded state.
            // At progress=0 opacity=0 so the surface is pure undecorated black.
            islandShape
                .fill(.ultraThinMaterial)
                .overlay(islandShape.fill(Color.black.opacity(0.90)))
                .overlay(
                    islandShape.stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.20), .white.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
                )
                .shadow(color: .black.opacity(0.45), radius: 10, x: 0, y: 4)
                .opacity(surfaceDecorationOpacity)
        }
    }

    // MARK: — Content Layer

    /// Content is always in the hierarchy — revealed inside the expanding shape.
    /// The LiquidIslandShape clip physically masks content to the current island bounds,
    /// creating the effect of content being revealed as the surface grows.
    @ViewBuilder
    private var contentLayer: some View {
        ZStack {
            // Media content (visible when media is active)
            MediaView(state: mediaManager.currentState)
                .opacity(mediaManager.isMediaActive ? 1.0 : 0.0)

            // Hover hint (visible when no media)
            islandHoverHint
                .opacity(mediaManager.isMediaActive ? 0.0 : 1.0)
        }
        .opacity(contentOpacity)
        // Content is clipped by THE SAME LiquidIslandShape.
        // As the shape grows, more content becomes visible inside it.
        // At progress=0 the shape is collapsed-notch-size and clips all content away.
        .clipShape(islandShape)
        // No scaleEffect — geometry itself morphs, not a zoom transform.
    }

    /// Subtle hint shown when hovering with no media playing.
    @ViewBuilder
    private var islandHoverHint: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.25))
                    .frame(width: 28, height: 28)
                Image(systemName: "waveform")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.cyan)
            }
            VStack(alignment: .leading, spacing: 2) {
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
        .frame(width: expandedWidth, height: expandedHeight)
    }

    // MARK: — Hover Logic

    private func handleHoverChanged(_ hovering: Bool) {
        // Cancel any pending collapse — lets spring naturally reverse
        hoverTask?.cancel()

        if hovering {
            // Immediate response: island begins opening the instant the cursor touches
            appState.setHovered(true)
            withAnimation(islandAnimation) {
                expansionProgress = 1.0
            }
            // Update content state
            expandContentState()
        } else {
            // 175ms grace period — cursor re-entry during this window cancels collapse
            hoverTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 175_000_000) // 175 ms
                guard !Task.isCancelled else { return }
                appState.setHovered(false)
                withAnimation(islandAnimation) {
                    expansionProgress = 0.0
                }
                collapseContentState()
            }
        }
    }

    private func expandContentState() {
        if mediaManager.isMediaActive {
            appState.islandState = .mediaExpanded(mediaManager.currentState)
        } else if appState.islandState == .notchCover || appState.islandState == .compact {
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

    // MARK: — Island State Change (from HUD / MediaManager)

    private func handleIslandStateChanged(_ state: IslandState) {
        // HUD badge states (volume, brightness, battery) trigger full expansion.
        // Collapse is handled by SystemHUDController after auto-dismiss timeout.
        switch state {
        case .battery, .volume, .brightness, .expanded, .mediaExpanded:
            if !appState.isHovered {
                withAnimation(islandAnimation) { expansionProgress = 1.0 }
            }
        case .notchCover, .compact:
            if !appState.isHovered {
                withAnimation(islandAnimation) { expansionProgress = 0.0 }
            }
        case .mediaCompact:
            if !appState.isHovered {
                withAnimation(islandAnimation) { expansionProgress = 0.0 }
            }
        case .hover:
            // Hover state is driven by expansionProgress directly — no action needed
            break
        }
    }

    // MARK: — Tap Logic

    private func handleTapGesture() {
        if mediaManager.isMediaActive {
            if case .mediaExpanded = appState.islandState {
                // Tap while expanded: collapse
                appState.islandState = .mediaCompact(mediaManager.currentState)
                withAnimation(islandAnimation) { expansionProgress = 0.0 }
                appState.setHovered(false)
            } else {
                // Tap while collapsed: expand
                appState.islandState = .mediaExpanded(mediaManager.currentState)
                withAnimation(islandAnimation) { expansionProgress = 1.0 }
            }
        } else {
            if expansionProgress > 0.5 {
                appState.islandState = metrics.hasNotch ? .notchCover : .compact
                withAnimation(islandAnimation) { expansionProgress = 0.0 }
                appState.setHovered(false)
            } else {
                appState.islandState = .expanded
                withAnimation(islandAnimation) { expansionProgress = 1.0 }
            }
        }
    }
}
