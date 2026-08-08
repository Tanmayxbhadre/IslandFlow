import AppKit

public struct ScreenMetrics {
    public let targetScreen: NSScreen
    public let screenFrame: NSRect
    public let visibleFrame: NSRect
    public let safeAreaTopInset: CGFloat
    public let hasNotch: Bool
    
    public var topCenterPoint: CGPoint {
        let x = screenFrame.origin.x + (screenFrame.width / 2.0)
        let y: CGFloat
        if hasNotch {
            // Align with top screen bounds when notch exists
            y = screenFrame.origin.y + screenFrame.height - safeAreaTopInset / 2.0
        } else {
            // Position slightly below menu bar on non-notch displays
            y = screenFrame.origin.y + screenFrame.height - (screenFrame.height - visibleFrame.maxY) - 8.0
        }
        return CGPoint(x: x, y: y)
    }
}

public final class ScreenManager {
    public static let shared = ScreenManager()
    
    private init() {}
    
    public func activeScreenMetrics() -> ScreenMetrics {
        // Find screen containing mouse cursor, or default to main screen
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens[0]
            
        let safeAreaTop: CGFloat
        if #available(macOS 12.0, *) {
            safeAreaTop = screen.safeAreaInsets.top
        } else {
            safeAreaTop = 0
        }
        
        let hasNotch = safeAreaTop > 0
        
        Logger.screen.debug("Active screen: \(screen.localizedName), Notch: \(hasNotch), SafeTop: \(safeAreaTop)")
        
        return ScreenMetrics(
            targetScreen: screen,
            screenFrame: screen.frame,
            visibleFrame: screen.visibleFrame,
            safeAreaTopInset: safeAreaTop,
            hasNotch: hasNotch
        )
    }
}
