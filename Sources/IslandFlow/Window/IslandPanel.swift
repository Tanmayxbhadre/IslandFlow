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

/// Simple NSView container for NSHostingView.
///
/// Phase 9: No longer owns a NSTrackingArea or onHoverChanged callback.
/// Hover detection is entirely managed by IslandInteractionController.
/// This view is a plain transparent pass-through container.
final class IslandHostingContainer: NSView {

    // Hit testing: pass through to subviews so SwiftUI handles taps/buttons.
    override func hitTest(_ point: NSPoint) -> NSView? {
        return super.hitTest(point)
    }

    // No tracking areas — IslandInteractionController handles all hover logic.
    override func updateTrackingAreas() {
        // Intentionally empty: no tracking areas registered.
        // IslandInteractionController uses NSEvent.addGlobalMonitorForEvents
        // + addLocalMonitorForEvents with direct NSEvent.mouseLocation checks.
    }
}
