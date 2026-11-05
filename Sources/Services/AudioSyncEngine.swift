import Foundation
import AVFoundation
import Combine

public final class AudioSyncEngine: ObservableObject {
    public static let shared = AudioSyncEngine()
    
    @Published public var isAudioListening: Bool = false
    @Published public var currentRMS: Float = 0
    @Published public var lastOnsetTimestamp: TimeInterval = 0
    @Published public var useAudioOnsetSync: Bool = true
    
    private var audioEngine: AVAudioEngine?
    private var previousRMS: Float = 0
    private var smoothedEnergy: Float = 0
    private let onsetThreshold: Float = 0.022
    private var lastWordTriggerTime: TimeInterval = 0
    
    private init() {
        startListening()
    }
    
    public func startListening() {
        guard audioEngine == nil else { return }
        
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
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
    
    /// Checks if the next word should trigger now based on audio acoustics and expected time
    public func isWordTriggered(wordStartTime: TimeInterval, currentPosition: TimeInterval) -> Bool {
        // If audio onset sync is enabled
        if useAudioOnsetSync {
            let timeDiff = wordStartTime - currentPosition
            let now = CACurrentMediaTime()
            let recentOnset = (now - lastOnsetTimestamp < 0.12)
            
            // Tight anticipation window (within 100ms)
            if recentOnset && timeDiff > -0.05 && timeDiff <= 0.10 {
                return true
            }
        }
        
        // Standard high-resolution clock trigger
        return currentPosition >= wordStartTime
    }
}

