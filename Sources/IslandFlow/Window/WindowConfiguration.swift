import AppKit

public struct WindowConfiguration {
    /// Window style mask configured for borderless non-activating floating panel.
    public static let styleMask: NSWindow.StyleMask = [
        .borderless,
        .nonactivatingPanel
    ]
    
    /// Panel level positioned slightly above main menu to float over regular app windows.
    public static let windowLevel: NSWindow.Level = .mainMenu + 1
    
    /// Behaviors ensuring panel persists across spaces, native full-screen apps, and window cycles.
    public static let collectionBehavior: NSWindow.CollectionBehavior = [
        .canJoinAllSpaces,
        .fullScreenAuxiliary,
        .stationary,
        .ignoresCycle
    ]
}
