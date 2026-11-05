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
    
    // High-resolution clock
    private var pollTimer: Timer?
    private var highFreqTimer: Timer?
    private var lastSampleRealTime: TimeInterval = 0
    private var lastReportedPosition: TimeInterval = 0
    
    // Demo mode state
    private var demoIndex: Int = 0
    
    public init() {
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
        let delta = now - lastSampleRealTime
        if delta > 0 && delta < 2.0 {
            let interpolated = lastReportedPosition + delta
            if currentTrack.duration > 0 {
                currentTrack.position = min(interpolated, currentTrack.duration)
            } else {
                currentTrack.position = interpolated
            }
        }
    }
    
    public func pollActivePlayer() {
        if preferredSource == .demo {
            return
        }
        
        // Try Spotify first if preferred or auto
        if preferredSource == .auto || preferredSource == .spotify {
            if let spotifyInfo = querySpotify() {
                updateWithTrackInfo(spotifyInfo, source: .spotify)
                return
            }
        }
        
        // Try Apple Music
        if preferredSource == .auto || preferredSource == .appleMusic {
            if let musicInfo = queryAppleMusic() {
                updateWithTrackInfo(musicInfo, source: .appleMusic)
                return
            }
        }
        
        // If nothing playing and was auto, keep last known or fallback to demo if uninitialized
        if currentTrack.title == "No Song Playing" && preferredSource == .auto {
            // Load demo by default so the user sees a gorgeous live display immediately
            loadDemoTrack(index: 0, autoPlay: false)
        }
    }
    
    private func updateWithTrackInfo(_ info: PlayerInfo, source: MusicSource) {
        let now = CACurrentMediaTime()
        lastSampleRealTime = now
        
        // Auto latency compensation: Apple Music has ~0.38s AppleScript IPC lag relative to speaker audio
        let latencyCompensation = (source == .appleMusic) ? 0.38 : 0.0
        let compensatedPosition = info.position + latencyCompensation
        lastReportedPosition = compensatedPosition
        
        let changedSong = currentTrack.title != info.title || currentTrack.artist != info.artist
        
        var currentPalette = currentTrack.palette
        if changedSong {
            currentPalette = ColorExtractor.defaultPaletteForDemo(title: info.title, artist: info.artist)
        }
        
        currentTrack = Track(
            id: "\(info.artist)-\(info.title)",
            title: info.title,
            artist: info.artist,
            album: info.album,
            duration: info.duration,
            position: compensatedPosition,
            isPlaying: info.isPlaying,
            source: source,
            artworkURL: info.artworkURL,
            artworkImage: changedSong ? nil : currentTrack.artworkImage,
            palette: currentPalette
        )
        
        if changedSong {
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
                    return (isP as string) & "|||" & (pos as string) & "|||" & tName & "|||" & tArtist & "|||" & tAlbum & "|||" & (dur as string) & "|||" & art
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
                    return (isP as string) & "|||" & (pos as string) & "|||" & tName & "|||" & tArtist & "|||" & tAlbum & "|||" & (dur as string) & "|||"
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
        let art = parts.count > 6 ? parts[6] : nil
        
        return PlayerInfo(
            isPlaying: isPlaying,
            position: pos,
            title: title,
            artist: artist,
            album: album,
            duration: dur,
            artworkURL: art?.isEmpty == false ? art : nil,
            artworkImage: nil
        )
    }
    
    // MARK: - Playback Control Commands
    
    public func togglePlayPause() {
        if preferredSource == .demo {
            currentTrack.isPlaying.toggle()
            lastSampleRealTime = CACurrentMediaTime()
            lastReportedPosition = currentTrack.position
            return
        }
        
        let target = (currentTrack.source == .spotify) ? "Spotify" : "Music"
        let script = "tell application \"\(target)\" to playpause"
        NSAppleScript(source: script)?.executeAndReturnError(nil)
        currentTrack.isPlaying.toggle()
        lastSampleRealTime = CACurrentMediaTime()
        lastReportedPosition = currentTrack.position
    }
    
    public func seek(to seconds: Double) {
        if preferredSource == .demo {
            currentTrack.position = seconds
            lastSampleRealTime = CACurrentMediaTime()
            lastReportedPosition = seconds
            return
        }
        
        let target = (currentTrack.source == .spotify) ? "Spotify" : "Music"
        let script = "tell application \"\(target)\" to set player position to \(seconds)"
        NSAppleScript(source: script)?.executeAndReturnError(nil)
        currentTrack.position = seconds
        lastSampleRealTime = CACurrentMediaTime()
        lastReportedPosition = seconds
    }
    
    public func nextTrack() {
        if preferredSource == .demo {
            demoIndex = (demoIndex + 1) % BuiltInDemoLyrics.songs.count
            loadDemoTrack(index: demoIndex, autoPlay: true)
            return
        }
        let target = (currentTrack.source == .spotify) ? "Spotify" : "Music"
        let script = "tell application \"\(target)\" to next track"
        NSAppleScript(source: script)?.executeAndReturnError(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.pollActivePlayer()
        }
    }
    
    public func previousTrack() {
        if preferredSource == .demo {
            demoIndex = (demoIndex - 1 + BuiltInDemoLyrics.songs.count) % BuiltInDemoLyrics.songs.count
            loadDemoTrack(index: demoIndex, autoPlay: true)
            return
        }
        let target = (currentTrack.source == .spotify) ? "Spotify" : "Music"
        let script = "tell application \"\(target)\" to previous track"
        NSAppleScript(source: script)?.executeAndReturnError(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
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
        
        lastSampleRealTime = CACurrentMediaTime()
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
