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
    @ObservedObject var appState = AppState.shared
    
    @State private var activeWord: TimedWord? = nil
    
    public init(
        line: LyricLine,
        currentPosition: TimeInterval,
        palette: ArtworkPalette,
        fontChoice: LyricFont,
        wavePhase: Double,
        onSeek: @escaping () -> Void
    ) {
        self.line = line
        self.currentPosition = currentPosition
        self.palette = palette
        self.fontChoice = fontChoice
        self.wavePhase = wavePhase
        self.onSeek = onSeek
    }
    
    public var body: some View {
        let timedWords = line.timedWords(
            speedMultiplier: appState.pacingSpeedMultiplier,
            chunkPhrases: appState.usePhraseChunking
        )
        let resolved = currentActiveWord(words: timedWords)
        let wordToDisplay = activeWord ?? resolved
        let wordIndex = wordToDisplay?.id ?? 0
        let variation = wordIndex % 5
        
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
            
            // SOLO KINETIC WORD - CINEMATIC, BUTTERY SMOOTH & JITTER-FREE
            ZStack {
                if let word = wordToDisplay {
                    Group {
                        switch variation {
                        case 0:
                            // VARIATION 0: 🌌 Stranger Things Retro Cinematic Zoom (Slow ominous creeping zoom-in with deep atmospheric neon bloom)
                            StrangerThingsZoomWordView(
                                word: word,
                                palette: palette,
                                fontChoice: fontChoice,
                                sectionName: line.sectionName
                            )
                            .transition(
                                .asymmetric(
                                    insertion: .scale(scale: 0.55).combined(with: .opacity),
                                    removal: .scale(scale: 2.2).combined(with: .opacity)
                                )
                            )
                            
                        case 1:
                            // VARIATION 1: 🌪️ 3D Kinetic Tumble (Somersault flip on X-Axis from above, ground shadow, spring settling)
                            KineticTumbleWordView(
                                word: word,
                                palette: palette,
                                fontChoice: fontChoice,
                                sectionName: line.sectionName
                            )
                            .transition(
                                .asymmetric(
                                    insertion: .scale(scale: 0.7).combined(with: .opacity).combined(with: .offset(y: -75)),
                                    removal: .scale(scale: 0.7).combined(with: .opacity).combined(with: .offset(y: 75))
                                )
                            )
                            
                        case 2:
                            // VARIATION 2: 🌫️ Ethereal Smoke & Ghost Dissolve (Emerges from dense starlight mist, resolves, evaporates)
                            EtherealSmokeFadeWordView(
                                word: word,
                                palette: palette,
                                fontChoice: fontChoice,
                                sectionName: line.sectionName
                            )
                            .transition(
                                .asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 1.25)),
                                    removal: .opacity.combined(with: .scale(scale: 0.75))
                                )
                            )
                            
                        case 3:
                            // VARIATION 3: ⚡ Hyperspace Kinetic Impact (Lightspeed punch from depth with dual chromatic trails)
                            HyperspaceImpactWordView(
                                word: word,
                                palette: palette,
                                fontChoice: fontChoice,
                                sectionName: line.sectionName
                            )
                            .transition(
                                .asymmetric(
                                    insertion: .scale(scale: 1.5).combined(with: .opacity),
                                    removal: .scale(scale: 0.4).combined(with: .opacity).combined(with: .offset(y: -40))
                                )
                            )
                            
                        default:
                            // VARIATION 4: 🎭 Prismatic Barrel Roll & Drift (3D horizontal spin on Y-Axis with neon light refraction)
                            PrismaticRollWordView(
                                word: word,
                                palette: palette,
                                fontChoice: fontChoice,
                                sectionName: line.sectionName
                            )
                            .transition(
                                .asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(x: 100)),
                                    removal: .scale(scale: 1.2).combined(with: .opacity).combined(with: .offset(x: -100))
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
                                .scaleEffect(sin(Double(dot) * 0.8) * 0.2 + 0.85)
                        }
                    }
                    .frame(height: 180)
                }
            }
            .frame(height: 280)
            .animation(.spring(response: 0.58, dampingFraction: 0.76), value: wordToDisplay?.id)
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSeek()
        }
        .onAppear {
            updateActiveWord()
        }
        .onChange(of: currentPosition) { _, _ in
            updateActiveWord()
        }
    }
    
    private func updateActiveWord() {
        let timedWords = line.timedWords(
            speedMultiplier: appState.pacingSpeedMultiplier,
            chunkPhrases: appState.usePhraseChunking
        )
        let resolved = currentActiveWord(words: timedWords)
        if resolved?.id != activeWord?.id || resolved?.text != activeWord?.text {
            withAnimation(.spring(response: 0.58, dampingFraction: 0.74)) {
                self.activeWord = resolved
            }
        }
    }
    
    // MARK: - Word Resolution with Audio Onset Sync
    
    private func currentActiveWord(words: [TimedWord]) -> TimedWord? {
        guard !words.isEmpty else { return nil }
        
        // Before the line's vocals start (musical intro/pause)
        if currentPosition < line.startTime - 0.25 {
            return nil
        }
        
        for (i, word) in words.enumerated() {
            if audioSync.isWordTriggered(wordStartTime: word.startTime, currentPosition: currentPosition) {
                if i + 1 < words.count && audioSync.isWordTriggered(wordStartTime: words[i + 1].startTime, currentPosition: currentPosition) {
                    continue
                }
                return word
            }
        }
        
        return words.last
    }
}

