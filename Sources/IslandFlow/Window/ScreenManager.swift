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
    
    private var cachedNotchMetrics: ScreenMetrics?
    
    private init() {}
    
    public func invalidateCache() {
        cachedNotchMetrics = nil
    }
    
    public func activeScreenMetrics() -> ScreenMetrics {
        if let cached = cachedNotchMetrics {
            return cached
        }
        
        let metrics = computeScreenMetrics()
        cachedNotchMetrics = metrics
        return metrics
    }
    
    private func computeScreenMetrics() -> ScreenMetrics {
        // Prefer the built-in notched display as the authoritative anchor for IslandFlow.
        let screen: NSScreen
        if #available(macOS 12.0, *), let notchScreen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) {
            screen = notchScreen
        } else {
            let mouseLocation = NSEvent.mouseLocation
            screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
                ?? NSScreen.main
                ?? NSScreen.screens[0]
        }
            
        let safeAreaTop: CGFloat
        if #available(macOS 12.0, *) {
            safeAreaTop = screen.safeAreaInsets.top
        } else {
            safeAreaTop = 0
        }
        
        let hasNotch = safeAreaTop > 0
        var computedNotchWidth: CGFloat = (safeAreaTop > 36.0) ? 180.0 : 160.0
        
        if #available(macOS 12.0, *) {
            if let topLeft = screen.auxiliaryTopLeftArea, let topRight = screen.auxiliaryTopRightArea {
                let centerGap = screen.frame.width - (topLeft.width + topRight.width)
                if centerGap > 0 {
                    // centerGap includes left and right menu item safety paddings (~9pt per side).
                    // The physical plastic notch cutout width is centerGap - 18.0.
                    computedNotchWidth = max(centerGap - 18.0, 160.0)
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
