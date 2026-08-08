import SwiftUI
import CoreGraphics

/// FluidIslandShape — the single continuous surface for all IslandFlow states.
/// 
/// The shape is always: flat top edge (anchored to screen bezel) + smoothly rounded bottom corners.
/// Three animatable parameters drive the entire morph:
///   - cornerRadius: 0→14→24 depending on state
///   - The bounding rect comes from .frame() in the parent view, which SwiftUI animates via animatableData
///
/// This shape is used for:
///   1. The background fill (black / material)
///   2. The clipShape on all content (content is physically clipped as the island contracts)
public struct FluidIslandShape: Shape {
    /// When true, the top edge is flat (flush against screen bezel).
    /// When false, all four corners are rounded (external display / non-notch mode).
    public var topFlush: Bool
    /// The bottom corner radius. Animatable.
    public var cornerRadius: CGFloat
    
    public var animatableData: CGFloat {
        get { cornerRadius }
        set { cornerRadius = newValue }
    }
    
    public init(topFlush: Bool, cornerRadius: CGFloat) {
        self.topFlush = topFlush
        self.cornerRadius = cornerRadius
    }
    
    public func path(in rect: CGRect) -> Path {
        // Clamp radius so it never exceeds the half-dimensions
        let r = min(cornerRadius, rect.height / 2.0, rect.width / 2.0)
        
        var path = Path()
        
        if topFlush {
            // Flat top — anchored to screen bezel.
            // Only the bottom two corners are rounded.
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            // Right side down to bottom-right arc start
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
            // Bottom-right corner arc
            path.addArc(
                center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
                radius: r,
                startAngle: .radians(0),
                endAngle: .radians(.pi / 2),
                clockwise: false
            )
            // Bottom edge left to bottom-left arc start
            path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
            // Bottom-left corner arc
            path.addArc(
                center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
                radius: r,
                startAngle: .radians(.pi / 2),
                endAngle: .radians(.pi),
                clockwise: false
            )
            // Left side back to top-left
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        } else {
            // External display — all four corners rounded symmetrically
            path.addRoundedRect(
                in: rect,
                cornerSize: CGSize(width: r, height: r),
                style: .continuous
            )
        }
        
        return path
    }
}
