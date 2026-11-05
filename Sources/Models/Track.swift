import Foundation
import SwiftUI

public enum MusicSource: String, CaseIterable, Identifiable {
    case auto = "Auto Detect"
    case spotify = "Spotify"
    case appleMusic = "Apple Music"
    case demo = "Demo Mode"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .auto: return "sparkles"
        case .spotify: return "music.note"
        case .appleMusic: return "apple.logo"
        case .demo: return "play.circle.fill"
        }
    }
}

public struct ArtworkPalette: Equatable {
    public var primary: Color
    public var secondary: Color
    public var accent: Color
    public var backgroundDark: Color
    public var backgroundMid: Color
    
    public init(
        primary: Color = Color(red: 0.95, green: 0.25, blue: 0.55),
        secondary: Color = Color(red: 0.45, green: 0.20, blue: 0.90),
        accent: Color = Color(red: 0.20, green: 0.85, blue: 0.95),
        backgroundDark: Color = Color(red: 0.05, green: 0.04, blue: 0.10),
        backgroundMid: Color = Color(red: 0.15, green: 0.08, blue: 0.25)
    ) {
        self.primary = primary
        self.secondary = secondary
        self.accent = accent
        self.backgroundDark = backgroundDark
        self.backgroundMid = backgroundMid
    }
    
    public var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundDark, backgroundMid, backgroundDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    public var accentGradient: LinearGradient {
        LinearGradient(
            colors: [primary, accent],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

public struct Track: Equatable {
    public var id: String
    public var title: String
    public var artist: String
    public var album: String
    public var duration: TimeInterval
    public var position: TimeInterval
    public var isPlaying: Bool
    public var source: MusicSource
    public var artworkURL: String?
    public var artworkImage: NSImage?
    public var palette: ArtworkPalette
    
    public var accentColor: Color {
        palette.accent
    }
    
    public init(
        id: String = UUID().uuidString,
        title: String = "No Song Playing",
        artist: String = "Open Spotify or Apple Music",
        album: String = "",
        duration: TimeInterval = 0,
        position: TimeInterval = 0,
        isPlaying: Bool = false,
        source: MusicSource = .auto,
        artworkURL: String? = nil,
        artworkImage: NSImage? = nil,
        palette: ArtworkPalette = ArtworkPalette()
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.position = position
        self.isPlaying = isPlaying
        self.source = source
        self.artworkURL = artworkURL
        self.artworkImage = artworkImage
        self.palette = palette
    }
    
    public var formattedPosition: String {
        let minutes = Int(position) / 60
        let seconds = Int(position) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    public var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    public var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(position / duration, 0), 1.0)
    }
}
