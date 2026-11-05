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
            
            // SOLO KINETIC WORD CANVAS (Clean, Pure White Dominant Typography)
            ZStack {
                if let word = wordToDisplay {
                    Group {
                        switch variation {
                        case 0:
                            // VARIATION 0: 🌌 Stranger Things Retro Cinematic Zoom
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
                            // VARIATION 1: 🌪️ 3D Kinetic Tumble
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
                            // VARIATION 2: 🌫️ Ethereal Smoke & Ghost Dissolve
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
                            // VARIATION 3: ⚡ Hyperspace Kinetic Impact
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
                            // VARIATION 4: 🎭 Prismatic Barrel Roll & Drift
                            PrismaticRollWordView(
                                word: word,
                                palette: palette,
                                fontChoice: fontChoice,
                                sectionName: line.sectionName
                            )
                            .transition(
                                .asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(y: 40)),
                                    removal: .scale(scale: 1.2).combined(with: .opacity).combined(with: .offset(y: -40))
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
            .frame(height: 290)
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
        guard let resolved = currentActiveWord(words: timedWords) else {
            if currentPosition < line.startTime - 0.5 {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                    self.activeWord = nil
                }
            }
            return
        }
        
        if resolved.id != activeWord?.id || resolved.text != activeWord?.text {
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
            // Soft Ambient Glow (Centered & subtle)
            Text(word.text)
                .font(fontChoice.font(size: size * 1.04, weight: .black, sectionName: sectionName))
                .tracking(7.0)
                .foregroundStyle(neonGlowColor.opacity(0.45))
                .blur(radius: 36)
                .scaleEffect(isZooming ? 1.20 : 0.92)
            
            // Hero Typography: >60% Pure Radiant White, bottom ~40% gentle accent dip
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .tracking(5.5)
                .foregroundStyle(
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0.0),
                            .init(color: .white, location: 0.62),
                            .init(color: neonGlowColor.opacity(0.80), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.white.opacity(0.95), radius: 14, x: 0, y: 0)
                .shadow(color: neonGlowColor.opacity(0.50), radius: 28, x: 0, y: 0)
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
            // Ground plane depth shadow (Centered)
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .foregroundStyle(palette.accent.opacity(0.35))
                .blur(radius: 20)
                .offset(y: isTumbled ? 28 : 50)
                .scaleEffect(isTumbled ? 0.95 : 0.7)
            
            // Hero Tumbling Word: >60% White, bottom ~40% accent
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .tracking(2.0)
                .foregroundStyle(
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0.0),
                            .init(color: .white, location: 0.62),
                            .init(color: palette.accent.opacity(0.80), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.white.opacity(0.92), radius: 14, x: 0, y: 0)
                .shadow(color: palette.accent.opacity(0.50), radius: 30, x: 0, y: 0)
                .rotation3DEffect(
                    .degrees(isTumbled ? 0 : -80),
                    axis: (x: 1, y: 0, z: 0),
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
            // Ambient Cloud Vapour Halo (Centered)
            Text(word.text)
                .font(fontChoice.font(size: size * 1.08, weight: .black, sectionName: sectionName))
                .foregroundStyle(palette.primary.opacity(0.40))
                .blur(radius: isMaterialized ? 22 : 40)
                .scaleEffect(isMaterialized ? 1.05 : 1.4)
                .opacity(isMaterialized ? 0.50 : 0.0)
            
            // Core Word: >60% White, bottom ~40% accent
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .tracking(3.5)
                .foregroundStyle(
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0.0),
                            .init(color: .white, location: 0.62),
                            .init(color: palette.accent.opacity(0.75), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.white.opacity(0.95), radius: 14, x: 0, y: 0)
                .shadow(color: palette.accent.opacity(0.45), radius: 28, x: 0, y: 0)
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
            // Vertical Symmetrical Depth Echo
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .foregroundStyle(palette.accent.opacity(0.35))
                .blur(radius: 8)
                .offset(y: isImpacted ? 4 : 22)
                .scaleEffect(isImpacted ? 1.0 : 1.3)
                .opacity(isImpacted ? 0.5 : 0.0)
            
            // Hero Word: >60% White, bottom ~40% accent
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .tracking(1.5)
                .foregroundStyle(
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0.0),
                            .init(color: .white, location: 0.62),
                            .init(color: palette.accent.opacity(0.80), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.white.opacity(0.95), radius: 14, x: 0, y: 0)
                .shadow(color: palette.accent.opacity(0.50), radius: 30, x: 0, y: 0)
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
            // Symmetrical Soft Ambient Flare (Centered)
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .foregroundStyle(palette.accent.opacity(0.30))
                .blur(radius: 18)
                .scaleEffect(isRolled ? 1.05 : 0.9)
            
            // Hero Word: >60% White, bottom ~40% accent
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .tracking(2.5)
                .foregroundStyle(
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0.0),
                            .init(color: .white, location: 0.62),
                            .init(color: palette.accent.opacity(0.80), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.white.opacity(0.92), radius: 14, x: 0, y: 0)
                .shadow(color: palette.accent.opacity(0.45), radius: 26, x: 0, y: 0)
                .rotation3DEffect(
                    .degrees(isRolled ? 0 : 70),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.4
                )
                .offset(y: isRolled ? 0 : 25)
                .scaleEffect(isRolled ? 1.0 : 0.85)
        }
        .onAppear {
            withAnimation(.spring(response: 0.60, dampingFraction: 0.70)) {
                isRolled = true
            }
        }
    }
}