// MARK: - Dynamic Font Size Helper

fileprivate func dynamicFontSize(for text: String) -> CGFloat {
    let length = text.count
    if length <= 3 {
        return 155 // Short words: Massive presence!
    } else if length <= 6 {
        return 135 // Medium words
    } else if length <= 10 {
        return 115 // Longer words
    } else if length <= 16 {
        return 95  // Phrases
    } else {
        return 80  // Extended lines
    }
}

// MARK: - Style 0: 🌌 Stranger Things Retro Cinematic Zoom

struct StrangerThingsZoomWordView: View {
    let word: TimedWord
    let palette: ArtworkPalette
    let fontChoice: LyricFont
    let sectionName: String?
    
    @State private var isZooming: Bool = false
    
    var body: some View {
        let size = dynamicFontSize(for: word.text)
        let wordDuration = max(word.endTime - word.startTime, 1.2)
        let neonGlowColor = palette.accent
        
        ZStack {
            // Deep Ambient 80s Neon Haze
            Text(word.text)
                .font(fontChoice.font(size: size * 1.04, weight: .black, sectionName: sectionName))
                .tracking(7.0)
                .foregroundStyle(neonGlowColor.opacity(0.85))
                .blur(radius: 42)
                .scaleEffect(isZooming ? 1.20 : 0.92)
            
            // Secondary Mid-Glow Bloom
            Text(word.text)
                .font(fontChoice.font(size: size * 1.02, weight: .black, sectionName: sectionName))
                .tracking(6.0)
                .foregroundStyle(
                    LinearGradient(
                        colors: [neonGlowColor, palette.primary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blur(radius: 14)
                .scaleEffect(isZooming ? 1.15 : 0.90)
            
            // Hero Stranger Things Typography
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .tracking(5.5)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.96), neonGlowColor.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.white.opacity(0.9), radius: 12, x: 0, y: 0)
                .shadow(color: neonGlowColor.opacity(0.95), radius: 32, x: 0, y: 0)
                .shadow(color: palette.primary.opacity(0.8), radius: 55, x: 0, y: 0)
                .scaleEffect(isZooming ? 1.12 : 0.88)
                .offset(y: isZooming ? -8 : 8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: wordDuration * 0.98)) {
                isZooming = true
            }
        }
    }
}

// MARK: - Style 1: 🌪️ 3D Kinetic Tumble

struct KineticTumbleWordView: View {
    let word: TimedWord
    let palette: ArtworkPalette
    let fontChoice: LyricFont
    let sectionName: String?
    
    @State private var isTumbled: Bool = false
    
    var body: some View {
        let size = dynamicFontSize(for: word.text)
        
        ZStack {
            // Ground plane depth shadow
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .foregroundStyle(palette.accent.opacity(0.45))
                .blur(radius: 24)
                .offset(y: isTumbled ? 28 : 50)
                .scaleEffect(isTumbled ? 0.95 : 0.7)
            
            // Hero Tumbling Word on X-Axis
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .tracking(2.0)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, palette.accent.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.white.opacity(0.85), radius: 15, x: 0, y: 0)
                .shadow(color: palette.accent.opacity(0.9), radius: 35, x: 0, y: 0)
                .shadow(color: palette.primary.opacity(0.7), radius: 55, x: 0, y: 0)
                .rotation3DEffect(
                    .degrees(isTumbled ? 0 : -80),
                    axis: (x: 1, y: 0.1, z: 0),
                    perspective: 0.45
                )
                .offset(y: isTumbled ? 0 : -70)
                .scaleEffect(isTumbled ? 1.0 : 0.82)
        }
        .onAppear {
            withAnimation(.spring(response: 0.62, dampingFraction: 0.68)) {
                isTumbled = true
            }
        }
    }
}

