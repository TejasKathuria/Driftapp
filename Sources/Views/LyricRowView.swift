import SwiftUI

public struct LyricRowView: View {
    let line: LyricLine
    let index: Int
    let activeLineIndex: Int?
    let progress: Double
    let fontChoice: LyricFont
    let fontSize: CGFloat
    let theme: DriftColorTheme
    let palette: ArtworkPalette
    let karaokeSweep: Bool
    let wavePhase: Double
    let onSeek: () -> Void
    
    @State private var isHovered: Bool = false
    
    public var body: some View {
        let distance = index - (activeLineIndex ?? 0)
        let isActive = (distance == 0)
        
        // Spatial Choreography ("Lyrics Coming from Here and There")
        let spatialOffset: CGSize = {
            if isActive {
                return .zero
            } else if distance > 0 {
                // Upcoming lines fly in from alternating directions
                if index % 3 == 0 {
                    return CGSize(width: -24, height: 4)
                } else if index % 3 == 1 {
                    return CGSize(width: 24, height: 4)
                } else {
                    return CGSize(width: 0, height: 12)
                }
            } else {
                // Past lines recede upward
                return CGSize(width: 0, height: -4)
            }
        }()
        
        let spatialAngle: Angle = {
            if isActive {
                return .zero
            } else if distance > 0 {
                return (index % 2 == 0) ? .degrees(-2.0) : .degrees(2.0)
            } else {
                return .zero
            }
        }()
        
        let textOpacity: Double = {
            if isActive { return 1.0 }
            if distance > 0 {
                return max(0.25, 0.75 - Double(distance) * 0.18)
            } else {
                return max(0.18, 0.40 - Double(abs(distance)) * 0.12)
            }
        }()
        
        let depthBlur: CGFloat = {
            if isActive { return 0 }
            if distance > 0 {
                return min(CGFloat(distance) * 0.6, 2.5)
            } else {
                return 1.2
            }
        }()
        
        VStack(alignment: .leading, spacing: 6) {
            // Verse Section Badge (e.g. [Chorus], [Verse 2])
            if let section = line.sectionName, !section.isEmpty {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isActive ? palette.accent : Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .scaleEffect(isActive ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isActive)
                    
                    Text(section.uppercased())
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(isActive ? palette.accent : Color.white.opacity(0.45))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(isActive ? palette.primary.opacity(0.22) : Color.white.opacity(0.06))
                        .overlay(
                            Capsule()
                                .stroke(isActive ? palette.accent.opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                )
                .padding(.bottom, 2)
            }
            
            // Lyric Line Content
            Button(action: onSeek) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    if isActive {
                        activeDynamicLine
                    } else {
                        inactiveLine(textOpacity: textOpacity)
                    }
                    
                    Spacer(minLength: 0)
                    
                    if isHovered {
                        Text(line.formattedStartTime)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(palette.accent)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Color.black.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(palette.accent.opacity(0.3), lineWidth: 0.8)
                            )
                            .transition(.opacity)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, isActive ? 12 : 6)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isActive ? Color.white.opacity(0.08) : (isHovered ? Color.white.opacity(0.04) : Color.clear))
        )
        // Spatial fly-in / tilt / scale physics
        .offset(spatialOffset)
        .rotationEffect(spatialAngle)
        .scaleEffect(isActive ? 1.06 : (isHovered ? 1.02 : 1.0))
        .blur(radius: depthBlur)
        .animation(.spring(response: 0.45, dampingFraction: 0.68), value: isActive)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: spatialOffset)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    // MARK: - Active Line with Floating Liquid Wave & Multi-Layer Glow
    
    @ViewBuilder
    private var activeDynamicLine: some View {
        let words = line.text.components(separatedBy: " ")
        
        // Floating Word Wave Layout
        HStack(spacing: 6) {
            ForEach(0..<words.count, id: \.self) { wordIdx in
                let word = words[wordIdx]
                // Floating wave bounce calculation per word
                let wordWave = sin(wavePhase * 2.8 + Double(wordIdx) * 0.65) * 3.2
                
                Text(word)
                    .font(fontChoice.font(size: fontSize, weight: .bold, sectionName: line.sectionName))
                    .foregroundStyle(theme.activeGradient(for: palette))
                    .shadow(color: theme.glowColor(for: palette).opacity(0.75), radius: 12, x: 0, y: 0)
                    .shadow(color: palette.primary.opacity(0.45), radius: 24, x: 0, y: 0)
                    .offset(y: wordWave)
            }
        }
        .multilineTextAlignment(.leading)
    }
    
    // MARK: - Inactive Lines with Depth Focus
    
    @ViewBuilder
    private func inactiveLine(textOpacity: Double) -> some View {
        Text(line.text)
            .font(fontChoice.font(size: fontSize * 0.88, weight: .medium, sectionName: line.sectionName))
            .foregroundStyle(Color.white.opacity(textOpacity))
            .multilineTextAlignment(.leading)
    }
}
