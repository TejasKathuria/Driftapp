import Foundation
import ShazamKit
import AVFoundation
import Combine

public final class AcousticVerseMatcher: NSObject, ObservableObject, SHSessionDelegate {
    public static let shared = AcousticVerseMatcher()
    
    @Published public var lastAcousticOffset: TimeInterval = 0
    @Published public var isAcousticallyLocked: Bool = false
    @Published public var sensorStatusText: String = "Listening to internal audio..."
    @Published public var detectedSongTitle: String = ""
    @Published public var detectedArtist: String = ""
    
    private var session: SHSession?
    private var lastMatchWallTime: TimeInterval = 0
    private var bufferCounter: Int = 0
    
    private override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        let shSession = SHSession()
        shSession.delegate = self
        self.session = shSession
    }
    
    public func processBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime?) {
        bufferCounter += 1
        // Feed audio frames to ShazamKit streaming session
        session?.matchStreamingBuffer(buffer, at: time)
    }
    
    // MARK: - SHSessionDelegate
    
    public func session(_ session: SHSession, didFind match: SHMatch) {
        guard let item = match.mediaItems.first else { return }
        let acousticOffset = item.predictedCurrentMatchOffset
        let now = CACurrentMediaTime()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lastAcousticOffset = acousticOffset
            self.lastMatchWallTime = now
            self.isAcousticallyLocked = true
            self.detectedSongTitle = item.title ?? ""
            self.detectedArtist = item.artist ?? ""
            
            let mins = Int(acousticOffset) / 60
            let secs = Int(acousticOffset) % 60
            self.sensorStatusText = String(format: "Acoustic Audio Sync: %02d:%02d", mins, secs)
            
            // Align MusicDetector to the acoustic verse timestamp!
            MusicDetector.shared.syncWithAcousticOffset(acousticOffset, detectedTitle: item.title, detectedArtist: item.artist)
        }
    }
    
    public func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        let now = CACurrentMediaTime()
        // If no acoustic match for 8+ seconds, update status
        if now - lastMatchWallTime > 8.0 {
            DispatchQueue.main.async { [weak self] in
                self?.isAcousticallyLocked = false
                self?.sensorStatusText = "Acoustic Audio Sensor: Listening..."
            }
        }
    }
}

