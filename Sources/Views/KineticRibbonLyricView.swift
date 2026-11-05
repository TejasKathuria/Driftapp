import SwiftUI

public struct KineticRibbonLyricView: View {
    let line: LyricLine
    let isActive: Bool
    let currentPosition: TimeInterval
    let palette: ArtworkPalette
    let fontChoice: LyricFont
    let bandAngle: Angle
    let wavePhase: Double
    let onSeek: () -> Void
    
    public var body: some View {
        let timedWords = line.timedWords
        
        ZStack {
            // Ribbon Banner Background (Full Width)
            if isActive {
                // Active Glowing Banner (matching the pink-to-cyan illuminated banner in screenshot)
                LinearGradient(
                    colors: [
                        palette.primary.opacity(0.92),
                        palette.primary.opacity(0.85),
                        palette.accent.opacity(0.92)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 120)
                // Soft glow halo, NO outline stroke rectangle!
                .shadow(color: palette.primary.opacity(0.6), radius: 25, x: 0, y: -4)
                .shadow(color: palette.accent.opacity(0.6), radius: 25, x: 0, y: 4)
            } else {
                // Inactive Dark Translucent Slanted Ribbon
                Color.black.opacity(0.62)
                    .background(.ultraThinMaterial.opacity(0.4))
                    .frame(height: 90)
            }
            
            // Words with 3D Flip & Word-After-Word Rotation
            HStack(spacing: isActive ? 18 : 12) {
                ForEach(timedWords) { word in
                    let isWordActive = word.isActive(at: currentPosition)
                    let isWordPassed = word.isPassed(at: currentPosition)
                    
                    wordView(
                        word: word,
                        isWordActive: isWordActive,
                        isWordPassed: isWordPassed,
                        isActiveBand: isActive
                    )
                }
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .rotationEffect(bandAngle)
        .contentShape(Rectangle())
        .onTapGesture {
            onSeek()
        }
    }
    
    // MARK: - Word-After-Word 3D Flip & Rotation Animation
    
    @ViewBuilder
    private func wordView(
        word: TimedWord,
        isWordActive: Bool,
        isWordPassed: Bool,
        isActiveBand: Bool
    ) -> some View {
        let flipAngle: Double = {
            if !isActiveBand { return 0 }
            if isWordActive {
                return 0
            } else if isWordPassed {
                return 0
            } else {
                // Upcoming word in active band is tilted back in 3D
                return -75.0
            }
        }()
        
        let wordScale: CGFloat = {
            if !isActiveBand { return 1.0 }
            if isWordActive { return 1.16 }
            if isWordPassed { return 1.0 }
            return 0.90
        }()
        
        let wordColor: Color = {
            if isActiveBand {
                if isWordActive {
                    return Color.white
                } else if isWordPassed {
                    return Color.white.opacity(0.92)
                } else {
                    return Color.white.opacity(0.45)
                }
            } else {
                // Inactive bands have soft gray/white text
                return Color.white.opacity(0.55)
            }
        }()
        
        let fontSize: CGFloat = isActiveBand ? (isWordActive ? 68 : 60) : 46
        
        Text(word.text)
            .font(fontChoice.font(size: fontSize, weight: .black, sectionName: line.sectionName))
            .foregroundStyle(wordColor)
            // Luminous bloom glow on active word, NO outline box!
            .shadow(
                color: isWordActive ? Color.white.opacity(0.95) : (isActiveBand ? palette.primary.opacity(0.4) : Color.clear),
                radius: isWordActive ? 18 : 4,
                x: 0,
                y: 0
            )
            .shadow(
                color: isWordActive ? palette.accent.opacity(0.8) : Color.clear,
                radius: isWordActive ? 32 : 0,
                x: 0,
                y: 0
            )
            // 3D Flip Animation along X-Axis
            .rotation3DEffect(
                .degrees(flipAngle),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.6
            )
            // Subtle living wave bounce
            .offset(y: isWordActive ? sin(wavePhase * 3.5) * 4.0 : 0)
            .scaleEffect(wordScale)
            .animation(.spring(response: 0.32, dampingFraction: 0.58), value: isWordActive)
    }
}
