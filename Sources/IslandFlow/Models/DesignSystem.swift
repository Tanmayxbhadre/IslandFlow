import SwiftUI

/// Unified Design System tokens for IslandFlow.
/// Enforces consistent spatial rhythm, typography hierarchy, colors, and motion physics.
public enum DesignSystem {

    // MARK: — Geometry Tokens

    public static let collapsedRadius: CGFloat = 10.0
    public static let expandedRadius:  CGFloat = 22.0
    public static let artworkRadius:   CGFloat = 10.0
    public static let buttonRadius:    CGFloat = 50.0

    public static let paddingHorizontal: CGFloat = 16.0
    public static let paddingVertical:   CGFloat = 10.0
    public static let itemSpacing:       CGFloat = 10.0

    // MARK: — Color Palette Tokens

    public static let primaryText   = Color.white
    public static let secondaryText = Color.white.opacity(0.60)
    public static let mutedText     = Color.white.opacity(0.45)

    public static let islandBackground = Color.black.opacity(0.94)

    public static let borderGradient = LinearGradient(
        colors: [.white.opacity(0.18), .white.opacity(0.03)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let accentGradient = LinearGradient(
        colors: [.cyan, .blue.opacity(0.90)],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: — Shadows

    public static let islandShadowColor  = Color.black.opacity(0.50)
    public static let islandShadowRadius: CGFloat = 14.0
    public static let islandShadowY:      CGFloat = 5.0

    // MARK: — Motion & Physics Tokens

    public static let springResponse:        Double = 0.36
    public static let springDampingFraction: Double = 0.78
}
