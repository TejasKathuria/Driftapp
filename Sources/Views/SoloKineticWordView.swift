import SwiftUI

public struct SoloKineticWordView: View {
    let line: LyricLine
    let currentPosition: TimeInterval
    let palette: ArtworkPalette
    let fontChoice: LyricFont
    let wavePhase: Double
    let onSeek: () -> Void
    
    @ObservedObject var audioSync = AudioSyncEngine.shared
    
    public var body: some View {
        let timedWords = line.timedWords
        let activeWord = currentActiveWord(words: timedWords)
        let tilt = organicTilt(for: activeWord?.text ?? "")
        
        VStack(spacing: 32) {
            Spacer()
            
            // Section Tag Badge (e.g. CHORUS, VERSE)
            if let section = line.sectionName, !section.isEmpty {
                Text(section.uppercased())
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .tracking(3.0)
                    .foregroundStyle(palette.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(palette.primary.opacity(0.35))
                    )
                    .shadow(color: palette.accent.opacity(0.6), radius: 15)
                    .transition(.opacity)
            }
            
            // SOLO KINETIC WORD WITH SOUL & CINEMATIC ZOOM
            ZStack {
                if let word = activeWord {
                    ZStack {
                        // 1. "Soul Echo" Aura Layer (Macro expanding depth trail)
                        Text(word.text)
                            .font(fontChoice.font(size: 108, weight: .black, sectionName: line.sectionName))
                            .tracking(2.5)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [palette.primary.opacity(0.7), palette.accent.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blur(radius: 24)
                            .scaleEffect(1.0 + CGFloat(sin(wavePhase * 2.4) * 0.25 + 0.25))
                            .opacity(0.45)
                        
                        // 2. Core Hero Word (Cinematic Zoom & 3D Depth)
                        Text(word.text)
                            .font(fontChoice.font(size: 104, weight: .black, sectionName: line.sectionName))
                            .tracking(1.5 + sin(wavePhase * 2.2) * 1.5)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0.95), palette.accent.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            // Multi-layer P3 wide-color radiant glow, NO outline boxes!
                            .shadow(color: Color.white.opacity(0.95), radius: 14, x: 0, y: 0)
                            .shadow(color: palette.primary.opacity(0.85), radius: 35, x: 0, y: 0)
                            .shadow(color: palette.accent.opacity(0.65), radius: CGFloat(50 + audioSync.currentRMS * 40), x: 0, y: 0)
                            // 3D Parallax & Organic Tumble
                            .rotationEffect(tilt + .degrees(sin(wavePhase * 1.6) * 2.0))
                            .rotation3DEffect(
                                .degrees(sin(wavePhase * 2.0) * 8.0),
                                axis: (x: 1, y: 0.25, z: 0),
                                perspective: 0.5
                            )
                            // Cinematic breathing zoom
                            .scaleEffect(1.0 + CGFloat(sin(wavePhase * 2.8) * 0.08))
                            .offset(
                                x: cos(wavePhase * 2.0) * 8.0,
                                y: sin(wavePhase * 3.4) * 6.0
                            )
                    }
                    .id(word.id)
                    // Cinematic Zoom Transition: Rushes in from deep core, zooms out into space on exit!
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.35)
                                .combined(with: .opacity)
                                .combined(with: .offset(y: 35)),
                            removal: .scale(scale: 1.85)
                                .combined(with: .opacity)
                                .combined(with: .offset(y: -40))
                        )
                    )
                } else {
                    // Musical interlude / breathing stardust dots before vocals begin
                    HStack(spacing: 16) {
                        ForEach(0..<3, id: \.self) { dot in
                            Circle()
                                .fill(palette.accent.opacity(0.85))
                                .frame(width: 14, height: 14)
                                .shadow(color: palette.accent.opacity(0.8), radius: 12)
                                .scaleEffect(sin(wavePhase * 3.5 + Double(dot) * 0.8) * 0.35 + 0.85)
                        }
                    }
                    .frame(height: 140)
                }
            }
            .frame(height: 180)
            .animation(.spring(response: 0.44, dampingFraction: 0.65), value: activeWord?.id)
            
            // Context Verse Subtitle (Soulful, Minimal & Clean)
            HStack(spacing: 8) {
                ForEach(timedWords) { w in
                    let isCurrent = (w.id == activeWord?.id)
                    Text(w.text)
                        .font(.system(size: 21, weight: isCurrent ? .black : .medium, design: .rounded))
                        .foregroundStyle(
                            isCurrent
                                ? palette.accent
                                : Color.white.opacity(0.32)
                        )
                        .scaleEffect(isCurrent ? 1.10 : 1.0)
                        .shadow(color: isCurrent ? palette.accent.opacity(0.85) : Color.clear, radius: 10)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCurrent)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSeek()
        }
    }
    
    // MARK: - Word Resolution with Audio Onset Sync
    
    private func currentActiveWord(words: [TimedWord]) -> TimedWord? {
        guard !words.isEmpty else { return nil }
        
        // Before the line's vocals start (e.g. musical intro/pause)
        if currentPosition < line.startTime - 0.25 {
            return nil
        }
        
        // Find word in real-time matching computer audio and cadence
        for (i, word) in words.enumerated() {
            if audioSync.isWordTriggered(wordStartTime: word.startTime, currentPosition: currentPosition) {
                // If the next word is already triggered by sound/time, continue to next
                if i + 1 < words.count && audioSync.isWordTriggered(wordStartTime: words[i + 1].startTime, currentPosition: currentPosition) {
                    continue
                }
                return word
            }
        }
        
        return words.last
    }
    
    private func organicTilt(for text: String) -> Angle {
        let hash = abs(text.hashValue)
        let angles: [Double] = [-5.0, 3.8, -3.5, 4.5, -5.5, 3.2, -4.0, 4.2]
        return .degrees(angles[hash % angles.count])
    }
}
