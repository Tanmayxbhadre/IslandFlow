import Foundation
import CoreGraphics

private typealias DisplayServicesGetBrightnessFunc = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
private typealias DisplayServicesSetBrightnessFunc = @convention(c) (CGDirectDisplayID, Float) -> Int32

@MainActor
public final class BrightnessManager: ObservableObject {
    public static let shared = BrightnessManager()

    @Published public private(set) var currentState: BrightnessState = BrightnessState(level: 75)

    /// Whether this Mac's display supports software brightness control via DisplayServices.
    @Published public private(set) var brightnessControllable: Bool = false

    private var getBrightnessFunc: DisplayServicesGetBrightnessFunc?
    private var setBrightnessFunc: DisplayServicesSetBrightnessFunc?

    private init() {
        setupDisplayServices()
        fetchBrightnessState()
    }

    private func setupDisplayServices() {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY) else {
            Logger.app.warning("[Brightness] DisplayServices.framework unavailable — brightness read/write disabled")
            return
        }

        if let getSym = dlsym(handle, "DisplayServicesGetBrightness") {
            getBrightnessFunc = unsafeBitCast(getSym, to: DisplayServicesGetBrightnessFunc.self)
        }

        if let setSym = dlsym(handle, "DisplayServicesSetBrightness") {
            setBrightnessFunc = unsafeBitCast(setSym, to: DisplayServicesSetBrightnessFunc.self)
            brightnessControllable = true
        } else {
            Logger.app.warning("[Brightness] DisplayServicesSetBrightness unavailable — brightness write disabled on this display configuration")
        }
    }

    public func fetchBrightnessState() {
        let mainDisplay = CGMainDisplayID()
        var brightness: Float = 0.75

        if let getBrightness = getBrightnessFunc {
            let result = getBrightness(mainDisplay, &brightness)
            if result != 0 {
                Logger.app.warning("[Brightness] DisplayServicesGetBrightness returned error \(result) — using fallback value")
                brightness = 0.75
            }
        }

        let level = Int(round(Double(brightness) * 100.0))
        let newState = BrightnessState(level: level)
        if currentState != newState {
            currentState = newState
            Logger.app.info("[Brightness] State updated: \(level)%")
        }
    }

    // MARK: — Write path

    /// Sets display brightness to the given percentage (0–100).
    /// Has no effect and logs a warning if the display does not support software brightness control.
    public func setBrightness(level: Int) {
        let clamped = min(max(level, 0), 100)
        let scalar = Float(clamped) / 100.0

        guard let setFn = setBrightnessFunc else {
            Logger.app.warning("[Brightness] setBrightness(\(clamped)) ignored — DisplayServicesSetBrightness unavailable")
            return
        }

        let result = setFn(CGMainDisplayID(), scalar)
        if result == 0 {
            // Immediately update local state — no async callback for brightness changes
            let newState = BrightnessState(level: clamped)
            if currentState != newState {
                currentState = newState
                Logger.app.info("[Brightness] Set to \(clamped)%")
            }
        } else {
            Logger.app.error("[Brightness] DisplayServicesSetBrightness returned error \(result)")
        }
    }

    public func increase(by delta: Int = 10) {
        setBrightness(level: currentState.level + delta)
    }

    public func decrease(by delta: Int = 10) {
        setBrightness(level: currentState.level - delta)
    }

    #if DEBUG
    public func simulateState(_ state: BrightnessState) {
        self.currentState = state
    }
    #endif
}
