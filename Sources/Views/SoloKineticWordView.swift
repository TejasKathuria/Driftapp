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
        
        VStack(spacing: 28) {
            Spacer()
            
            // Section Tag Badge
            if let section = line.sectionName, !section.isEmpty {
                Text(section.uppercased())
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .tracking(2.5)
                    .foregroundStyle(palette.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(palette.primary.opacity(0.3))
                    )
                    .shadow(color: palette.accent.opacity(0.5), radius: 12)
            }
            
            // ONE WORD ON THE SCREEN MOVING WITH ANIMATION
            if let word = activeWord {
                soloWordAnimated(word: word, tilt: tilt)
                    .id(word.id)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 1.32)
                                .combined(with: .opacity)
                                .combined(with: .offset(y: 40)),
                            removal: .scale(scale: 0.78)
                                .combined(with: .opacity)
                                .combined(with: .offset(y: -50))
                        )
                    )
            } else {
                Text(line.text)
                    .font(fontChoice.font(size: 54, weight: .black, sectionName: line.sectionName))
                    .foregroundStyle(Color.white)
            }
            
            // Context Verse Subtitle (Soft & Clean without clutter)
            HStack(spacing: 8) {
                ForEach(timedWords) { w in
                    let isCurrent = (w.id == activeWord?.id)
                    Text(w.text)
                        .font(.system(size: 20, weight: isCurrent ? .bold : .medium, design: .rounded))
                        .foregroundStyle(
                            isCurrent
                                ? palette.accent
                                : Color.white.opacity(0.35)
                        )
                        .scaleEffect(isCurrent ? 1.08 : 1.0)
                        .shadow(color: isCurrent ? palette.accent.opacity(0.8) : Color.clear, radius: 8)
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
    
    // MARK: - Solo Word Kinetic Typography
    
    @ViewBuilder
    private func soloWordAnimated(word: TimedWord, tilt: Angle) -> some View {
        let waveBounce = sin(wavePhase * 3.8) * 6.0
        let waveDrift = cos(wavePhase * 2.2) * 8.0
        
        Text(word.text)
            .font(fontChoice.font(size: 96, weight: .black, sectionName: line.sectionName))
            .tracking(1.0)
            .foregroundStyle(Color.white)
            // Luminous glowing neon shadow from album cover colors, NO outline rectangle!
            .shadow(color: Color.white.opacity(0.9), radius: 18, x: 0, y: 0)
            .shadow(color: palette.primary.opacity(0.85), radius: 36, x: 0, y: 0)
            .shadow(color: palette.accent.opacity(0.65), radius: 55, x: 0, y: 0)
            // 3D Flip & Tumble Rotation
            .rotationEffect(tilt)
            .rotation3DEffect(
                .degrees(sin(wavePhase * 2.0) * 8.0),
                axis: (x: 1, y: 0.3, z: 0),
                perspective: 0.5
            )
            .offset(x: waveDrift, y: waveBounce)
            .animation(.spring(response: 0.28, dampingFraction: 0.55), value: word.id)
    }
    
    // MARK: - Word Resolution with Audio Onset Sync
    
    private func currentActiveWord(words: [TimedWord]) -> TimedWord? {
        guard !words.isEmpty else { return nil }
        
        // Find word where currentPosition falls within its start & end time
        for (i, word) in words.enumerated() {
            // Check acoustic audio onset for early vocal trigger
            if audioSync.isWordTriggered(wordStartTime: word.startTime, currentPosition: currentPosition) {
                // If next word is already triggered by audio onset, advance to next
                if i + 1 < words.count && audioSync.isWordTriggered(wordStartTime: words[i + 1].startTime, currentPosition: currentPosition) {
                    continue
                }
                return word
            }
        }
        
        return words.first
    }
    
    private func organicTilt(for text: String) -> Angle {
        let hash = abs(text.hashValue)
        let angles: [Double] = [-5.5, 4.0, -3.8, 5.0, -6.0, 3.5, -4.2, 4.8]
        return .degrees(angles[hash % angles.count])
    }
}
