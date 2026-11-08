import Foundation
import AVFoundation
import CoreAudio
import AudioToolbox
import Combine

public final class AudioSyncEngine: ObservableObject {
    public static let shared = AudioSyncEngine()
    
    @Published public var isAudioListening: Bool = false
    @Published public var currentRMS: Float = 0
    @Published public var lastOnsetTimestamp: TimeInterval = 0
    @Published public var useAudioOnsetSync: Bool = true
    @Published public var activeMicrophoneName: String = "Built-in Microphone"
    
    private var audioEngine: AVAudioEngine?
    private var previousRMS: Float = 0
    private var smoothedEnergy: Float = 0
    private let onsetThreshold: Float = 0.022
    private var lastWordTriggerTime: TimeInterval = 0
    
    // CoreAudio hardware device routing & monitoring
    private var currentSelectedDeviceID: AudioDeviceID?
    private var defaultInputListenerBlock: AudioObjectPropertyListenerBlock?
    private var devicesListenerBlock: AudioObjectPropertyListenerBlock?
    
    private init() {
        setupAudioDeviceListeners()
        startListening()
    }
    
    deinit {
        removeAudioDeviceListeners()
    }
    
    // MARK: - Built-in Microphone Selection
    
    /// Finds the MacBook's Built-in Microphone (or non-Bluetooth input device)
    /// to prevent macOS from dropping Bluetooth headsets (AirPods/Sony/Bose) to low-quality SCO telephone mode.
    public static func findBuiltInMicrophoneDeviceID() -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size) == noErr, size > 0 else {
            return nil
        }
        
        let count = Int(size) / MemoryLayout<AudioDeviceID>.size
        var devices = [AudioDeviceID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &devices) == noErr else {
            return nil
        }
        
        var builtInMicID: AudioDeviceID? = nil
        var nonBluetoothInputID: AudioDeviceID? = nil
        
        for dev in devices {
            // Check if device has input channels
            var streamAddr = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreams,
                mScope: kAudioObjectPropertyScopeInput,
                mElement: kAudioObjectPropertyElementMain
            )
            var streamSize: UInt32 = 0
            guard AudioObjectGetPropertyDataSize(dev, &streamAddr, 0, nil, &streamSize) == noErr, streamSize > 0 else {
                continue
            }
            
            // Check transport type
            var transportAddr = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyTransportType,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var transport: UInt32 = 0
            var tSize = UInt32(MemoryLayout<UInt32>.size)
            AudioObjectGetPropertyData(dev, &transportAddr, 0, nil, &tSize, &transport)
            
            let isBuiltIn = (transport == kAudioDeviceTransportTypeBuiltIn)
            let isBluetooth = (transport == kAudioDeviceTransportTypeBluetooth || transport == kAudioDeviceTransportTypeBluetoothLE)
            
            if isBuiltIn {
                builtInMicID = dev
                break // Found internal MacBook microphone!
            } else if !isBluetooth && nonBluetoothInputID == nil {
                nonBluetoothInputID = dev
            }
        }
        
        return builtInMicID ?? nonBluetoothInputID
    }
    
    public static func getDeviceName(_ deviceID: AudioDeviceID) -> String {
        var name: CFString = "" as CFString
        var nameSize = UInt32(MemoryLayout<CFString>.size)
        var nameAddr = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = withUnsafeMutablePointer(to: &name) { ptr in
            AudioObjectGetPropertyData(deviceID, &nameAddr, 0, nil, &nameSize, ptr)
        }
        if status == noErr {
            return name as String
        }
        return "Built-in Microphone"
    }
    
    // MARK: - Device Change Notification Handling
    
    private func setupAudioDeviceListeners() {
        var defaultInputAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let inputBlock: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.handleDeviceChange()
            }
        }
        self.defaultInputListenerBlock = inputBlock
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &defaultInputAddr,
            DispatchQueue.main,
            inputBlock
        )
        
        var devicesAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let devBlock: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.handleDeviceChange()
            }
        }
        self.devicesListenerBlock = devBlock
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &devicesAddr,
            DispatchQueue.main,
            devBlock
        )
    }
    
    private func removeAudioDeviceListeners() {
        if let block = defaultInputListenerBlock {
            var defaultInputAddr = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDefaultInputDevice,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject),
                &defaultInputAddr,
                DispatchQueue.main,
                block
            )
        }
        if let block = devicesListenerBlock {
            var devicesAddr = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDevices,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject),
                &devicesAddr,
                DispatchQueue.main,
                block
            )
        }
    }
    
    private func handleDeviceChange() {
        guard isAudioListening else { return }
        let targetMicID = Self.findBuiltInMicrophoneDeviceID()
        if targetMicID != currentSelectedDeviceID {
            print("AudioSyncEngine: Audio device configuration changed. Re-pinning to Built-in MacBook Microphone...")
            stopListening()
            startListening()
        }
    }
    
    // MARK: - Engine Lifecycle
    
    public func startListening() {
        guard audioEngine == nil else { return }
        
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        
        // Pin audio input unit to MacBook Built-in Microphone to prevent headset audio degradation
        if let micID = Self.findBuiltInMicrophoneDeviceID(), let audioUnit = inputNode.audioUnit {
            var deviceID = micID
            let status = AudioUnitSetProperty(
                audioUnit,
                kAudioOutputUnitProperty_CurrentDevice,
                kAudioUnitScope_Global,
                0,
                &deviceID,
                UInt32(MemoryLayout<AudioDeviceID>.size)
            )
            if status == noErr {
                self.currentSelectedDeviceID = micID
                let devName = Self.getDeviceName(micID)
                DispatchQueue.main.async {
                    self.activeMicrophoneName = devName
                }
                print("AudioSyncEngine: Successfully routed microphone to Built-in MacBook Mic: \(devName) (ID \(micID))")
            }
        }
        
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0 && format.channelCount > 0 else {
            return
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, when in
            self?.processAudioBuffer(buffer)
            AcousticVerseMatcher.shared.processBuffer(buffer, at: when)
        }
        
        do {
            try engine.start()
            self.audioEngine = engine
            DispatchQueue.main.async {
                self.isAudioListening = true
            }
        } catch {
            print("AudioEngine start notice: Falling back to software clock interpolation.")
        }
    }
    
    public func stopListening() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        DispatchQueue.main.async {
            self.isAudioListening = false
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return }
        
        var sumSquares: Float = 0
        for i in 0..<frameCount {
            let sample = channelData[i]
            sumSquares += sample * sample
        }
        let rms = sqrt(sumSquares / Float(frameCount))
        
        let now = CACurrentMediaTime()
        let delta = rms - smoothedEnergy
        
        // Detect sudden vocal burst / beat onset
        if delta > onsetThreshold && (now - lastOnsetTimestamp > 0.12) {
            DispatchQueue.main.async {
                self.lastOnsetTimestamp = now
            }
        }
        
        smoothedEnergy = smoothedEnergy * 0.85 + rms * 0.15
        
        // Publish smoothed RMS value to prevent visual jitter in views
        let dampedRMS = smoothedEnergy
        if abs(dampedRMS - self.currentRMS) > 0.008 {
            DispatchQueue.main.async {
                self.currentRMS = dampedRMS
            }
        }
    }
    
    /// Checks if the next word should trigger now based on high-resolution monotonic clock
    public func isWordTriggered(wordStartTime: TimeInterval, currentPosition: TimeInterval) -> Bool {
        // Standard high-resolution clock trigger: deterministic & monotonic
        return currentPosition >= wordStartTime
    }
}

