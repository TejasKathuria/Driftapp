import SwiftUI

public struct SoloKineticWordView: View {
    let line: LyricLine
    let currentPosition: TimeInterval
    let palette: ArtworkPalette
    let fontChoice: LyricFont
    let wavePhase: Double
    let onSeek: () -> Void
    
    @ObservedObject var audioSync = AudioSyncEngine.shared
    @ObservedObject var acousticMatcher = AcousticVerseMatcher.shared
    
    public var body: some View {
        let timedWords = line.timedWords
        let activeWord = currentActiveWord(words: timedWords)
        let wordIndex = activeWord?.id ?? 0
        let variation = wordIndex % 4
        
        VStack {
            Spacer()
            
            // Section Tag Badge (Minimal & Floating)
            if let section = line.sectionName, !section.isEmpty {
                Text(section.uppercased())
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(3.5)
                    .foregroundStyle(palette.accent)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(palette.primary.opacity(0.35))
                    )
                    .shadow(color: palette.accent.opacity(0.6), radius: 15)
                    .padding(.bottom, 24)
                    .transition(.opacity)
            }
            
            // SOLO KINETIC WORD - PURE, MASSIVE & VARIED ANIMATIONS
            ZStack {
                if let word = activeWord {
                    Group {
                        switch variation {
                        case 0:
                            // VARIATION 0: 🌌 Cosmic Hyper-Zoom (Rushes in, kerning blooms, zooms out to space)
                            cosmicZoomWord(word: word)
                                .transition(
                                    .asymmetric(
                                        insertion: .scale(scale: 0.2)
                                            .combined(with: .opacity)
                                            .combined(with: .offset(y: 30)),
                                        removal: .scale(scale: 2.8)
                                            .combined(with: .opacity)
                                            .combined(with: .offset(y: -40))
                                    )
                                )
                        case 1:
                            // VARIATION 1: 🌪️ 3D Vertical Tumbler (Somersault flip on X-Axis & ground slam)
                            verticalTumbleWord(word: word)
                                .transition(
                                    .asymmetric(
                                        insertion: .scale(scale: 1.45)
                                            .combined(with: .opacity)
                                            .combined(with: .offset(y: -80)),
                                        removal: .scale(scale: 0.6)
                                            .combined(with: .opacity)
                                            .combined(with: .offset(y: 80))
                                    )
                                )
                        case 2:
                            // VARIATION 2: ⚡ Kinetic Horizontal Barrel Roll (Spins in on Y-Axis with side momentum)
                            horizontalRollWord(word: word)
                                .transition(
                                    .asymmetric(
                                        insertion: .scale(scale: 0.75)
                                            .combined(with: .opacity)
                                            .combined(with: .offset(x: -120)),
                                        removal: .scale(scale: 1.3)
                                            .combined(with: .opacity)
                                            .combined(with: .offset(x: 140))
                                    )
                                )
                        default:
                            // VARIATION 3: 💥 Chromatic Aberration Slam (Impact bounce with dual neon ghost trails)
                            chromaticSlamWord(word: word)
                                .transition(
                                    .asymmetric(
                                        insertion: .scale(scale: 1.5)
                                            .combined(with: .opacity),
                                        removal: .scale(scale: 0.4)
                                            .combined(with: .opacity)
                                            .combined(with: .offset(y: -50))
                                    )
                                )
                        }
                    }
                    .id(word.id)
                } else {
                    // Musical interlude / breathing stardust dots before vocals begin
                    HStack(spacing: 18) {
                        ForEach(0..<3, id: \.self) { dot in
                            Circle()
                                .fill(palette.accent.opacity(0.85))
                                .frame(width: 16, height: 16)
                                .shadow(color: palette.accent.opacity(0.8), radius: 15)
                                .scaleEffect(sin(wavePhase * 3.5 + Double(dot) * 0.8) * 0.35 + 0.85)
                        }
                    }
                    .frame(height: 180)
                }
            }
            .frame(height: 240)
            .animation(.spring(response: 0.42, dampingFraction: 0.64), value: activeWord?.id)
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSeek()
        }
    }
    
    // MARK: - Dynamic Text Size Calculation
    
    private func dynamicFontSize(for text: String) -> CGFloat {
        if text.count <= 3 {
            return 160 // Short words: Massive presence!
        } else if text.count <= 6 {
            return 145 // Medium words
        } else if text.count <= 10 {
            return 125 // Longer words
        } else {
            return 105 // Extended compound words
        }
    }
    
    // MARK: - Variation 0: Cosmic Hyper-Zoom
    
    @ViewBuilder
    private func cosmicZoomWord(word: TimedWord) -> some View {
        let size = dynamicFontSize(for: word.text)
        let tilt = organicTilt(for: word.text, base: -4.5)
        
        ZStack {
            // Expanding Ethereal Depth Echo
            Text(word.text)
                .font(fontChoice.font(size: size * 1.05, weight: .black, sectionName: line.sectionName))
                .tracking(4.0)
                .foregroundStyle(
                    LinearGradient(
                        colors: [palette.primary.opacity(0.8), palette.accent.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 28)
                .scaleEffect(1.0 + CGFloat(sin(wavePhase * 2.2) * 0.28 + 0.28))
                .opacity(0.48)
            
            // Hero Word
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: line.sectionName))
                .tracking(2.0 + sin(wavePhase * 2.0) * 2.5)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.96), palette.accent.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.white.opacity(0.95), radius: 16, x: 0, y: 0)
                .shadow(color: palette.primary.opacity(0.85), radius: 40, x: 0, y: 0)
                .shadow(color: palette.accent.opacity(0.7), radius: CGFloat(60 + audioSync.currentRMS * 40), x: 0, y: 0)
                .rotationEffect(tilt)
                .scaleEffect(1.0 + CGFloat(sin(wavePhase * 2.6) * 0.08))
                .offset(
                    x: cos(wavePhase * 1.8) * 9.0,
                    y: sin(wavePhase * 3.2) * 7.0
                )
        }
    }
    
    // MARK: - Variation 1: 3D Vertical Tumbler
    
    @ViewBuilder
    private func verticalTumbleWord(word: TimedWord) -> some View {
        let size = dynamicFontSize(for: word.text)
        let tilt = organicTilt(for: word.text, base: 5.0)
        
        ZStack {
            // Ambient Aura
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: line.sectionName))
                .foregroundStyle(palette.accent.opacity(0.4))
                .blur(radius: 20)
                .offset(y: 12)
            
            // Hero Word tumbling on X-Axis
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: line.sectionName))
                .tracking(1.0)
                .foregroundStyle(Color.white)
                .shadow(color: Color.white.opacity(0.92), radius: 14, x: 0, y: 0)
                .shadow(color: palette.accent.opacity(0.9), radius: 36, x: 0, y: 0)
                .shadow(color: palette.primary.opacity(0.75), radius: 55, x: 0, y: 0)
                .rotationEffect(tilt + .degrees(sin(wavePhase * 2.2) * 2.5))
                .rotation3DEffect(
                    .degrees(sin(wavePhase * 2.4) * 9.0),
                    axis: (x: 1, y: 0.1, z: 0),
                    perspective: 0.5
                )
                .offset(y: sin(wavePhase * 3.8) * 8.0)
        }
    }
    
    // MARK: - Variation 2: Kinetic Horizontal Barrel Roll
    
    @ViewBuilder
    private func horizontalRollWord(word: TimedWord) -> some View {
        let size = dynamicFontSize(for: word.text)
        let tilt = organicTilt(for: word.text, base: -3.0)
        
        ZStack {
            // Soft Background Flare
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: line.sectionName))
                .foregroundStyle(palette.primary.opacity(0.45))
                .blur(radius: 22)
                .offset(x: -8)
            
            // Hero Word rolling on Y-Axis
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: line.sectionName))
                .tracking(1.8)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, palette.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.white.opacity(0.95), radius: 15, x: 0, y: 0)
                .shadow(color: palette.accent.opacity(0.85), radius: 38, x: 0, y: 0)
                .shadow(color: palette.primary.opacity(0.65), radius: 60, x: 0, y: 0)
                .rotationEffect(tilt)
                .rotation3DEffect(
                    .degrees(sin(wavePhase * 2.1) * 12.0),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .offset(x: cos(wavePhase * 2.4) * 12.0)
        }
    }
    
    // MARK: - Variation 3: Chromatic Impact Slam
    
    @ViewBuilder
    private func chromaticSlamWord(word: TimedWord) -> some View {
        let size = dynamicFontSize(for: word.text)
        let tilt = organicTilt(for: word.text, base: 4.0)
        
        ZStack {
            // Chromatic Echo Left (Palette Primary)
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: line.sectionName))
                .foregroundStyle(palette.primary.opacity(0.65))
                .blur(radius: 4)
                .offset(x: -6, y: 3)
            
            // Chromatic Echo Right (Palette Accent)
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: line.sectionName))
                .foregroundStyle(palette.accent.opacity(0.65))
                .blur(radius: 4)
                .offset(x: 6, y: -3)
            
            // Core Word
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: line.sectionName))
                .tracking(1.2)
                .foregroundStyle(Color.white)
                .shadow(color: Color.white.opacity(0.95), radius: 18, x: 0, y: 0)
                .shadow(color: palette.primary.opacity(0.85), radius: 42, x: 0, y: 0)
                .shadow(color: palette.accent.opacity(0.7), radius: 65, x: 0, y: 0)
                .rotationEffect(tilt)
                .scaleEffect(1.0 + CGFloat(audioSync.currentRMS * 0.15))
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
    
    private func organicTilt(for text: String, base: Double) -> Angle {
        let hash = abs(text.hashValue)
        let offsets: [Double] = [-2.0, 1.5, -1.0, 2.0, -2.5, 1.8]
        return .degrees(base + offsets[hash % offsets.count])
    }
}
