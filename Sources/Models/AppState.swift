import SwiftUI
import Combine

public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    @Published public var displayMode: DriftDisplayMode = .floatingWidget
    @Published public var fontChoice: LyricFont = .rounded
    @Published public var fontSize: CGFloat = 26
    @Published public var colorTheme: DriftColorTheme = .dynamicArtwork
    @Published public var backgroundOpacity: Double = 0.75
    @Published public var isAlwaysOnTop: Bool = true
    @Published public var isClickThrough: Bool = false
    @Published public var showWaveform: Bool = true
    @Published public var karaokeProgressSweep: Bool = true
    @Published public var autoHideWhenPaused: Bool = false
    
    // Lyrics & active verse state
    @Published public var lyrics: ParsedLyrics? = nil
    @Published public var activeLineIndex: Int? = nil
    @Published public var isLoadingLyrics: Bool = false
    @Published public var currentVerseName: String? = nil
    
    // Audio Visualizer bars
    @Published public var spectrumLevels: [CGFloat] = Array(repeating: 0.1, count: 24)
    
    private var cancellables = Set<AnyCancellable>()
    private var lastTrackId: String = ""
    private var visualizerTimer: Timer?
    
    public init() {
        setupSubscriptions()
        startVisualizerSimulation()
    }
    
    private func setupSubscriptions() {
        let detector = MusicDetector.shared
        
        // Listen to track changes to fetch lyrics
        detector.$currentTrack
            .receive(on: DispatchQueue.main)
            .sink { [weak self] track in
                self?.handleTrackUpdate(track)
            }
            .store(in: &cancellables)
    }
    
    private func handleTrackUpdate(_ track: Track) {
        let adjustedTime = track.position + MusicDetector.shared.syncOffset
        
        // Check if track changed
        if track.id != lastTrackId {
            lastTrackId = track.id
            fetchLyrics(for: track)
        }
        
        // Update active line and verse
        if let currentLyrics = lyrics {
            let index = currentLyrics.activeLineIndex(for: adjustedTime)
            if index != activeLineIndex {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    self.activeLineIndex = index
                    if let idx = index, idx < currentLyrics.lines.count {
                        self.currentVerseName = currentLyrics.lines[idx].sectionName
                    }
                }
            }
        }
    }
    
    public func fetchLyrics(for track: Track) {
        guard !track.title.isEmpty && track.title != "No Song Playing" else {
            self.lyrics = nil
            self.activeLineIndex = nil
            return
        }
        
        self.isLoadingLyrics = true
        
        Task {
            let result = await LyricsService.shared.fetchLyrics(for: track)
            await MainActor.run {
                self.lyrics = result
                self.isLoadingLyrics = false
                let adjustedTime = track.position + MusicDetector.shared.syncOffset
                self.activeLineIndex = result?.activeLineIndex(for: adjustedTime)
                if let idx = self.activeLineIndex, let lines = result?.lines, idx < lines.count {
                    self.currentVerseName = lines[idx].sectionName
                }
            }
        }
    }
    
    private func startVisualizerSimulation() {
        visualizerTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let isPlaying = MusicDetector.shared.currentTrack.isPlaying
            
            if isPlaying {
                self.spectrumLevels = (0..<24).map { i in
                    let base = sin(Double(i) * 0.5 + CACurrentMediaTime() * 4.0) * 0.5 + 0.5
                    let randomJitter = CGFloat.random(in: 0.2...0.95)
                    return CGFloat(base) * randomJitter
                }
            } else {
                self.spectrumLevels = Array(repeating: 0.08, count: 24)
            }
        }
    }
}

