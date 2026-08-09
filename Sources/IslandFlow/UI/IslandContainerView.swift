import SwiftUI
import Combine

/// IslandContainerView — the entire island rendered inside the stationary NSPanel canvas.
///
/// ┌─────────────────────────────────────────────────────────────────────────────┐
/// │  PHASE 8 COORDINATE SYSTEM                                                  │
/// │                                                                             │
/// │  NSPanel: always 350 × 145 pt, top edge flush with screen bezel.           │
/// │                                                                             │
/// │  SwiftUI y-axis (top-down):                                                 │
/// │    y = 0              → physical screen top = notch camera housing top     │
/// │    y = collapsedHeight → bottom of notch (safeAreaTopInset = 32 pt)       │
/// │    y = expandedHeight  → bottom of expanded island (145 pt)               │
/// │                                                                             │
/// │  NOTCH SAFE ZONE: y = 0 → collapsedHeight (32 pt)                         │
/// │    The black surface exists here (matches camera cutout).                  │
/// │    Content NEVER enters this zone — text/artwork are physically            │
/// │    behind the camera module and would be invisible.                        │
/// │                                                                             │
/// │  CONTENT ZONE: y = collapsedHeight → expandedHeight                       │
/// │    113 pt of usable content space below the notch.                         │
/// │    All media elements (artwork, title, progress, controls) live here.      │
/// │                                                                             │
/// │  ONE master value drives ALL geometry:                                      │
/// │    expansionProgress: CGFloat  (0.0 = notch, 1.0 = full island)           │
/// │                                                                             │
/// │  Phase 8 animation timeline:                                                │
/// │    0.00 – 0.35  Pure black surface expands (notch growing)                 │
/// │    0.35 – 0.90  Glass/decoration fades in                                  │
/// │    0.45 – 0.75  Content fades in (island wide enough to show it)           │
/// └─────────────────────────────────────────────────────────────────────────────┘
public struct IslandContainerView: View {
    @ObservedObject private var appState:     AppState     = AppState.shared
    @ObservedObject private var mediaManager: MediaManager = MediaManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: — Master expansion state

    /// The ONLY value that drives geometry and appearance.
    /// Set only via withAnimation — never naked assignment from outside.
    @State private var expansionProgress: CGFloat = 0.0

    /// Grace-period task for hover exit (prevents collapse on brief cursor overshoot).
    @State private var hoverTask: Task<Void, Never>?

    // MARK: — Fixed geometry constants (snapshot at init; refreshed only on screen change)

    private var metrics: ScreenMetrics { ScreenManager.shared.activeScreenMetrics() }

    /// Width of the physical notch = collapsed island width.
    private var collapsedWidth:  CGFloat { metrics.notchWidth }
    /// Height of the physical notch = collapsed island height = notch safe zone size.
    private var collapsedHeight: CGFloat { metrics.safeAreaTopInset }
    /// Full island width = panel width (stationary).
    private let expandedWidth:   CGFloat = WindowManager.expandedWidth
    /// Full island height = panel height (stationary).
    private let expandedHeight:  CGFloat = WindowManager.expandedHeight
    /// Bottom corner radius at collapsed state (matches physical notch curve).
    private let collapsedRadius: CGFloat = 10.0
    /// Bottom corner radius at fully expanded state.
    private let expandedRadius:  CGFloat = 22.0

    /// Usable content height below the notch safe zone.
    /// contentTop is always at y = collapsedHeight in SwiftUI panel space.
    private var contentHeight: CGFloat { expandedHeight - collapsedHeight }

    // MARK: — Shape (re-created each render from current progress)

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

    /// Single spring drives all geometry. Matches LiquidIslandShape.animatableData interpolation.
    /// Response 0.28s + dampingFraction 0.92 = fast initial, smooth, almost no bounce.
    private var islandAnimation: Animation {
        reduceMotion
            ? .linear(duration: 0.12)
            : .spring(response: 0.28, dampingFraction: 0.92)
    }

    // MARK: — Derived appearance values (all from expansionProgress)

    /// Glass material + stroke + shadow opacity.
    /// Delayed to 0.35 so the island grows as pure black first (notch stretching feel).
    /// Fully opaque at 0.90 so decoration is complete before island fully opens.
    private var surfaceDecorationOpacity: Double {
        let t = max(0.0, min(1.0, (Double(expansionProgress) - 0.35) / 0.55))
        return t
    }

    /// Media content opacity.
    /// Delayed to 0.45 so content only appears when the island is wide enough
    /// (island width at p=0.45 ≈ 246pt) to not clip the content awkwardly.
    /// Fully opaque at 0.75.
    private var contentOpacity: Double {
        let t = max(0.0, min(1.0, (Double(expansionProgress) - 0.45) / 0.30))
        return t
    }

    // MARK: — Body

