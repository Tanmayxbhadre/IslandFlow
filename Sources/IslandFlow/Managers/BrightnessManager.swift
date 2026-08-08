import Foundation
import CoreGraphics

private typealias DisplayServicesGetBrightnessFunc = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32

@MainActor
public final class BrightnessManager: ObservableObject {
    public static let shared = BrightnessManager()
    
    @Published public private(set) var currentState: BrightnessState = BrightnessState(level: 75)
    private var getBrightnessFunc: DisplayServicesGetBrightnessFunc?
    
    private init() {
        setupDisplayServices()
        fetchBrightnessState()
    }
    
    private func setupDisplayServices() {
        let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY)
        if let handle = handle {
            if let sym = dlsym(handle, "DisplayServicesGetBrightness") {
                getBrightnessFunc = unsafeBitCast(sym, to: DisplayServicesGetBrightnessFunc.self)
            }
        }
    }
    
    public func fetchBrightnessState() {
        let mainDisplay = CGMainDisplayID()
        var brightness: Float = 0.75
        
        if let getBrightness = getBrightnessFunc {
            let result = getBrightness(mainDisplay, &brightness)
            if result != 0 {
                brightness = 0.75
            }
        }
        
        let level = Int(round(brightness * 100.0))
        let newState = BrightnessState(level: level)
        if currentState != newState {
            currentState = newState
            Logger.app.info("Brightness state updated: \(level)%")
        }
    }
    
    #if DEBUG
    public func simulateState(_ state: BrightnessState) {
        self.currentState = state
    }
    #endif
}
