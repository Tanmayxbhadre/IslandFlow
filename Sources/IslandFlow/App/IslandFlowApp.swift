import SwiftUI
import AppKit
import Combine

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
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        
        WindowManager.shared.setupWindow()
        _ = SystemHUDController.shared
        _ = MediaManager.shared
        _ = HoverSettings.shared
        _ = SystemStateController.shared
        _ = SimulationController.shared
        
        observeStateChanges()
        
        Logger.app.info("IslandFlow Phase 11 launched successfully")
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

    private func observeStateChanges() {
        // Observe system & simulation updates to refresh menu dynamically
        SystemStateController.shared.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshMenuIfOpen()
            }
            .store(in: &cancellables)

        SimulationController.shared.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshMenuIfOpen()
            }
            .store(in: &cancellables)

        HoverSettings.shared.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshMenuIfOpen()
            }
            .store(in: &cancellables)
    }

    private func refreshMenuIfOpen() {
        if let menu = mainContainerMenu {
            rebuildMenu(menu)
        }
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
        
        // 1. Header Title
        let titleItem = NSMenuItem(title: "IslandFlow", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())
        
        // 2. Toggle Expand / Collapse
        let toggleStateItem = NSMenuItem(title: "Toggle Expand / Collapse", action: #selector(toggleIslandState), keyEquivalent: "e")
        toggleStateItem.target = self
        menu.addItem(toggleStateItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 3. Hover Controls Submenu (Phase 10)
        let hoverControlsMenuItem = NSMenuItem(title: "Hover Controls", action: nil, keyEquivalent: "")
        let hoverMenu = buildHoverControlsSubmenu()
        hoverControlsMenuItem.submenu = hoverMenu
        menu.addItem(hoverControlsMenuItem)
        
        menu.addItem(NSMenuItem.separator())

        // 4. Dynamic Live Status & Simulations Submenu (Phase 11)
        let simMenuItem = NSMenuItem(title: "Simulate HUD & Media Events", action: nil, keyEquivalent: "")
        let simMenu = buildSimulationsSubmenu()
        simMenuItem.submenu = simMenu
        menu.addItem(simMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 5. Quit
        let quitItem = NSMenuItem(title: "Quit IslandFlow", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    // MARK: — Hover Controls Submenu (Phase 10)

    private func buildHoverControlsSubmenu() -> NSMenu {
        let settings = HoverSettings.shared
        let menu = NSMenu(title: "Hover Controls")
        
        let hoverEnabledItem = createToggleItem(title: "Hover Enabled", state: settings.hoverEnabled, action: #selector(toggleHoverEnabled))
        menu.addItem(hoverEnabledItem)
        
        let openOnNotchItem = createToggleItem(title: "Open on Notch Hover", state: settings.openOnNotchHover, action: #selector(toggleOpenOnNotchHover))
        menu.addItem(openOnNotchItem)
        
        let collapseOnExitItem = createToggleItem(title: "Collapse on Mouse Exit", state: settings.collapseOnMouseExit, action: #selector(toggleCollapseOnMouseExit))
        menu.addItem(collapseOnExitItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Delays
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
        
        // Animation Speed & Hover Sensitivity
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
        
        // Region Rules
        let reqNotchItem = createToggleItem(title: "Require Notch Hover", state: settings.requireNotchHover, action: #selector(toggleRequireNotchHover))
        menu.addItem(reqNotchItem)
        
        let keepOpenItem = createToggleItem(title: "Keep Open While Inside Island", state: settings.keepOpenInsideIsland, action: #selector(toggleKeepOpenInsideIsland))
        menu.addItem(keepOpenItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Ignore HUD Toggles
        let ignoreVolItem = createToggleItem(title: "Ignore Volume HUD", state: settings.ignoreVolumeHUD, action: #selector(toggleIgnoreVolumeHUD))
        menu.addItem(ignoreVolItem)
        
        let ignoreBrightItem = createToggleItem(title: "Ignore Brightness HUD", state: settings.ignoreBrightnessHUD, action: #selector(toggleIgnoreBrightnessHUD))
        menu.addItem(ignoreBrightItem)
        
        let ignoreMediaItem = createToggleItem(title: "Ignore Media Updates", state: settings.ignoreMediaUpdates, action: #selector(toggleIgnoreMediaUpdates))
        menu.addItem(ignoreMediaItem)
        
        let ignoreSpaceItem = createToggleItem(title: "Ignore Space Changes", state: settings.ignoreSpaceChanges, action: #selector(toggleIgnoreSpaceChanges))
        menu.addItem(ignoreSpaceItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Debug & Reset
        let debugItem = createToggleItem(title: "Debug Hover State", state: settings.debugHoverState, action: #selector(toggleDebugHoverState))
        menu.addItem(debugItem)
        
        let resetItem = NSMenuItem(title: "Reset Hover Settings", action: #selector(resetHoverSettings), keyEquivalent: "")
        resetItem.target = self
        menu.addItem(resetItem)
        
        return menu
    }

    // MARK: — Dynamic Live Status & Simulations Submenu (Phase 11)

    private func buildSimulationsSubmenu() -> NSMenu {
        let menu = NSMenu(title: "Simulate HUD & Media Events")
        let sysState = SystemStateController.shared
        let simState = SimulationController.shared

        let effVol = sysState.effectiveVolume
        let effBright = sysState.effectiveBrightness
        let effBat = sysState.effectiveBattery
        let effMedia = sysState.effectiveMedia

        // 1. Volume Submenu Item (Live title)
        let volTitle = effVol.isMuted
            ? "Volume (Muted)"
            : "Volume (\(effVol.level)%)"
        let volMenuItem = NSMenuItem(title: volTitle, action: nil, keyEquivalent: "")
        volMenuItem.submenu = buildVolumeSubmenu(effVol: effVol, isSimulated: simState.simulatedVolume != nil)
        menu.addItem(volMenuItem)

        // 2. Brightness Submenu Item (Live title)
        let brightTitle = "Brightness (\(effBright.level)%)"
        let brightMenuItem = NSMenuItem(title: brightTitle, action: nil, keyEquivalent: "")
        brightMenuItem.submenu = buildBrightnessSubmenu(effBright: effBright, isSimulated: simState.simulatedBrightness != nil)
        menu.addItem(brightMenuItem)

        // 3. Battery Submenu Item (Live title)
        let batTitle: String
        if effBat.isCharging {
            batTitle = "Charging (\(effBat.percentage)%)"
        } else if effBat.isLow {
            batTitle = "Low Battery (\(effBat.percentage)%)"
        } else {
            batTitle = "Battery (\(effBat.percentage)%)"
        }
        let batMenuItem = NSMenuItem(title: batTitle, action: nil, keyEquivalent: "")
        batMenuItem.submenu = buildBatterySubmenu(effBat: effBat, isSimulated: simState.simulatedBattery != nil)
        menu.addItem(batMenuItem)

        // 4. Media Submenu Item (Live title)
        let mediaTitle = "Media: \(effMedia.isPlaying ? "Playing" : (effMedia.playbackState == .paused ? "Paused" : "Stopped"))"
        let mediaMenuItem = NSMenuItem(title: mediaTitle, action: nil, keyEquivalent: "")
        mediaMenuItem.submenu = buildMediaSubmenu(effMedia: effMedia, isSimulated: simState.simulatedMedia != nil)
        menu.addItem(mediaMenuItem)

        menu.addItem(NSMenuItem.separator())

        // 5. Debug State Submenu Item
        let debugStateMenuItem = NSMenuItem(title: "Debug State", action: nil, keyEquivalent: "")
        debugStateMenuItem.submenu = buildDebugStateSubmenu()
        menu.addItem(debugStateMenuItem)

        menu.addItem(NSMenuItem.separator())

        // 6. Reset Simulations Item
        let resetSimsItem = NSMenuItem(title: "Reset Simulations", action: #selector(resetAllSimulations), keyEquivalent: "")
        resetSimsItem.target = self
        resetSimsItem.isEnabled = simState.isSimulatingAny
        menu.addItem(resetSimsItem)

        return menu
    }

    // MARK: — Submenus for Volume, Brightness, Battery, Media, Debug

    private func buildVolumeSubmenu(effVol: VolumeState, isSimulated: Bool) -> NSMenu {
        let menu = NSMenu(title: "Volume")
        
        let header = NSMenuItem(title: "Current Volume: \(effVol.level)% \(isSimulated ? "(Simulated)" : "(System)")", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(NSMenuItem.separator())

        for pct in [0, 25, 50, 75, 100] {
            let item = NSMenuItem(title: "Set to \(pct)%", action: #selector(setSimulatedVolumeLevel(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = pct
            item.state = (effVol.level == pct && !effVol.isMuted) ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        let incItem = NSMenuItem(title: "Increase Volume (+10%)", action: #selector(increaseVolumeAction), keyEquivalent: "")
        incItem.target = self
        menu.addItem(incItem)

        let decItem = NSMenuItem(title: "Decrease Volume (-10%)", action: #selector(decreaseVolumeAction), keyEquivalent: "")
        decItem.target = self
        menu.addItem(decItem)

        let muteItem = NSMenuItem(title: "Muted", action: #selector(toggleMuteAction), keyEquivalent: "")
        muteItem.target = self
        muteItem.state = effVol.isMuted ? .on : .off
        menu.addItem(muteItem)

        menu.addItem(NSMenuItem.separator())

        let resetVolItem = NSMenuItem(title: "Reset Volume Simulation", action: #selector(resetVolumeSimulationAction), keyEquivalent: "")
        resetVolItem.target = self
        resetVolItem.isEnabled = isSimulated
        menu.addItem(resetVolItem)

        return menu
    }

    private func buildBrightnessSubmenu(effBright: BrightnessState, isSimulated: Bool) -> NSMenu {
        let menu = NSMenu(title: "Brightness")

        let header = NSMenuItem(title: "Current Brightness: \(effBright.level)% \(isSimulated ? "(Simulated)" : "(System)")", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(NSMenuItem.separator())

        for pct in [0, 25, 50, 75, 100] {
            let item = NSMenuItem(title: "Set to \(pct)%", action: #selector(setSimulatedBrightnessLevel(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = pct
            item.state = (effBright.level == pct) ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        let incItem = NSMenuItem(title: "Increase Brightness (+10%)", action: #selector(increaseBrightnessAction), keyEquivalent: "")
        incItem.target = self
        menu.addItem(incItem)

        let decItem = NSMenuItem(title: "Decrease Brightness (-10%)", action: #selector(decreaseBrightnessAction), keyEquivalent: "")
        decItem.target = self
        menu.addItem(decItem)

        menu.addItem(NSMenuItem.separator())

        let resetItem = NSMenuItem(title: "Reset Brightness Simulation", action: #selector(resetBrightnessSimulationAction), keyEquivalent: "")
        resetItem.target = self
        resetItem.isEnabled = isSimulated
        menu.addItem(resetItem)

        return menu
    }

    private func buildBatterySubmenu(effBat: BatteryState, isSimulated: Bool) -> NSMenu {
        let menu = NSMenu(title: "Battery")

        let statusText = effBat.isCharging ? "Charging" : (effBat.isFull ? "Full" : "Discharging")
        let header = NSMenuItem(title: "Current Battery: \(effBat.percentage)% (\(statusText)) \(isSimulated ? "[Simulated]" : "[System]")", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(NSMenuItem.separator())

        let item15 = NSMenuItem(title: "Simulate 15% (Low Battery)", action: #selector(simLowBatteryAction), keyEquivalent: "")
        item15.target = self
        item15.state = (effBat.percentage == 15 && effBat.isLow) ? .on : .off
        menu.addItem(item15)

        let item25 = NSMenuItem(title: "Simulate 25%", action: #selector(simBattery25Action), keyEquivalent: "")
        item25.target = self
        item25.state = (effBat.percentage == 25) ? .on : .off
        menu.addItem(item25)

        let item50 = NSMenuItem(title: "Simulate 50%", action: #selector(simBattery50Action), keyEquivalent: "")
        item50.target = self
        item50.state = (effBat.percentage == 50) ? .on : .off
        menu.addItem(item50)

        let item85 = NSMenuItem(title: "Simulate 85% (Charging)", action: #selector(simChargingAction), keyEquivalent: "")
        item85.target = self
        item85.state = (effBat.percentage == 85 && effBat.isCharging) ? .on : .off
        menu.addItem(item85)

        let item100 = NSMenuItem(title: "Simulate 100% (Full)", action: #selector(simBattery100Action), keyEquivalent: "")
        item100.target = self
        item100.state = (effBat.percentage == 100 && effBat.isFull) ? .on : .off
        menu.addItem(item100)

        menu.addItem(NSMenuItem.separator())

        let toggleChargeItem = NSMenuItem(title: "Toggle Charging State", action: #selector(toggleChargingAction), keyEquivalent: "")
        toggleChargeItem.target = self
        toggleChargeItem.state = effBat.isCharging ? .on : .off
        menu.addItem(toggleChargeItem)

        menu.addItem(NSMenuItem.separator())

        let resetItem = NSMenuItem(title: "Reset Battery Simulation", action: #selector(resetBatterySimulationAction), keyEquivalent: "")
        resetItem.target = self
        resetItem.isEnabled = isSimulated
        menu.addItem(resetItem)

        return menu
    }

    private func buildMediaSubmenu(effMedia: MediaState, isSimulated: Bool) -> NSMenu {
        let menu = NSMenu(title: "Media")

        let trackInfo = effMedia.title.isEmpty || effMedia.title == "No Track"
            ? "No Active Media"
            : "\(effMedia.title) - \(effMedia.artist)"
        let header = NSMenuItem(title: "Track: \(trackInfo) \(isSimulated ? "[Simulated]" : "")", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(NSMenuItem.separator())

        let playItem = NSMenuItem(title: "Simulate Playing", action: #selector(simMediaPlayAction), keyEquivalent: "")
        playItem.target = self
        playItem.state = effMedia.isPlaying ? .on : .off
        menu.addItem(playItem)

        let pauseItem = NSMenuItem(title: "Simulate Paused", action: #selector(simMediaPauseAction), keyEquivalent: "")
        pauseItem.target = self
        pauseItem.state = (effMedia.playbackState == .paused) ? .on : .off
        menu.addItem(pauseItem)

        let stopItem = NSMenuItem(title: "Simulate Stopped", action: #selector(simMediaStopAction), keyEquivalent: "")
        stopItem.target = self
        stopItem.state = (effMedia.playbackState == .stopped) ? .on : .off
        menu.addItem(stopItem)

        menu.addItem(NSMenuItem.separator())

        let nextItem = NSMenuItem(title: "Next Track", action: #selector(nextTrackAction), keyEquivalent: "")
        nextItem.target = self
        menu.addItem(nextItem)

        let prevItem = NSMenuItem(title: "Previous Track", action: #selector(previousTrackAction), keyEquivalent: "")
        prevItem.target = self
        menu.addItem(prevItem)

        menu.addItem(NSMenuItem.separator())

        let resetItem = NSMenuItem(title: "Reset Media Simulation", action: #selector(resetMediaSimulationAction), keyEquivalent: "")
        resetItem.target = self
        resetItem.isEnabled = isSimulated
        menu.addItem(resetItem)

        return menu
    }

    private func buildDebugStateSubmenu() -> NSMenu {
        let menu = NSMenu(title: "Debug State")
        let sys = SystemStateController.shared
        let sim = SimulationController.shared
        let ic = IslandInteractionController.shared

        let srcItem = NSMenuItem(title: "Source: \(sim.isSimulatingAny ? "Simulation Active" : "Live System")", action: nil, keyEquivalent: "")
        srcItem.isEnabled = false
        menu.addItem(srcItem)
        menu.addItem(NSMenuItem.separator())

        let volStr = "Volume: Actual \(sys.actualVolume.level)%, Effective \(sys.effectiveVolume.level)% \(sys.effectiveVolume.isMuted ? "[MUTED]" : "")"
        let volItem = NSMenuItem(title: volStr, action: nil, keyEquivalent: "")
        volItem.isEnabled = false
        menu.addItem(volItem)

        let brightStr = "Brightness: Actual \(sys.actualBrightness.level)%, Effective \(sys.effectiveBrightness.level)%"
        let brightItem = NSMenuItem(title: brightStr, action: nil, keyEquivalent: "")
        brightItem.isEnabled = false
        menu.addItem(brightItem)

        let batStr = "Battery: Actual \(sys.actualBattery.percentage)%, Effective \(sys.effectiveBattery.percentage)% \(sys.effectiveBattery.isCharging ? "[CHARGING]" : "")"
        let batItem = NSMenuItem(title: batStr, action: nil, keyEquivalent: "")
        batItem.isEnabled = false
        menu.addItem(batItem)

        let mediaStr = "Media: Actual \(sys.actualMedia.isPlaying ? "Playing" : "Stopped"), Effective \(sys.effectiveMedia.isPlaying ? "Playing" : (sys.effectiveMedia.playbackState == .paused ? "Paused" : "Stopped"))"
        let mediaItem = NSMenuItem(title: mediaStr, action: nil, keyEquivalent: "")
        mediaItem.isEnabled = false
        menu.addItem(mediaItem)

        menu.addItem(NSMenuItem.separator())

        let hoverStr = "Hover: State \(String(describing: ic.state).uppercased()), Progress \(String(format: "%.2f", AppState.shared.expansionProgress))"
        let hoverItem = NSMenuItem(title: hoverStr, action: nil, keyEquivalent: "")
        hoverItem.isEnabled = false
        menu.addItem(hoverItem)

        return menu
    }

    private func createToggleItem(title: String, state: Bool, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.state = state ? .on : .off
        return item
    }
    
    // MARK: — Submenu Actions (Hover Settings)
    
    @objc private func toggleHoverEnabled() { HoverSettings.shared.hoverEnabled.toggle() }
    @objc private func toggleOpenOnNotchHover() { HoverSettings.shared.openOnNotchHover.toggle() }
    @objc private func toggleCollapseOnMouseExit() { HoverSettings.shared.collapseOnMouseExit.toggle() }
    @objc private func setOpenDelay(_ sender: NSMenuItem) {
        if let val = sender.representedObject as? Int { HoverSettings.shared.openDelay = val }
    }
    @objc private func setCloseDelay(_ sender: NSMenuItem) {
        if let val = sender.representedObject as? Int { HoverSettings.shared.closeDelay = val }
    }
    @objc private func setGracePeriod(_ sender: NSMenuItem) {
        if let val = sender.representedObject as? Int { HoverSettings.shared.hoverGracePeriod = val }
    }
    @objc private func setAnimationSpeed(_ sender: NSMenuItem) {
        if let speed = sender.representedObject as? AnimationSpeed { HoverSettings.shared.animationSpeed = speed }
    }
    @objc private func setHoverSensitivity(_ sender: NSMenuItem) {
        if let sens = sender.representedObject as? HoverSensitivity { HoverSettings.shared.hoverSensitivity = sens }
    }
    @objc private func toggleRequireNotchHover() { HoverSettings.shared.requireNotchHover.toggle() }
    @objc private func toggleKeepOpenInsideIsland() { HoverSettings.shared.keepOpenInsideIsland.toggle() }
    @objc private func toggleIgnoreVolumeHUD() { HoverSettings.shared.ignoreVolumeHUD.toggle() }
    @objc private func toggleIgnoreBrightnessHUD() { HoverSettings.shared.ignoreBrightnessHUD.toggle() }
    @objc private func toggleIgnoreMediaUpdates() { HoverSettings.shared.ignoreMediaUpdates.toggle() }
    @objc private func toggleIgnoreSpaceChanges() { HoverSettings.shared.ignoreSpaceChanges.toggle() }
    @objc private func toggleDebugHoverState() { HoverSettings.shared.debugHoverState.toggle() }
    @objc private func resetHoverSettings() { HoverSettings.shared.resetToDefaults() }

    @objc private func toggleIslandState() { AppState.shared.toggleState() }

    // MARK: — Submenu Actions (Volume / Brightness / Battery / Media / Reset)

    @objc private func setSimulatedVolumeLevel(_ sender: NSMenuItem) {
        if let level = sender.representedObject as? Int {
            SimulationController.shared.setSimulatedVolume(level: level)
        }
    }
    @objc private func increaseVolumeAction() {
        if SimulationController.shared.simulatedVolume != nil {
            let current = SystemStateController.shared.effectiveVolume.level
            SimulationController.shared.setSimulatedVolume(level: current + 10)
        } else {
            VolumeManager.shared.adjustVolume(by: 10)
        }
    }
    @objc private func decreaseVolumeAction() {
        if SimulationController.shared.simulatedVolume != nil {
            let current = SystemStateController.shared.effectiveVolume.level
            SimulationController.shared.setSimulatedVolume(level: current - 10)
        } else {
            VolumeManager.shared.adjustVolume(by: -10)
        }
    }
    @objc private func toggleMuteAction() {
        if SimulationController.shared.simulatedVolume != nil {
            let current = SystemStateController.shared.effectiveVolume
            SimulationController.shared.setSimulatedVolume(level: current.level, isMuted: !current.isMuted)
        } else {
            VolumeManager.shared.toggleMute()
        }
    }
    @objc private func resetVolumeSimulationAction() {
        SimulationController.shared.resetVolumeSimulation()
    }

    @objc private func setSimulatedBrightnessLevel(_ sender: NSMenuItem) {
        if let level = sender.representedObject as? Int {
            SimulationController.shared.setSimulatedBrightness(level: level)
        }
    }
    @objc private func increaseBrightnessAction() {
        let current = SystemStateController.shared.effectiveBrightness.level
        SimulationController.shared.setSimulatedBrightness(level: current + 10)
    }
    @objc private func decreaseBrightnessAction() {
        let current = SystemStateController.shared.effectiveBrightness.level
        SimulationController.shared.setSimulatedBrightness(level: current - 10)
    }
    @objc private func resetBrightnessSimulationAction() {
        SimulationController.shared.resetBrightnessSimulation()
    }

    @objc private func simLowBatteryAction() {
        SimulationController.shared.setSimulatedBattery(percentage: 15, isCharging: false)
    }
    @objc private func simBattery25Action() {
        SimulationController.shared.setSimulatedBattery(percentage: 25, isCharging: false)
    }
    @objc private func simBattery50Action() {
        SimulationController.shared.setSimulatedBattery(percentage: 50, isCharging: false)
    }
    @objc private func simChargingAction() {
        SimulationController.shared.setSimulatedBattery(percentage: 85, isCharging: true)
    }
    @objc private func simBattery100Action() {
        SimulationController.shared.setSimulatedBattery(percentage: 100, isCharging: true, isFull: true)
    }
    @objc private func toggleChargingAction() {
        let current = SystemStateController.shared.effectiveBattery
        SimulationController.shared.setSimulatedBattery(percentage: current.percentage, isCharging: !current.isCharging, isFull: current.isFull)
    }
    @objc private func resetBatterySimulationAction() {
        SimulationController.shared.resetBatterySimulation()
    }

    @objc private func simMediaPlayAction() {
        SimulationController.shared.setSimulatedMedia(isPlaying: true)
    }
    @objc private func simMediaPauseAction() {
        SimulationController.shared.setSimulatedMedia(isPlaying: false)
    }
    @objc private func simMediaStopAction() {
        SimulationController.shared.setSimulatedMediaStopped()
    }
    @objc private func nextTrackAction() {
        MediaManager.shared.nextTrack()
    }
    @objc private func previousTrackAction() {
        MediaManager.shared.previousTrack()
    }
    @objc private func resetMediaSimulationAction() {
        SimulationController.shared.resetMediaSimulation()
    }

    @objc private func resetAllSimulations() {
        SimulationController.shared.resetAll()
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
