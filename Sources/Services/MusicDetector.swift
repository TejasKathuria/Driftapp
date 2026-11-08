import Foundation
import Combine
import SwiftUI
import AppKit

public final class MusicDetector: ObservableObject {
    public static let shared = MusicDetector()
    
    @Published public var currentTrack: Track = Track()
    @Published public var preferredSource: MusicSource = .auto
    @Published public var isSearchingLyrics: Bool = false
    @Published public var syncOffset: Double = 0.0 // Manual offset in seconds
    @Published public var isInteractivityLocked: Bool = false // Click-through mode
    
    // High-resolution monotonic anchor clock
    private var pollTimer: Timer?
    private var highFreqTimer: Timer?
    private var anchorPosition: TimeInterval = 0
    private var anchorMediaTime: TimeInterval = 0
    private var lastSampleRealTime: TimeInterval = 0
    private var lastReportedPosition: TimeInterval = 0
    
    // Demo mode state
    private var demoIndex: Int = 0
    
    public init() {
        anchorMediaTime = CACurrentMediaTime()
        startTracking()
    }
    
    public func startTracking() {
        stopTracking()
        
        // 1s poll to query player state from Spotify / Music.app
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.pollActivePlayer()
        }
        
        // 50ms timer for continuous sub-millisecond smooth interpolation
        highFreqTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.interpolatePlaybackTime()
        }
        
        // Initial poll
        pollActivePlayer()
    }
    
    public func stopTracking() {
        pollTimer?.invalidate()
        pollTimer = nil
        highFreqTimer?.invalidate()
        highFreqTimer = nil
    }
    
    private func interpolatePlaybackTime() {
        guard currentTrack.isPlaying else { return }
        let now = CACurrentMediaTime()
        let elapsed = now - anchorMediaTime
        if elapsed >= 0 && elapsed < 7200.0 {
            let interpolated = anchorPosition + elapsed
            if currentTrack.duration > 0 {
                currentTrack.position = min(interpolated, currentTrack.duration)
            } else {
                currentTrack.position = interpolated
            }
            lastReportedPosition = currentTrack.position
            lastSampleRealTime = now
        }
    }
    
    public func pollActivePlayer() {
        if preferredSource == .demo {
            return
        }
        
        let spotifyInfo = (preferredSource == .auto || preferredSource == .spotify) ? querySpotify() : nil
        let musicInfo = (preferredSource == .auto || preferredSource == .appleMusic) ? queryAppleMusic() : nil
        
        // Priority 1: Which player is ACTUALLY PLAYING right now?
        if let sInfo = spotifyInfo, sInfo.isPlaying {
            updateWithTrackInfo(sInfo, source: .spotify)
            return
        }
        if let mInfo = musicInfo, mInfo.isPlaying {
            updateWithTrackInfo(mInfo, source: .appleMusic)
            return
        }
        
        // Priority 2: If neither is playing, pick preferred source or whichever has an active track
        if preferredSource == .spotify, let sInfo = spotifyInfo {
            updateWithTrackInfo(sInfo, source: .spotify)
            return
        }
        if preferredSource == .appleMusic, let mInfo = musicInfo {
            updateWithTrackInfo(mInfo, source: .appleMusic)
            return
        }
        if let sInfo = spotifyInfo, !sInfo.title.isEmpty {
            updateWithTrackInfo(sInfo, source: .spotify)
            return
        }
        if let mInfo = musicInfo, !mInfo.title.isEmpty {
            updateWithTrackInfo(mInfo, source: .appleMusic)
            return
        }
        
        // If nothing playing and was auto, keep last known or fallback to demo if uninitialized
        if currentTrack.title == "No Song Playing" && preferredSource == .auto {
            loadDemoTrack(index: 0, autoPlay: false)
        }
    }
    
    private func updateWithTrackInfo(_ info: PlayerInfo, source: MusicSource) {
        let now = CACurrentMediaTime()
        let changedSong = currentTrack.title != info.title || currentTrack.artist != info.artist
        
        if changedSong {
            anchorPosition = info.position
            anchorMediaTime = now
            lastReportedPosition = info.position
            lastSampleRealTime = now
            
            let currentPalette = ColorExtractor.defaultPaletteForDemo(title: info.title, artist: info.artist)
            currentTrack = Track(
                id: "\(info.artist)-\(info.title)",
                title: info.title,
                artist: info.artist,
                album: info.album,
                duration: info.duration,
                position: info.position,
                isPlaying: info.isPlaying,
                source: source,
                artworkURL: info.artworkURL,
                artworkImage: nil,
                palette: currentPalette,
                embeddedLyrics: info.lyrics
            )
            
            let trackToFetch = currentTrack
            Task {
                let (data, palette) = await ArtworkService.shared.fetchArtworkDataAndPalette(for: trackToFetch)
                await MainActor.run {
                    if self.currentTrack.id == trackToFetch.id {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            self.currentTrack.artworkImage = data.flatMap { NSImage(data: $0) }
                            self.currentTrack.palette = palette
                        }
                    }
                }
            }
            return
        }
        
        // Handle playback state transitions (play / pause)
        if currentTrack.isPlaying != info.isPlaying {
            currentTrack.isPlaying = info.isPlaying
            anchorPosition = info.position
            anchorMediaTime = now
            currentTrack.position = info.position
            lastReportedPosition = info.position
            lastSampleRealTime = now
            return
        }
        
        if info.isPlaying {
            // Anchor Monotonic Clock:
            // Calculate what our continuous hardware-interpolated position should be right now
            let expectedPosition = anchorPosition + (now - anchorMediaTime)
            let drift = info.position - expectedPosition
            
            // If drift > 0.85s, the user actively sought or scrubbed in the player: snap immediately!
            if abs(drift) > 0.85 {
                anchorPosition = info.position
                anchorMediaTime = now
                currentTrack.position = info.position
                lastReportedPosition = info.position
                lastSampleRealTime = now
            } else if abs(drift) > 0.20 {
                // Micro-slew: adjust anchor very gently without jerking or micro-jumping
                anchorPosition += drift * 0.05
            }
            
            if currentTrack.duration != info.duration && info.duration > 0 {
                currentTrack.duration = info.duration
            }
        } else {
            // Stationary when paused
            anchorPosition = info.position
            anchorMediaTime = now
            currentTrack.position = info.position
            lastReportedPosition = info.position
            lastSampleRealTime = now
        }
    }
    
    // MARK: - Acoustic Audio Sensor Steering
    
    public func syncWithAcousticOffset(_ acousticOffset: TimeInterval, detectedTitle: String?, detectedArtist: String?) {
        guard acousticOffset > 0 else { return }
        
        // If Spotify or Apple Music is actively playing, the local player clock is authoritative!
        // ShazamKit acoustic matching must NEVER hijack or fight the player clock.
        if currentTrack.isPlaying && (currentTrack.source == .spotify || currentTrack.source == .appleMusic) {
            return
        }
        
        // If no track is actively playing, use the acoustically detected song!
        if currentTrack.title == "No Song Playing", let title = detectedTitle, !title.isEmpty {
            let artist = detectedArtist ?? "Unknown Artist"
            let palette = ColorExtractor.defaultPaletteForDemo(title: title, artist: artist)
            currentTrack = Track(
                id: "\(artist)-\(title)",
                title: title,
                artist: artist,
                album: "",
                duration: 240,
                position: acousticOffset,
                isPlaying: true,
                source: .auto,
                palette: palette
            )
            anchorPosition = acousticOffset
            anchorMediaTime = CACurrentMediaTime()
            AppState.shared.fetchLyrics(for: currentTrack)
            return
        }
        
        let diff = acousticOffset - currentTrack.position
        
        // Only adjust if discrepancy is major (>= 2.5s) in auto mode
        if abs(diff) >= 2.5 {
            anchorPosition = acousticOffset
            anchorMediaTime = CACurrentMediaTime()
            lastReportedPosition = acousticOffset
            lastSampleRealTime = anchorMediaTime
            currentTrack.position = acousticOffset
        }
    }
    
    // MARK: - AppleScript Querying
    
    private struct PlayerInfo {
        let isPlaying: Bool
        let position: Double
        let title: String
        let artist: String
        let album: String
        let duration: Double
        let artworkURL: String?
        let artworkImage: NSImage?
        let lyrics: String?
    }
    
    private func querySpotify() -> PlayerInfo? {
        let scriptSource = """
        if application "Spotify" is running then
            tell application "Spotify"
                if player state is playing or player state is paused then
                    set isP to (player state is playing)
                    set pos to player position
                    set tName to name of current track
                    set tArtist to artist of current track
                    set tAlbum to album of current track
                    set dur to (duration of current track) / 1000.0
                    set art to ""
                    try
                        set art to artwork url of current track
                    end try
                    return (isP as string) & "|||" & (pos as string) & "|||" & tName & "|||" & tArtist & "|||" & tAlbum & "|||" & (dur as string) & "|||" & art & "|||" & ""
                end if
            end tell
        end if
        return ""
        """
        return executeScript(scriptSource)
    }
    
    private func queryAppleMusic() -> PlayerInfo? {
        let scriptSource = """
        if application "Music" is running then
            tell application "Music"
                if player state is playing or player state is paused then
                    set isP to (player state is playing)
                    set pos to player position
                    set tName to name of current track
                    set tArtist to artist of current track
                    set tAlbum to album of current track
                    set dur to duration of current track
                    set lyr to ""
                    try
                        set lyr to lyrics of current track
                    end try
                    return (isP as string) & "|||" & (pos as string) & "|||" & tName & "|||" & tArtist & "|||" & tAlbum & "|||" & (dur as string) & "|||" & "" & "|||" & lyr
                end if
            end tell
        end if
        return ""
        """
        return executeScript(scriptSource)
    }
    
    private func executeScript(_ script: String) -> PlayerInfo? {
        guard let appleScript = NSAppleScript(source: script) else { return nil }
        var errorDict: NSDictionary?
        let result = appleScript.executeAndReturnError(&errorDict)
        if errorDict != nil {
            return nil
        }
        
        guard let stringVal = result.stringValue, !stringVal.isEmpty else { return nil }
        let parts = stringVal.components(separatedBy: "|||")
        guard parts.count >= 6 else { return nil }
        
        let isPlaying = parts[0].lowercased() == "true"
        let pos = Double(parts[1]) ?? 0
        let title = parts[2]
        let artist = parts[3]
        let album = parts[4]
        let dur = Double(parts[5]) ?? 0
        let art = parts.count > 6 && !parts[6].isEmpty ? parts[6] : nil
        let lyr = parts.count > 7 ? parts.suffix(from: 7).joined(separator: "|||").trimmingCharacters(in: .whitespacesAndNewlines) : nil
        
        return PlayerInfo(
            isPlaying: isPlaying,
            position: pos,
            title: title,
            artist: artist,
            album: album,
            duration: dur,
            artworkURL: art,
            artworkImage: nil,
            lyrics: (lyr?.isEmpty == false) ? lyr : nil
        )
    }
    
    // MARK: - Playback Control Commands
    
    private var activePlayerTarget: String {
        if currentTrack.source == .spotify { return "Spotify" }
        if currentTrack.source == .appleMusic { return "Music" }
        if !NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client").isEmpty {
            return "Spotify"
        }
        return "Music"
    }
    
    public func togglePlayPause() {
        let now = CACurrentMediaTime()
        currentTrack.isPlaying.toggle()
        anchorPosition = currentTrack.position
        anchorMediaTime = now
        lastSampleRealTime = now
        lastReportedPosition = currentTrack.position
        
        if preferredSource == .demo {
            return
        }
        
        let target = activePlayerTarget
        let script = "tell application \"\(target)\" to playpause"
        DispatchQueue.global(qos: .userInitiated).async {
            NSAppleScript(source: script)?.executeAndReturnError(nil)
        }
    }
    
    public func seek(to seconds: Double) {
        let now = CACurrentMediaTime()
        currentTrack.position = seconds
        anchorPosition = seconds
        anchorMediaTime = now
        lastSampleRealTime = now
        lastReportedPosition = seconds
        
        if preferredSource == .demo {
            return
        }
        
        let target = activePlayerTarget
        let script = "tell application \"\(target)\" to set player position to \(seconds)"
        DispatchQueue.global(qos: .userInitiated).async {
            NSAppleScript(source: script)?.executeAndReturnError(nil)
        }
    }
    
    public func nextTrack() {
        if preferredSource == .demo {
            demoIndex = (demoIndex + 1) % BuiltInDemoLyrics.songs.count
            loadDemoTrack(index: demoIndex, autoPlay: true)
            return
        }
        let target = activePlayerTarget
        let script = "tell application \"\(target)\" to next track"
        DispatchQueue.global(qos: .userInitiated).async {
            NSAppleScript(source: script)?.executeAndReturnError(nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.pollActivePlayer()
        }
    }
    
    public func previousTrack() {
        if preferredSource == .demo {
            demoIndex = (demoIndex - 1 + BuiltInDemoLyrics.songs.count) % BuiltInDemoLyrics.songs.count
            loadDemoTrack(index: demoIndex, autoPlay: true)
            return
        }
        let target = activePlayerTarget
        let script = "tell application \"\(target)\" to previous track"
        DispatchQueue.global(qos: .userInitiated).async {
            NSAppleScript(source: script)?.executeAndReturnError(nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.pollActivePlayer()
        }
    }
    
    // MARK: - Demo Track Simulation
    
    public func loadDemoTrack(index: Int, autoPlay: Bool = false) {
        guard index >= 0 && index < BuiltInDemoLyrics.songs.count else { return }
        let demo = BuiltInDemoLyrics.songs[index]
        demoIndex = index
        
        let durations: [Double] = [200, 355, 242, 390]
        let dur = index < durations.count ? durations[index] : 210.0
        
        let now = CACurrentMediaTime()
        anchorPosition = 0
        anchorMediaTime = now
        lastSampleRealTime = now
        lastReportedPosition = 0
        
        let palette = ColorExtractor.defaultPaletteForDemo(title: demo.title, artist: demo.artist)
        
        currentTrack = Track(
            id: "demo-\(demo.title)",
            title: demo.title,
            artist: demo.artist,
            album: "Hits & Classics",
            duration: dur,
            position: 0,
            isPlaying: autoPlay,
            source: .demo,
            artworkURL: nil,
            artworkImage: nil,
            palette: palette
        )
    }
    
    private func generatePalette(for text: String) -> SwiftUI.Color {
        let hash = abs(text.hashValue)
        let hues: [Double] = [0.95, 0.60, 0.45, 0.12, 0.78, 0.55] // Rose, Blue, Mint, Amber, Violet, Cyan
        let hue = hues[hash % hues.count]
        return SwiftUI.Color(hue: hue, saturation: 0.85, brightness: 0.98, opacity: 1.0)
    }
}
