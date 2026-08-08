import SwiftUI

public struct NotchCoverShape: Shape {
    public var isTopFlush: Bool
    public var cornerRadius: CGFloat
    
    public init(isTopFlush: Bool, cornerRadius: CGFloat) {
        self.isTopFlush = isTopFlush
        self.cornerRadius = cornerRadius
    }
    
    public var animatableData: CGFloat {
        get { cornerRadius }
        set { cornerRadius = newValue }
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(cornerRadius, min(rect.width / 2.0, rect.height / 2.0))
        
        if isTopFlush {
            // Flat top edge against top screen bezel, smooth rounded bottom corners
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
            path.addArc(
                center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
                radius: r,
                startAngle: Angle(degrees: 0),
                endAngle: Angle(degrees: 90),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
            path.addArc(
                center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
                radius: r,
                startAngle: Angle(degrees: 90),
                endAngle: Angle(degrees: 180),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        } else {
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: r, height: r))
        }
        
        return path
    }
}
