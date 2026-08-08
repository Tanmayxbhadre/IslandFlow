import AppKit

/// A custom NSPanel configured for non-activating system HUD behavior.
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
        
        // Key floating HUD settings:
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false // SwiftUI handles subtle outer glow/shadow
        self.hidesOnDeactivate = false
        self.ignoresMouseEvents = false
        self.isMovableByWindowBackground = false
        self.isReleasedWhenClosed = false
        
        Logger.window.info("IslandPanel initialized successfully")
    }
    
    // Prevent panel from taking active focus away from current app (VS Code, browser, terminal, etc.)
    override public var canBecomeKey: Bool { false }
    override public var canBecomeMain: Bool { false }
}
