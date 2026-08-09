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

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private var mainContainerMenu: NSMenu?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        
        WindowManager.shared.setupWindow()
        _ = SystemHUDController.shared
        _ = MediaManager.shared
        _ = HoverSettings.shared
        
        Logger.app.info("IslandFlow Phase 10 launched successfully")
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "drop.fill", accessibilityDescription: "IslandFlow")
        }
        
        let menu = NSMenu()
        menu.delegate = self
        self.mainContainerMenu = menu
        
        rebuildMenu(menu)
        statusItem?.menu = menu
    }
    
    nonisolated func menuWillOpen(_ menu: NSMenu) {
        Task { @MainActor in
            if menu == self.mainContainerMenu {
                self.rebuildMenu(menu)
            }
        }
    }
    
    private func rebuildMenu(_ menu: NSMenu) {
        menu.removeAllItems()
        
        // Title Header
        let titleItem = NSMenuItem(title: "IslandFlow", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())
        
        // Toggle Expand / Collapse
        let toggleStateItem = NSMenuItem(title: "Toggle Expand / Collapse", action: #selector(toggleIslandState), keyEquivalent: "e")
        toggleStateItem.target = self
        menu.addItem(toggleStateItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // ── Hover Controls Submenu ──────────────────────────────────────────
        let hoverControlsMenuItem = NSMenuItem(title: "Hover Controls", action: nil, keyEquivalent: "")
        let hoverMenu = buildHoverControlsSubmenu()
        hoverControlsMenuItem.submenu = hoverMenu
        menu.addItem(hoverControlsMenuItem)
        
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
    }
    
    private func buildHoverControlsSubmenu() -> NSMenu {
        let settings = HoverSettings.shared
        let menu = NSMenu(title: "Hover Controls")
        
        // 1. Toggles: Hover Enabled, Open on Notch Hover, Collapse on Mouse Exit
        let hoverEnabledItem = createToggleItem(title: "Hover Enabled", state: settings.hoverEnabled, action: #selector(toggleHoverEnabled))
        menu.addItem(hoverEnabledItem)
        
        let openOnNotchItem = createToggleItem(title: "Open on Notch Hover", state: settings.openOnNotchHover, action: #selector(toggleOpenOnNotchHover))
        menu.addItem(openOnNotchItem)
        
        let collapseOnExitItem = createToggleItem(title: "Collapse on Mouse Exit", state: settings.collapseOnMouseExit, action: #selector(toggleCollapseOnMouseExit))
        menu.addItem(collapseOnExitItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 2. Delays (Open Delay, Close Delay, Hover Grace Period)
        let openDelaySubmenu = NSMenu(title: "Open Delay")
        for val in [0, 40, 80, 120, 200] {
            let item = NSMenuItem(title: "\(val) ms", action: #selector(setOpenDelay(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = val
            item.state = (settings.openDelay == val) ? .on : .off
            openDelaySubmenu.addItem(item)
        }
        let openDelayItem = NSMenuItem(title: "Open Delay", action: nil, keyEquivalent: "")
        openDelayItem.submenu = openDelaySubmenu
        menu.addItem(openDelayItem)
        
        let closeDelaySubmenu = NSMenu(title: "Close Delay")
        for val in [100, 150, 180, 220, 300] {
            let item = NSMenuItem(title: "\(val) ms", action: #selector(setCloseDelay(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = val
            item.state = (settings.closeDelay == val) ? .on : .off
            closeDelaySubmenu.addItem(item)
        }
        let closeDelayItem = NSMenuItem(title: "Close Delay", action: nil, keyEquivalent: "")
        closeDelayItem.submenu = closeDelaySubmenu
        menu.addItem(closeDelayItem)
        
        let graceSubmenu = NSMenu(title: "Hover Grace Period")
        for val in [100, 150, 180, 220, 300, 400] {
            let item = NSMenuItem(title: "\(val) ms", action: #selector(setGracePeriod(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = val
            item.state = (settings.hoverGracePeriod == val) ? .on : .off
            graceSubmenu.addItem(item)
        }
        let graceItem = NSMenuItem(title: "Hover Grace Period", action: nil, keyEquivalent: "")
        graceItem.submenu = graceSubmenu
        menu.addItem(graceItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 3. Animation Speed & Hover Sensitivity Submenus
        let animSpeedSubmenu = NSMenu(title: "Animation Speed")
        for speed in AnimationSpeed.allCases {
            let item = NSMenuItem(title: speed.rawValue, action: #selector(setAnimationSpeed(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = speed
            item.state = (settings.animationSpeed == speed) ? .on : .off
            animSpeedSubmenu.addItem(item)
        }
        let animSpeedItem = NSMenuItem(title: "Animation Speed", action: nil, keyEquivalent: "")
        animSpeedItem.submenu = animSpeedSubmenu
        menu.addItem(animSpeedItem)
        
        let sensSubmenu = NSMenu(title: "Hover Sensitivity")
        for sens in HoverSensitivity.allCases {
            let item = NSMenuItem(title: sens.rawValue, action: #selector(setHoverSensitivity(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = sens
            item.state = (settings.hoverSensitivity == sens) ? .on : .off
            sensSubmenu.addItem(item)
        }
        let sensItem = NSMenuItem(title: "Hover Sensitivity", action: nil, keyEquivalent: "")
        sensItem.submenu = sensSubmenu
        menu.addItem(sensItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 4. Region Rules: Require Notch Hover, Keep Open Inside Island
        let reqNotchItem = createToggleItem(title: "Require Notch Hover", state: settings.requireNotchHover, action: #selector(toggleRequireNotchHover))
        menu.addItem(reqNotchItem)
        
        let keepOpenItem = createToggleItem(title: "Keep Open While Inside Island", state: settings.keepOpenInsideIsland, action: #selector(toggleKeepOpenInsideIsland))
        menu.addItem(keepOpenItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 5. Ignore HUD Toggles
        let ignoreVolItem = createToggleItem(title: "Ignore Volume HUD", state: settings.ignoreVolumeHUD, action: #selector(toggleIgnoreVolumeHUD))
        menu.addItem(ignoreVolItem)
        
        let ignoreBrightItem = createToggleItem(title: "Ignore Brightness HUD", state: settings.ignoreBrightnessHUD, action: #selector(toggleIgnoreBrightnessHUD))
        menu.addItem(ignoreBrightItem)
        
        let ignoreMediaItem = createToggleItem(title: "Ignore Media Updates", state: settings.ignoreMediaUpdates, action: #selector(toggleIgnoreMediaUpdates))
        menu.addItem(ignoreMediaItem)
        
        let ignoreSpaceItem = createToggleItem(title: "Ignore Space Changes", state: settings.ignoreSpaceChanges, action: #selector(toggleIgnoreSpaceChanges))
        menu.addItem(ignoreSpaceItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 6. Debug & Reset
        let debugItem = createToggleItem(title: "Debug Hover State", state: settings.debugHoverState, action: #selector(toggleDebugHoverState))
        menu.addItem(debugItem)
        
        let resetItem = NSMenuItem(title: "Reset Hover Settings", action: #selector(resetHoverSettings), keyEquivalent: "")
        resetItem.target = self
        menu.addItem(resetItem)
        
        return menu
    }
    
    private func createToggleItem(title: String, state: Bool, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.state = state ? .on : .off
        return item
    }
    
    // MARK: — Submenu Actions
    
    @objc private func toggleHoverEnabled() {
        HoverSettings.shared.hoverEnabled.toggle()
    }
    @objc private func toggleOpenOnNotchHover() {
        HoverSettings.shared.openOnNotchHover.toggle()
    }
    @objc private func toggleCollapseOnMouseExit() {
        HoverSettings.shared.collapseOnMouseExit.toggle()
    }
    @objc private func setOpenDelay(_ sender: NSMenuItem) {
        if let val = sender.representedObject as? Int {
            HoverSettings.shared.openDelay = val
        }
    }
    @objc private func setCloseDelay(_ sender: NSMenuItem) {
        if let val = sender.representedObject as? Int {
            HoverSettings.shared.closeDelay = val
        }
    }
    @objc private func setGracePeriod(_ sender: NSMenuItem) {
        if let val = sender.representedObject as? Int {
            HoverSettings.shared.hoverGracePeriod = val
        }
    }
    @objc private func setAnimationSpeed(_ sender: NSMenuItem) {
        if let speed = sender.representedObject as? AnimationSpeed {
            HoverSettings.shared.animationSpeed = speed
        }
    }
    @objc private func setHoverSensitivity(_ sender: NSMenuItem) {
        if let sens = sender.representedObject as? HoverSensitivity {
            HoverSettings.shared.hoverSensitivity = sens
        }
    }
    @objc private func toggleRequireNotchHover() {
        HoverSettings.shared.requireNotchHover.toggle()
    }
    @objc private func toggleKeepOpenInsideIsland() {
        HoverSettings.shared.keepOpenInsideIsland.toggle()
    }
    @objc private func toggleIgnoreVolumeHUD() {
        HoverSettings.shared.ignoreVolumeHUD.toggle()
    }
    @objc private func toggleIgnoreBrightnessHUD() {
        HoverSettings.shared.ignoreBrightnessHUD.toggle()
    }
    @objc private func toggleIgnoreMediaUpdates() {
        HoverSettings.shared.ignoreMediaUpdates.toggle()
    }
    @objc private func toggleIgnoreSpaceChanges() {
        HoverSettings.shared.ignoreSpaceChanges.toggle()
    }
    @objc private func toggleDebugHoverState() {
        HoverSettings.shared.debugHoverState.toggle()
    }
    @objc private func resetHoverSettings() {
        HoverSettings.shared.resetToDefaults()
    }

    @objc private func toggleIslandState() {
        AppState.shared.toggleState()
    }
    
    #if DEBUG
    @objc private func simVolume() {
        SystemEventSimulator.simulateVolumeChange()
    }
    
    @objc private func simMute() {
        SystemEventSimulator.simulateMute()
    }
    
    @objc private func simBrightness() {
        SystemEventSimulator.simulateBrightnessChange()
    }
    
    @objc private func simCharging() {
        SystemEventSimulator.simulateCharging()
    }
    
    @objc private func simLowBattery() {
        SystemEventSimulator.simulateLowBattery()
    }
    
    @objc private func simMediaPlayAction() {
        SystemEventSimulator.simulateMediaPlaying()
    }
    
    @objc private func simMediaStopAction() {
        SystemEventSimulator.simulateMediaStopped()
    }
    #endif
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
