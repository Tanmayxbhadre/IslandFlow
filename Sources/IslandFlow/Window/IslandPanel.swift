import AppKit

// MARK: — IslandPanel

/// A custom NSPanel configured for non-activating system HUD behavior.
///
/// Phase 9 changes:
///   • `acceptsMouseMovedEvents = true` — ensures the local NSEvent monitor in
///     `IslandInteractionController` fires when the cursor is over this panel.
///   • The NSTrackingArea approach from IslandHostingContainer has been removed.
///     Hover detection is now 100% handled by IslandInteractionController's
///     global+local event monitors with authoritative point-in-rect checks.
public final class IslandPanel: NSPanel {

    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: WindowConfiguration.styleMask,
            backing: .buffered,
            defer: false
        )

        self.level                       = WindowConfiguration.windowLevel
        self.collectionBehavior         = WindowConfiguration.collectionBehavior
        self.animationBehavior          = .none
        self.isOpaque                   = false
        self.backgroundColor            = .clear
        self.hasShadow                  = false  // SwiftUI renders its own shadow
        self.hidesOnDeactivate          = false
        self.ignoresMouseEvents         = false
        self.isMovableByWindowBackground = false
        self.isReleasedWhenClosed       = false
        // Required so the local NSEvent monitor in IslandInteractionController
        // fires for cursor movements over this panel.
        self.acceptsMouseMovedEvents    = true

        Logger.window.info("[IslandFlow][PANEL] IslandPanel initialized (Phase 9)")
    }

    // Prevent panel from stealing focus from the active app.
    override public var canBecomeKey:  Bool { false }
    override public var canBecomeMain: Bool { false }
}

// MARK: — IslandHostingContainer

/// Custom NSView container with precise hit testing.
/// Only the active visual island geometry intercepts mouse clicks.
/// All transparent surrounding areas (Chrome tabs, menu bar, desktop) pass clicks
/// straight through to the underlying windows and applications.
final class IslandHostingContainer: NSView {

    override func hitTest(_ point: NSPoint) -> NSView? {
        let progress = AppState.shared.expansionProgress
        let metrics = ScreenManager.shared.activeScreenMetrics()

        let collapsedWidth: CGFloat = metrics.notchWidth
        let collapsedHeight: CGFloat = metrics.safeAreaTopInset
        let expandedWidth: CGFloat = WindowManager.expandedWidth
        let expandedHeight: CGFloat = WindowManager.expandedHeight

        // Interpolate current active width and height based on expansionProgress
        let currentWidth = collapsedWidth + (expandedWidth - collapsedWidth) * progress
        let currentHeight = collapsedHeight + (expandedHeight - collapsedHeight) * progress

        // Island is anchored to the top-center of container view (AppKit Y=0 is bottom)
        let containerWidth = bounds.width
        let minX = (containerWidth - currentWidth) / 2.0
        let minY = bounds.height - currentHeight

        let activeIslandRect = NSRect(x: minX, y: minY, width: currentWidth, height: currentHeight)

        // Add 4pt spatial tolerance padding for comfortable control clicking
        let paddedActiveRect = activeIslandRect.insetBy(dx: -4.0, dy: -4.0)

        if paddedActiveRect.contains(point) {
            let hitView = super.hitTest(point)
            if HoverSettings.shared.debugHoverState {
                Logger.window.debug("[HitTest] mouse=\(Int(point.x)),\(Int(point.y)) inside=true result=\(hitView?.description ?? "self")")
            }
            return hitView
        }

        if HoverSettings.shared.debugHoverState {
            Logger.window.debug("[HitTest] mouse=\(Int(point.x)),\(Int(point.y)) inside=false result=PASS_THROUGH")
        }

        // Return nil so AppKit passes clicks straight through to Chrome, Finder, Menu Bar, etc.
        return nil
    }

    override func updateTrackingAreas() {
        // Intentionally empty: no tracking areas registered.
        // Hover detection is managed by IslandInteractionController.
    }
}