    public var body: some View {
        ZStack(alignment: .top) {
            backgroundSurface
            contentLayer
        }
        // Fill the entire stationary panel canvas.
        // LiquidIslandShape draws the actual visible island within this canvas.
        .frame(width: expandedWidth, height: expandedHeight)
        // ONE animation modifier. SwiftUI propagates spring to LiquidIslandShape.animatableData.
        .animation(islandAnimation, value: expansionProgress)
        // Hover events — from stable NSTrackingArea via NotificationCenter
        .onReceive(
            NotificationCenter.default.publisher(for: .islandHoverChanged)
        ) { note in
            guard let hovering = note.object as? Bool else { return }
            handleHoverChanged(hovering)
        }
        // HUD / media state — content selection only, never geometry
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

    /// Single continuous surface — no if/else branching.
    ///
    /// Layer 1 (always): solid black exactly matching physical notch at rest.
    /// Layer 2 (opacity): glass + stroke + shadow that fades in as island grows.
    @ViewBuilder
    private var backgroundSurface: some View {
        ZStack {
            // ── Permanent solid black ────────────────────────────────────────
            // At p=0 covers notch exactly. As p→1 grows to full island.
            // This layer is ALWAYS there — it IS the notch at rest.
            islandShape
                .fill(Color.black)

            // ── Glass / decoration layer ─────────────────────────────────────
            // Fades in from p=0.35 → p=0.90 so first 35% of expansion is
            // pure black (looks like the notch physically stretching).
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

    /// Content zone layout:
    ///
    ///  ┌─────────────── Panel (350 × 145 pt) ───────────────┐
    ///  │░░░░░░░░░░░░ NOTCH SAFE ZONE (0→32 pt) ░░░░░░░░░░░░│  ← black surface only
    ///  │  ┌──────────── CONTENT ZONE (32→145 pt) ──────────┐│
    ///  │  │  artwork | title | artist                       ││
    ///  │  │  ──────────────────────── progress bar         ││
    ///  │  │            ◄  ▶  ►                             ││
    ///  │  └────────────────────────────────────────────────┘│
    ///  └───────────────────────────────────────────────────-┘
    ///
    /// Key: content starts at y = collapsedHeight (safeAreaTopInset = 32 pt).
    /// The LiquidIslandShape clip reveals content naturally as height grows.
    /// Content NEVER enters y = 0..collapsedHeight (physical camera zone).
    @ViewBuilder
    private var contentLayer: some View {
        VStack(spacing: 0) {
            // ── Notch safe zone spacer ─────────────────────────────────────
            // This transparent block keeps all content BELOW the physical notch.
            // Value = safeAreaTopInset (32pt on 14" MBP). Geometry-derived, never guessed.
            Color.clear
                .frame(height: collapsedHeight)

            // ── Content zone ────────────────────────────────────────────────
            // Constrained to the content area below the notch.
            ZStack {
                // Media content (active when music playing)
                MediaView(state: mediaManager.currentState)
                    .opacity(mediaManager.isMediaActive ? 1.0 : 0.0)

                // No-media hint (active when no music)
                islandHoverHint
                    .opacity(mediaManager.isMediaActive ? 0.0 : 1.0)
            }
            .frame(width: expandedWidth, height: contentHeight)
        }
        .frame(width: expandedWidth, height: expandedHeight, alignment: .top)
        // Fade in only when island is wide enough (p≈0.45) to show content without clipping.
        .opacity(contentOpacity)
        // Clip content by the SAME island shape.
        // As height grows past y=32, content is progressively revealed bottom-up... wait,
        // the shape grows DOWNWARD, so content at y=32 appears first, then content
        // deeper in (y=50, y=80, y=100) appears as height increases.
        .clipShape(islandShape)
    }

    /// No-media hover hint content.
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

    // MARK: — Hover Logic

    private func handleHoverChanged(_ hovering: Bool) {
        // Cancel pending collapse — spring reverses from current position naturally.
        hoverTask?.cancel()

        if hovering {
            // Immediate: no delay before opening begins.
            appState.setHovered(true)
            expandContentState()
            withAnimation(islandAnimation) {
                expansionProgress = 1.0
            }

            // Debug geometry log (first hover only)
            let p = expansionProgress
            Logger.window.debug("""
                [Phase8] hoverEnter progress=\(p) \
                notchH=\(collapsedHeight) panelH=\(expandedHeight) \
                contentTop=\(collapsedHeight) contentH=\(contentHeight)
                """)
        } else {
            // 175ms grace period — re-entry cancels the collapse.
            hoverTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 175_000_000) // 175 ms
                guard !Task.isCancelled else { return }
                appState.setHovered(false)
                collapseContentState()
                withAnimation(islandAnimation) {
                    expansionProgress = 0.0
                }
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

    // MARK: — Island State Change (HUD / MediaManager)

    private func handleIslandStateChanged(_ state: IslandState) {
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
            break
        }
    }

    // MARK: — Tap Logic

    private func handleTapGesture() {
        if mediaManager.isMediaActive {
            if case .mediaExpanded = appState.islandState {
                appState.islandState = .mediaCompact(mediaManager.currentState)
                withAnimation(islandAnimation) { expansionProgress = 0.0 }
                appState.setHovered(false)
            } else {
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
