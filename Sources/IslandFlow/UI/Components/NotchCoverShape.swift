import SwiftUI

public struct NotchCoverShape: Shape {
    public var isTopFlush: Bool
    public var cornerRadius: CGFloat
    
    public var animatableData: CGFloat {
        get { cornerRadius }
        set { cornerRadius = newValue }
    }
    
    public init(isTopFlush: Bool, cornerRadius: CGFloat) {
        self.isTopFlush = isTopFlush
        self.cornerRadius = cornerRadius
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(cornerRadius, min(rect.width / 2.0, rect.height / 2.0))
        
        if isTopFlush {
            // Liquid top-flush Bezier path anchored against screen top bezel
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
            
            // Continuous bottom-right curve
            path.addRelativeArc(
                center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
                radius: r,
                startAngle: .degrees(0),
                delta: .degrees(90)
            )
            
            path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
            
            // Continuous bottom-left curve
            path.addRelativeArc(
                center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
                radius: r,
                startAngle: .degrees(90),
                delta: .degrees(90)
            )
            
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.closeSubpath()
        } else {
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: r, height: r))
        }
        
        return path
    }
}
