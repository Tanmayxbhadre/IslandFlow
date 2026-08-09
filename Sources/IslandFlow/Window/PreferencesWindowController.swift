import AppKit
import SwiftUI

@MainActor
public final class PreferencesWindowController: NSObject, NSWindowDelegate {
    public static let shared = PreferencesWindowController()

    private var window: NSWindow?

    private override init() {
        super.init()
    }

    public func showWindow() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let preferencesView = PreferencesView()
        let hostingController = NSHostingController(rootView: preferencesView)

        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "IslandFlow Preferences"
        newWindow.styleMask = [.titled, .closable, .miniaturizable]
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        newWindow.center()

        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func windowWillClose(_ notification: Notification) {
        // Retain window reference for fast re-opening
    }
}
