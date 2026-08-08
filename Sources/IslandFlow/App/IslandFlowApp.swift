import SwiftUI
import AppKit

@main
struct IslandFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        
        Task { @MainActor in
            WindowManager.shared.setupWindow()
            _ = SystemHUDController.shared
            _ = MediaManager.shared
        }
        
        Logger.app.info("IslandFlow Phase 3.1 launched successfully")
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
        
        #if DEBUG
        menu.addItem(NSMenuItem.separator())
        
        let simMenuItem = NSMenuItem(title: "Simulate HUD & Media Events", action: nil, keyEquivalent: "")
        let simMenu = NSMenu()
        
        let simVolItem = NSMenuItem(title: "Volume (72%)", action: #selector(simVolume), keyEquivalent: "")
        simVolItem.target = self
        simMenu.addItem(simVolItem)
        
        let simMuteItem = NSMenuItem(title: "Muted", action: #selector(simMute), keyEquivalent: "")
        simMuteItem.target = self
        simMenu.addItem(simMuteItem)
        
        let simBrightItem = NSMenuItem(title: "Brightness (65%)", action: #selector(simBrightness), keyEquivalent: "")
        simBrightItem.target = self
        simMenu.addItem(simBrightItem)
        
        let simChargeItem = NSMenuItem(title: "Charging (85%)", action: #selector(simCharging), keyEquivalent: "")
        simChargeItem.target = self
        simMenu.addItem(simChargeItem)
        
        let simLowBatItem = NSMenuItem(title: "Low Battery (15%)", action: #selector(simLowBattery), keyEquivalent: "")
        simLowBatItem.target = self
        simMenu.addItem(simLowBatItem)
        
        simMenu.addItem(NSMenuItem.separator())
        
        let simMediaPlay = NSMenuItem(title: "Simulate Media Playing", action: #selector(simMediaPlayAction), keyEquivalent: "")
        simMediaPlay.target = self
        simMenu.addItem(simMediaPlay)
        
        let simMediaStop = NSMenuItem(title: "Simulate Media Stopped", action: #selector(simMediaStopAction), keyEquivalent: "")
        simMediaStop.target = self
        simMenu.addItem(simMediaStop)
        
        simMenuItem.submenu = simMenu
        menu.addItem(simMenuItem)
        #endif
        
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
    
    #if DEBUG
    @objc private func simVolume() {
        Task { @MainActor in SystemEventSimulator.simulateVolumeChange() }
    }
    
    @objc private func simMute() {
        Task { @MainActor in SystemEventSimulator.simulateMute() }
    }
    
    @objc private func simBrightness() {
        Task { @MainActor in SystemEventSimulator.simulateBrightnessChange() }
    }
    
    @objc private func simCharging() {
        Task { @MainActor in SystemEventSimulator.simulateCharging() }
    }
    
    @objc private func simLowBattery() {
        Task { @MainActor in SystemEventSimulator.simulateLowBattery() }
    }
    
    @objc private func simMediaPlayAction() {
        Task { @MainActor in SystemEventSimulator.simulateMediaPlaying() }
    }
    
    @objc private func simMediaStopAction() {
        Task { @MainActor in SystemEventSimulator.simulateMediaStopped() }
    }
    #endif
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
