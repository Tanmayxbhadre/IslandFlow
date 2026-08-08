import SwiftUI
import AppKit

@main
struct IslandFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // No main window since this is a pure menu-bar floating HUD utility
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run application as background accessory (no Dock icon, no main window steal)
        NSApp.setActivationPolicy(.accessory)
        
        // Create menu bar item
        setupStatusItem()
        
        // Initialize island floating panel
        Task { @MainActor in
            WindowManager.shared.setupWindow()
        }
        
        Logger.app.info("IslandFlow launched successfully")
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "drop.fill", accessibilityDescription: "IslandFlow")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "IslandFlow", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        let toggleStateItem = NSMenuItem(title: "Toggle Expand / Collapse", action: #selector(toggleIslandState), keyEquivalent: "e")
        toggleStateItem.target = self
        menu.addItem(toggleStateItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit IslandFlow", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func toggleIslandState() {
        Task { @MainActor in
            AppState.shared.toggleState()
        }
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
