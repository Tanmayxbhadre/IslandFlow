import SwiftUI
import Combine

/// IslandContainerView — the entire island rendered inside the stationary NSPanel canvas.
///
/// ┌─────────────────────────────────────────────────────────────────────────────┐
/// │  PHASE 9 INTERACTION MODEL                                                  │
/// │                                                                             │
/// │  ONE source of truth for geometry: IslandInteractionController.state        │
/// │                                                                             │
/// │  .opening  → withAnimation { expansionProgress = 1.0 }                     │
/// │  .closing  → withAnimation { expansionProgress = 0.0 }                     │
/// │  .collapsed→ (already at 0.0, no action)                                    │
/// │  .expanded → (already at 1.0, no action)                                   │
/// │                                                                             │
/// │  NO other component can collapse this view:                                 │
/// │    • Volume change     → does NOT collapse                                  │
/// │    • Brightness change → does NOT collapse                                  │
/// │    • Track change      → does NOT collapse                                  │
/// │    • Space switch      → does NOT collapse                                  │
/// │    • Battery update    → does NOT collapse                                  │
/// │                                                                             │
/// │  Only VERIFIED_MOUSE_EXIT from IslandInteractionController collapses.       │
/// │                                                                             │
/// │  Content state (.islandState) changes are accepted without geometry effect: │
/// │    MediaView content updates immediately when islandState changes.          │
/// │    Geometry (expansionProgress) only changes from interactionState.         │
/// │                                                                             │
/// │  Panel coordinate system:                                                   │
/// │    y = 0..collapsedHeight (32pt) → NOTCH SAFE ZONE (no content here)       │
/// │    y = collapsedHeight..expandedHeight → CONTENT ZONE (113pt)              │
/// └─────────────────────────────────────────────────────────────────────────────┘
public struct IslandContainerView: View {
    @ObservedObject private var appState:              AppState                    = AppState.shared
    @ObservedObject private var mediaManager:          MediaManager                = MediaManager.shared
    @ObservedObject private var interactionController: IslandInteractionController = IslandInteractionController.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: — Master expansion state

    /// The ONLY value that drives geometry and appearance.
    /// Changed ONLY by handleInteractionStateChanged(). Never by HUD/media.
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

    /// Single spring — matches LiquidIslandShape.animatableData interpolation.
    private var islandAnimation: Animation {
        reduceMotion
            ? .linear(duration: 0.12)
            : .spring(response: 0.28, dampingFraction: 0.92)
    }

    // MARK: — Derived appearance

    /// Glass + stroke + shadow fade in from p=0.35, complete at p=0.90.
    /// At p<0.35, island is pure black (notch-stretching feel).
    private var surfaceDecorationOpacity: Double {
        max(0, min(1, (Double(expansionProgress) - 0.35) / 0.55))
    }

    /// Content fades in from p=0.45, complete at p=0.75.
    /// Ensures content only appears when island is wide enough (~246pt) to avoid
    /// horizontal clipping of left-aligned artwork.
    private var contentOpacity: Double {
        max(0, min(1, (Double(expansionProgress) - 0.45) / 0.30))
    }

    // MARK: — Body

    public var body: some View {
        ZStack(alignment: .top) {
            backgroundSurface
            contentLayer
        }
        .frame(width: expandedWidth, height: expandedHeight)
        // ONE spring animation for all geometry and appearance.
        .animation(islandAnimation, value: expansionProgress)
        // ── Interaction state subscriber ──────────────────────────────────
        // ONLY source of geometry (expansionProgress) changes.
        .onReceive(interactionController.$state) { newState in
            handleInteractionStateChanged(newState)
        }
        // ── Content state subscriber ──────────────────────────────────────
        // Updates content display (MediaView, HUD views) WITHOUT affecting geometry.
        .onReceive(appState.$islandState) { newState in
            handleContentStateChanged(newState)
        }
        // Tap: manual expand/collapse (content area clicks)
        .contentShape(Rectangle())
        .onTapGesture { handleTapGesture() }
    }

    // MARK: — Background Surface

    @ViewBuilder
    private var backgroundSurface: some View {
        ZStack {
            // ── Solid black (always present) ─────────────────────────────
            // At p=0 covers exactly the physical notch. Grows as island opens.
            // This is the "notch stretching" effect — pure black, no decoration.
            islandShape
                .fill(Color.black)

            // ── Glass decoration (fades in at p≥0.35) ────────────────────
            // Appears after the black surface has already grown significantly,
            // so the first ~35% of expansion feels like the notch itself moving.
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

    /// Layout:
    ///   VStack {
    ///     Color.clear (height=32pt = notch safe zone)
    ///     ZStack { MediaView / islandHoverHint } (height=113pt = content zone)
    ///   }
    ///
    /// The LiquidIslandShape clip progressively reveals content as height grows.
    /// At p=0: island bottom edge = y=32, so ALL content (starting at y=32)
    ///   is exactly at the clip boundary — nothing visible yet.
    /// At p=0.5: island bottom ≈ y=88 — top 56pt of content zone revealed.
    /// At p=1.0: island fills full canvas — all 113pt of content revealed.
    @ViewBuilder
    private var contentLayer: some View {
        VStack(spacing: 0) {
            // NOTCH SAFE ZONE: content never enters y=0..collapsedHeight.
            // Geometry-derived: collapsedHeight = safeAreaTopInset = 32pt.
            Color.clear.frame(height: collapsedHeight)

            // CONTENT ZONE: all media/hint content lives below the notch.
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

    // MARK: — Interaction State Handler (GEOMETRY AUTHORITY)

    /// The ONLY method that changes expansionProgress.
    /// Called by IslandInteractionController state changes (hover in/out).
    private func handleInteractionStateChanged(
        _ newState: IslandInteractionController.InteractionState
    ) {
        switch newState {
        case .opening:
            // Cursor entered — expand immediately.
            appState.setHovered(true)
            expandContentState()
            withAnimation(islandAnimation) {
                expansionProgress = 1.0
            }
            Logger.window.info("[Island] geometry: expanding progress=1.0")

        case .closing, .collapsed:
            // Cursor exited (with grace period verified).
            appState.setHovered(false)
            collapseContentState()
            withAnimation(islandAnimation) {
                expansionProgress = 0.0
            }
            Logger.window.info("[Island] geometry: collapsing progress=0.0 reason=VERIFIED_MOUSE_EXIT")

        case .expanded:
            // Already fully open — no geometry change needed.
            break
        }
    }

    // MARK: — Content State Handler (CONTENT ONLY — NO GEOMETRY)

    /// Handles islandState changes from SystemHUDController and MediaManager.
    ///
    /// IMPORTANT: This method NEVER changes expansionProgress.
    /// Content can change (new song, volume indicator) without affecting geometry.
    /// The island opens/closes ONLY based on cursor position via IslandInteractionController.
    private func handleContentStateChanged(_ state: IslandState) {
        // No geometry action. The content (MediaView/HUD views) reads from
        // appState.islandState and mediaManager.currentState reactively.
        // All we do here is ensure the content selection is coherent.
        //
        // Logging for debug: if a collapse request slips through (should never happen):
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
        // Tap does not change expansionProgress — hover state is authoritative.
    }
}
