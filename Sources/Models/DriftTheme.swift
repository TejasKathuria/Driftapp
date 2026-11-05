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
        case .floatingWidget: return "Translucent floating window with smooth auto-scroll & glowing active verse."
        case .notchIsland: return "Minimalist pill hugging the MacBook notch showing the current verse & waveform."
        case .immersiveStudio: return "Fullscreen cinematic experience with living fluid gradients & dynamic focus."
        }
    }
}

public enum LyricFont: String, CaseIterable, Identifiable {
    case rounded = "SF Pro Rounded"
    case standard = "SF Pro System"
    case serif = "New York Serif"
    case mono = "SF Mono"
    
    public var id: String { rawValue }
    
    public func font(size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        switch self {
        case .rounded:
            return .system(size: size, weight: weight, design: .rounded)
        case .standard:
            return .system(size: size, weight: weight, design: .default)
        case .serif:
            return .system(size: size, weight: weight, design: .serif)
        case .mono:
            return .system(size: size, weight: weight, design: .monospaced)
        }
    }
}

public enum DriftColorTheme: String, CaseIterable, Identifiable {
    case dynamicArtwork = "Dynamic Artwork"
    case neonCyber = "Cyberpunk (Magenta & Cyan)"
    case northernLights = "Aurora (Emerald & Teal)"
    case sunsetGlow = "Sunset (Tangerine & Coral)"
    case pureWhite = "Minimalist Diamond"
    
    public var id: String { rawValue }
    
    public func activeGradient(for trackAccent: Color) -> LinearGradient {
        switch self {
        case .dynamicArtwork:
            return LinearGradient(
                colors: [trackAccent, trackAccent.opacity(0.8)],
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
                colors: [Color.white, Color(white: 0.9)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    public func glowColor(for trackAccent: Color) -> Color {
        switch self {
        case .dynamicArtwork: return trackAccent
        case .neonCyber: return Color(red: 1.0, green: 0.2, blue: 0.7)
        case .northernLights: return Color(red: 0.2, green: 0.9, blue: 0.7)
        case .sunsetGlow: return Color(red: 1.0, green: 0.45, blue: 0.2)
        case .pureWhite: return Color.white.opacity(0.8)
        }
    }
}
