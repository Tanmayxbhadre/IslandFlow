import AppKit

public struct ScreenMetrics {
    public let targetScreen: NSScreen
    public let screenFrame: NSRect
    public let visibleFrame: NSRect
    public let safeAreaTopInset: CGFloat
    public let hasNotch: Bool
    public let notchWidth: CGFloat
    
    /// Top center point aligned flush with top edge of screen for notch-docked states
    public var topFlushPoint: CGPoint {
        let x = screenFrame.origin.x + (screenFrame.width / 2.0)
        let y = screenFrame.origin.y + screenFrame.height
        return CGPoint(x: x, y: y)
    }
    
    /// Top center point positioned slightly below menu bar for floating states on non-notch screens
    public var topFloatingPoint: CGPoint {
        let x = screenFrame.origin.x + (screenFrame.width / 2.0)
        let y = screenFrame.origin.y + screenFrame.height - (screenFrame.height - visibleFrame.maxY) - 4.0
        return CGPoint(x: x, y: y)
    }
}

public final class ScreenManager {
    public static let shared = ScreenManager()
    
    private init() {}
    
    public func activeScreenMetrics() -> ScreenMetrics {
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
        var computedNotchWidth: CGFloat = (safeAreaTop > 36.0) ? 200.0 : 173.0
        
        if #available(macOS 12.0, *) {
            if let topLeft = screen.auxiliaryTopLeftArea, let topRight = screen.auxiliaryTopRightArea {
                let centerGap = screen.frame.width - (topLeft.width + topRight.width)
                if centerGap > 0 {
                    computedNotchWidth = centerGap
                }
            }
        }
        
        Logger.screen.debug("Active screen: \(screen.localizedName), Notch: \(hasNotch), SafeTop: \(safeAreaTop), NotchWidth: \(computedNotchWidth)")
        
        return ScreenMetrics(
            targetScreen: screen,
            screenFrame: screen.frame,
            visibleFrame: screen.visibleFrame,
            safeAreaTopInset: safeAreaTop,
            hasNotch: hasNotch,
            notchWidth: computedNotchWidth
        )
    }
}