// MARK: - Style 2: 🌫️ Ethereal Smoke & Ghost Dissolve

struct EtherealSmokeFadeWordView: View {
    let word: TimedWord
    let palette: ArtworkPalette
    let fontChoice: LyricFont
    let sectionName: String?
    
    @State private var isMaterialized: Bool = false
    
    var body: some View {
        let size = dynamicFontSize(for: word.text)
        
        ZStack {
            // Ambient Cloud Vapour Halo
            Text(word.text)
                .font(fontChoice.font(size: size * 1.08, weight: .black, sectionName: sectionName))
                .foregroundStyle(palette.primary.opacity(0.75))
                .blur(radius: isMaterialized ? 25 : 45)
                .scaleEffect(isMaterialized ? 1.05 : 1.4)
                .opacity(isMaterialized ? 0.65 : 0.0)
            
            // Core Word Materializing from Mist
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .tracking(3.5)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.95), palette.accent.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.white.opacity(0.95), radius: 16, x: 0, y: 0)
                .shadow(color: palette.accent.opacity(0.85), radius: 40, x: 0, y: 0)
                .blur(radius: isMaterialized ? 0 : 28)
                .scaleEffect(isMaterialized ? 1.0 : 1.25)
                .opacity(isMaterialized ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.65)) {
                isMaterialized = true
            }
        }
    }
}

// MARK: - Style 3: ⚡ Hyperspace Kinetic Impact

struct HyperspaceImpactWordView: View {
    let word: TimedWord
    let palette: ArtworkPalette
    let fontChoice: LyricFont
    let sectionName: String?
    
    @State private var isImpacted: Bool = false
    
    var body: some View {
        let size = dynamicFontSize(for: word.text)
        
        ZStack {
            // Chromatic Trail Left (Palette Primary)
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .foregroundStyle(palette.primary.opacity(0.6))
                .blur(radius: 5)
                .offset(x: isImpacted ? -4 : -35, y: isImpacted ? -2 : -15)
                .scaleEffect(isImpacted ? 1.0 : 1.4)
                .opacity(isImpacted ? 0.7 : 0.0)
            
            // Chromatic Trail Right (Palette Accent)
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .foregroundStyle(palette.accent.opacity(0.6))
                .blur(radius: 5)
                .offset(x: isImpacted ? 4 : 35, y: isImpacted ? 2 : 15)
                .scaleEffect(isImpacted ? 1.0 : 1.4)
                .opacity(isImpacted ? 0.7 : 0.0)
            
            // Hero Word
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .tracking(1.5)
                .foregroundStyle(Color.white)
                .shadow(color: Color.white.opacity(0.95), radius: 16, x: 0, y: 0)
                .shadow(color: palette.accent.opacity(0.9), radius: 42, x: 0, y: 0)
                .shadow(color: palette.primary.opacity(0.75), radius: 65, x: 0, y: 0)
                .scaleEffect(isImpacted ? 1.0 : 1.5)
                .opacity(isImpacted ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.44, dampingFraction: 0.62)) {
                isImpacted = true
            }
        }
    }
}

// MARK: - Style 4: 🎭 Prismatic Barrel Roll & Drift

struct PrismaticRollWordView: View {
    let word: TimedWord
    let palette: ArtworkPalette
    let fontChoice: LyricFont
    let sectionName: String?
    
    @State private var isRolled: Bool = false
    
    var body: some View {
        let size = dynamicFontSize(for: word.text)
        
        ZStack {
            // Prismatic Echo
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .foregroundStyle(palette.accent.opacity(0.5))
                .blur(radius: 18)
                .offset(x: isRolled ? -6 : -40)
            
            // Hero Word Rolling on Y-Axis
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .tracking(2.5)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, palette.accent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: Color.white.opacity(0.92), radius: 15, x: 0, y: 0)
                .shadow(color: palette.accent.opacity(0.85), radius: 36, x: 0, y: 0)
                .rotation3DEffect(
                    .degrees(isRolled ? 0 : 70),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.4
                )
                .offset(x: isRolled ? 0 : 80)
                .scaleEffect(isRolled ? 1.0 : 0.85)
        }
        .onAppear {
            withAnimation(.spring(response: 0.60, dampingFraction: 0.70)) {
                isRolled = true
            }
        }
    }
}
