import AppKit

// MARK: — Notification Names

extension Notification.Name {
    /// Posted when hover state changes. `object` is a `Bool` (true = entered, false = exited).
    static let islandHoverChanged = Notification.Name("com.islandflow.hoverChanged")
}

// MARK: — IslandPanel

/// A custom NSPanel configured for non-activating system HUD behavior.
/// The panel is permanently sized to the maximum expanded island dimensions.
/// All visible morphing happens within SwiftUI — the panel frame never changes during interaction.
public final class IslandPanel: NSPanel {

    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: WindowConfiguration.styleMask,
            backing: .buffered,
            defer: false
        )

        self.level = WindowConfiguration.windowLevel
        self.collectionBehavior = WindowConfiguration.collectionBehavior
        self.animationBehavior = .none
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false          // SwiftUI renders its own drop shadow
        self.hidesOnDeactivate = false
        self.ignoresMouseEvents = false
        self.isMovableByWindowBackground = false
        self.isReleasedWhenClosed = false

        Logger.window.info("[IslandFlow][PANEL CREATE] IslandPanel initialized")
    }

    // Prevent panel from stealing focus from the active app.
    override public var canBecomeKey:  Bool { false }
    override public var canBecomeMain: Bool { false }
}

// MARK: — IslandHostingContainer

/// An intermediate NSView that wraps the NSHostingView and owns the stable
/// NSTrackingArea for hover detection.
///
/// Why a wrapper view instead of SwiftUI `.onHover`?
/// SwiftUI's `.onHover` attaches a tracking area to the view's current bounds.
/// Because the NSHostingView always fills the (large, stationary) panel, the
/// SwiftUI hover zone would cover the entire 350×145pt panel area at all times.
/// This wrapper lets us update the tracking rect independently of SwiftUI layout.
///
/// The hover zone is the full panel bounds. Since the panel sits at the very top
/// of the screen (above all menu bar items) and only the center portion is visible
/// as the island, entering this zone reliably indicates cursor intent on the island.
final class IslandHostingContainer: NSView {

    /// Called whenever the cursor enters or exits the tracking zone.
    /// `true` = entered (hover start), `false` = exited (hover end).
    var onHoverChanged: ((Bool) -> Void)?

    // MARK: — Tracking area

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        // Remove all existing tracking areas before adding the updated one.
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        // Track the full view bounds — the panel is already sized to the maximum
        // island dimensions, so this covers exactly the interaction region.
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    // MARK: — Mouse events

    override func mouseEntered(with event: NSEvent) {
        onHoverChanged?(true)
    }

    override func mouseExited(with event: NSEvent) {
        onHoverChanged?(false)
    }

    // MARK: — Hit testing

    /// Pass hit testing through to subviews (NSHostingView handles SwiftUI taps/clicks).
    override func hitTest(_ point: NSPoint) -> NSView? {
        return super.hitTest(point)
    }
}
