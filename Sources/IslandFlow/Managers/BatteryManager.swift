import Foundation
import IOKit.ps

@MainActor
public final class BatteryManager: ObservableObject {
    public static let shared = BatteryManager()
    
    @Published public private(set) var currentState: BatteryState?
    private var runLoopSource: Unmanaged<CFRunLoopSource>?
    
    private init() {
        fetchBatteryState()
        registerForPowerNotifications()
    }
    
    public func fetchBatteryState() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return
        }
        
        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            
            let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int ?? 0
            let maxCapacity = description[kIOPSMaxCapacityKey] as? Int ?? 100
            let isCharging = (description[kIOPSIsChargingKey] as? Bool) ?? false
            let isCharged = (description[kIOPSIsChargedKey] as? Bool) ?? false
            let powerSource = description[kIOPSPowerSourceStateKey] as? String
            
            let percentage = maxCapacity > 0 ? Int((Double(currentCapacity) / Double(maxCapacity)) * 100.0) : 0
            let isPlugged = powerSource == kIOPSACPowerValue
            let charging = isCharging || (isPlugged && !isCharged && percentage < 100)
            
            let newState = BatteryState(
                percentage: percentage,
                isCharging: charging,
                isFull: isCharged || percentage >= 100
            )
            
            if currentState != newState {
                currentState = newState
                Logger.app.info("Battery state updated: \(percentage)%, charging: \(charging)")
            }
            break
        }
    }
    
    private func registerForPowerNotifications() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        let loopSource = IOPSNotificationCreateRunLoopSource({ context in
            guard let context = context else { return }
            let manager = Unmanaged<BatteryManager>.fromOpaque(context).takeUnretainedValue()
            Task { @MainActor in
                manager.fetchBatteryState()
            }
        }, context)
        
        if let source = loopSource?.takeRetainedValue() {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
        }
    }
    
    public func simulateState(_ state: BatteryState) {
        self.currentState = state
    }
}
