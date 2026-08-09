import SwiftUI
import CoreGraphics

/// LiquidIslandShape — the ONE shape that represents every island state.
///
/// Architecture:
///   • The shape lives inside a canvas that is always `expandedWidth × expandedHeight`.
///   • At progress = 0.0 it draws the collapsed notch geometry, centered horizontally and
///     anchored to the top (y = 0 in SwiftUI's coordinate space = physical screen bezel).
///   • At progress = 1.0 it fills the full expanded island bounds.
///   • Every intermediate value produces a continuously interpolated shape — there is NO
///     moment where two shapes coexist or one replaces the other.
///
/// Top edge invariant:
///   `minY` of the drawn rect is ALWAYS `rect.minY` (= 0), regardless of progress.
///   Width expands symmetrically left and right.
///   Height grows downward only.
///
/// The `animatableData` is `progress` alone — SwiftUI calls `path(in:)` on every
/// display frame of the spring animation, producing frame-perfect liquid morphing.
public struct LiquidIslandShape: Shape {

    // MARK: — Animatable

    /// Master progress: 0.0 = collapsed notch, 1.0 = fully expanded.
    public var progress: CGFloat

    public var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    // MARK: — Fixed geometry constants (set at init, never change during animation)

    public let collapsedWidth:  CGFloat
    public let collapsedHeight: CGFloat
    public let expandedWidth:   CGFloat
    public let expandedHeight:  CGFloat
    public let collapsedRadius: CGFloat
    public let expandedRadius:  CGFloat

    // MARK: — Init

    public init(
        progress:        CGFloat,
        collapsedWidth:  CGFloat,
        collapsedHeight: CGFloat,
        expandedWidth:   CGFloat,
        expandedHeight:  CGFloat,
        collapsedRadius: CGFloat = 10.0,
        expandedRadius:  CGFloat = 22.0
    ) {
        self.progress        = progress
        self.collapsedWidth  = collapsedWidth
        self.collapsedHeight = collapsedHeight
        self.expandedWidth   = expandedWidth
        self.expandedHeight  = expandedHeight
        self.collapsedRadius = collapsedRadius
        self.expandedRadius  = expandedRadius
    }

    // MARK: — Path

    public func path(in rect: CGRect) -> Path {
        let p = max(0.0, min(1.0, progress))

        // ── Interpolated dimensions ──────────────────────────────────────────
        let w = collapsedWidth  + (expandedWidth  - collapsedWidth)  * p
        let h = collapsedHeight + (expandedHeight - collapsedHeight) * p
        let r = min(
            collapsedRadius + (expandedRadius - collapsedRadius) * p,
            h / 2.0,
            w / 2.0
        )

        // ── Geometry anchored at top-center of host rect ─────────────────────
        // minX expands symmetrically; minY is LOCKED to rect.minY (screen top).
        let xInset = (rect.width  - w) / 2.0
        let minX   = rect.minX + xInset
        let maxX   = minX + w
        let minY   = rect.minY          // ← INVARIANT: never moves
        let maxY   = minY + h           // ← grows downward

        // Debug assertion (disabled in release)
        assert(abs(minY - rect.minY) < 0.001, "LiquidIslandShape: top edge drifted!")

        // ── Path: flat top + rounded bottom corners ─────────────────────────
        var path = Path()

        // Top-left → top-right (flat, flush with screen bezel)
        path.move(to:    CGPoint(x: minX, y: minY))
        path.addLine(to: CGPoint(x: maxX, y: minY))

        // Right side ↓ to bottom-right arc start
        path.addLine(to: CGPoint(x: maxX, y: maxY - r))

        // Bottom-right corner arc (0° → 90°, clockwise = false in SwiftUI's flipped space)
        path.addArc(
            center:     CGPoint(x: maxX - r, y: maxY - r),
            radius:     r,
            startAngle: .radians(0),
            endAngle:   .radians(.pi / 2),
            clockwise:  false
        )

        // Bottom edge ← to bottom-left arc start
        path.addLine(to: CGPoint(x: minX + r, y: maxY))

        // Bottom-left corner arc (90° → 180°)
        path.addArc(
            center:     CGPoint(x: minX + r, y: maxY - r),
            radius:     r,
            startAngle: .radians(.pi / 2),
            endAngle:   .radians(.pi),
            clockwise:  false
        )

        // Left side ↑ back to top-left
        path.addLine(to: CGPoint(x: minX, y: minY))
        path.closeSubpath()

        return path
    }
}
