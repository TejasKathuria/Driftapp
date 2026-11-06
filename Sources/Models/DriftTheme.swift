import SwiftUI

public enum DriftDisplayMode: String, CaseIterable, Identifiable {
    case floatingWidget = "Floating Glass HUD"
    case notchIsland = "Notch Dynamic Island"
    case immersiveStudio = "Immersive Studio"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .floatingWidget: return "rectangle.fill.on.rectangle.angled.fill"
        case .notchIsland: return "capsule.portrait.fill"
        case .immersiveStudio: return "sparkles.tv.fill"
        }
    }
    
    public var description: String {
        switch self {
        case .floatingWidget: return "Translucent floating window with animated spatial fly-in lyrics & glowing active verse."
        case .notchIsland: return "Minimalist pill hugging the MacBook notch showing the current verse & waveform."
        case .immersiveStudio: return "Fullscreen cinematic experience with living album-art fluid gradients & kinetic lyrics."
        }
    }
    
    public var shortName: String {
        switch self {
        case .floatingWidget: return "Floating Glass"
        case .notchIsland: return "Notch Island"
        case .immersiveStudio: return "Fullscreen"
        }
    }
}

public enum KineticAnimationStyle: String, CaseIterable, Identifiable {
    case threeSlotReel = "3-Slot Kinetic Reel (CleanShot)"
    case popPosterCanvas = "Pop Kinetic Posters (Banners & Wave)"
    case staircaseCascade = "Staircase Cascade (CleanShot)"
    case soloCinematicStream = "Solo Cinematic Stream (Stranger Things & 3D)"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .threeSlotReel: return "3-Slot Reel"
        case .popPosterCanvas: return "Pop Posters"
        case .staircaseCascade: return "Staircase"
        case .soloCinematicStream: return "Solo Stream"
        }
    }
    
    public var icon: String {
        switch self {
        case .threeSlotReel: return "list.bullet.below.rectangle"
        case .popPosterCanvas: return "ticket.fill"
        case .staircaseCascade: return "stairs"
        case .soloCinematicStream: return "sparkles"
        }
    }
    
    public var description: String {
        switch self {
        case .threeSlotReel:
            return "CleanShot vertical roller: Previous word on top, hero tilted word in center, upcoming word below."
        case .popPosterCanvas:
            return "Pop poster canvas: Solid banner cards, corner musical notes (♪), undulating wave split, and diagonal kicks."
        case .staircaseCascade:
            return "CleanShot diagonal staircase: Cascading step words with bold punchy hero text and retro sparkle sticker."
        case .soloCinematicStream:
            return "Solo kinetic word: Cycles through Stranger Things creeping zoom, 3D somersault, and smoke dissolve."
        }
    }
}

public enum LyricFont: String, CaseIterable, Identifiable {
    case neoCyber = "Neo-Cyber (Display Italic)"
    case rounded = "SF Pro Rounded"
    case editorialSerif = "Editorial Serif (Poetic)"
    case kineticMix = "Adaptive Kinetic Mix"
    case brutalistMono = "Cyber Monospace"
    case standard = "SF Pro System"
    
    public var id: String { rawValue }
    
    public func font(size: CGFloat, weight: Font.Weight = .semibold, sectionName: String? = nil) -> Font {
        switch self {
        case .neoCyber:
            return .system(size: size, weight: .black, design: .default).italic()
        case .rounded:
            return .system(size: size, weight: weight, design: .rounded)
        case .editorialSerif:
            return .system(size: size, weight: weight, design: .serif).italic()
        case .kineticMix:
            let sec = sectionName?.lowercased() ?? ""
            if sec.contains("chorus") || sec.contains("hook") {
                return .system(size: size * 1.08, weight: .black, design: .default).italic()
            } else if sec.contains("bridge") || sec.contains("intro") {
                return .system(size: size, weight: .medium, design: .serif).italic()
            } else {
                return .system(size: size, weight: .bold, design: .rounded)
            }
        case .brutalistMono:
            return .system(size: size * 0.9, weight: .bold, design: .monospaced)
        case .standard:
            return .system(size: size, weight: weight, design: .default)
        }
    }
}

public enum LyricAnimationEffect: String, CaseIterable, Identifiable {
    case cinematicChoreography = "Spatial Drift (From Here & There)"
    case floatingWordWave = "Floating Liquid Wave"
    case karaokePulseGlow = "Karaoke Neon Sweep"
    
    public var id: String { rawValue }
}

public enum DriftColorTheme: String, CaseIterable, Identifiable {
    case dynamicArtwork = "Album Cover Colors (Live)"
    case neonCyber = "Cyberpunk (Magenta & Cyan)"
    case northernLights = "Aurora (Emerald & Teal)"
    case sunsetGlow = "Sunset (Tangerine & Coral)"
    case pureWhite = "Minimalist Diamond"
    
    public var id: String { rawValue }
    
    public func activeGradient(for palette: ArtworkPalette) -> LinearGradient {
        switch self {
        case .dynamicArtwork:
            return LinearGradient(
                colors: [palette.primary, palette.accent],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .neonCyber:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.1, blue: 0.6), Color(red: 0.2, green: 0.8, blue: 1.0)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .northernLights:
            return LinearGradient(
                colors: [Color(red: 0.1, green: 0.9, blue: 0.6), Color(red: 0.2, green: 0.6, blue: 0.9)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .sunsetGlow:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.4, blue: 0.2), Color(red: 1.0, green: 0.1, blue: 0.5)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .pureWhite:
            return LinearGradient(
                colors: [Color.white, Color(white: 0.85)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    public func glowColor(for palette: ArtworkPalette) -> Color {
        switch self {
        case .dynamicArtwork: return palette.accent
        case .neonCyber: return Color(red: 1.0, green: 0.2, blue: 0.7)
        case .northernLights: return Color(red: 0.2, green: 0.9, blue: 0.7)
        case .sunsetGlow: return Color(red: 1.0, green: 0.45, blue: 0.2)
        case .pureWhite: return Color.white.opacity(0.8)
        }
    }
}
