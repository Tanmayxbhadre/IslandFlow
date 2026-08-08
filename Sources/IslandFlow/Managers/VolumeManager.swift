import Foundation
import CoreAudio

@MainActor
public final class VolumeManager: ObservableObject {
    public static let shared = VolumeManager()
    
    @Published public private(set) var currentState: VolumeState = VolumeState(level: 50, isMuted: false)
    
    private init() {
        fetchVolumeState()
        setupCoreAudioListener()
    }
    
    public func fetchVolumeState() {
        var defaultDeviceID = AudioObjectID(kAudioObjectUnknown)
        var propertySize = UInt32(MemoryLayout<AudioObjectID>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &defaultDeviceID
        )
        
        guard status == noErr, defaultDeviceID != kAudioObjectUnknown else { return }
        
        var volume: Float32 = 0.0
        var volSize = UInt32(MemoryLayout<Float32>.size)
        var volAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        if AudioObjectGetPropertyData(defaultDeviceID, &volAddress, 0, nil, &volSize, &volume) != noErr {
            volAddress.mElement = 1
            _ = AudioObjectGetPropertyData(defaultDeviceID, &volAddress, 0, nil, &volSize, &volume)
        }
        
        var isMutedInt: UInt32 = 0
        var muteSize = UInt32(MemoryLayout<UInt32>.size)
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        _ = AudioObjectGetPropertyData(defaultDeviceID, &muteAddress, 0, nil, &muteSize, &isMutedInt)
        
        let level = Int(round(volume * 100.0))
        let isMuted = isMutedInt != 0
        
        let newState = VolumeState(level: level, isMuted: isMuted)
        if currentState != newState {
            currentState = newState
            Logger.app.info("Volume state updated: \(level)%, muted: \(isMuted)")
        }
    }
    
    private func setupCoreAudioListener() {
        var defaultDeviceID = AudioObjectID(kAudioObjectUnknown)
        var propertySize = UInt32(MemoryLayout<AudioObjectID>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &defaultDeviceID
        )
        
        guard status == noErr, defaultDeviceID != kAudioObjectUnknown else { return }
        
        var volAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectAddPropertyListenerBlock(defaultDeviceID, &volAddress, DispatchQueue.main) { [weak self] _, _ in
            Task { @MainActor in
                self?.fetchVolumeState()
            }
        }
        
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectAddPropertyListenerBlock(defaultDeviceID, &muteAddress, DispatchQueue.main) { [weak self] _, _ in
            Task { @MainActor in
                self?.fetchVolumeState()
            }
        }
    }
    
    public func simulateState(_ state: VolumeState) {
        self.currentState = state
    }
}
