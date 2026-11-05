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
            
            // SOLO KINETIC WORD CANVAS WITH AMBIENT RIPPLES
            ZStack {
                // RAM-Easy Ambient Sonic Ripples (GPU Accelerated, 0 CPU overhead)
                AmbientSonicRipples(color: palette.accent)
                    .opacity(wordToDisplay != nil ? 0.75 : 0.2)
                
                if let word = wordToDisplay {
                    Group {
                        switch variation {
                        case 0:
                            // VARIATION 0: 🌌 Stranger Things Retro Cinematic Zoom (Ominous creeping zoom with vertical bottom gradient)
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
                            // VARIATION 2: 🌫️ Ethereal Smoke & Ghost Dissolve (Emerges from starlight mist, vertical gradient, dissolves)
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
                            // VARIATION 3: ⚡ Hyperspace Kinetic Impact (Lightspeed punch from depth with symmetrical vertical bloom)
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
                            // VARIATION 4: 🎭 Prismatic Barrel Roll & Drift (3D horizontal spin on Y-Axis with pure vertical bottom gradient)
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

// MARK: - RAM-Easy Ambient Sonic Ripples (GPU Accelerated Vector Rings)

struct AmbientSonicRipples: View {
    let color: Color
    @State private var ripplePhase: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .strokeBorder(
                        color.opacity(max(0, 0.32 - Double(index) * 0.08 - Double(ripplePhase) * 0.12)),
                        lineWidth: 1.5
                    )
                    .scaleEffect(0.55 + CGFloat(index) * 0.35 + ripplePhase * 0.38)
                    .blur(radius: 1.5 + CGFloat(index) * 2.0)
            }
        }
        .frame(width: 320, height: 320)
        .onAppear {
            withAnimation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true)) {
                ripplePhase = 1.0
            }
        }
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
            // Deep Ambient 80s Neon Haze (Centered)
            Text(word.text)
                .font(fontChoice.font(size: size * 1.04, weight: .black, sectionName: sectionName))
                .tracking(7.0)
                .foregroundStyle(neonGlowColor.opacity(0.85))
                .blur(radius: 42)
                .scaleEffect(isZooming ? 1.20 : 0.92)
            
            // Secondary Mid-Glow Bloom (Vertical Gradient)
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
            
            // Hero Typography: Pure Top-to-Bottom Vertical Gradient (No right-side color tint)
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
            // Ground plane depth shadow (Centered)
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .foregroundStyle(palette.accent.opacity(0.45))
                .blur(radius: 24)
                .offset(y: isTumbled ? 28 : 50)
                .scaleEffect(isTumbled ? 0.95 : 0.7)
            
            // Hero Tumbling Word: Vertical Top-to-Bottom Gradient
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
                .foregroundStyle(palette.primary.opacity(0.75))
                .blur(radius: isMaterialized ? 25 : 45)
                .scaleEffect(isMaterialized ? 1.05 : 1.4)
                .opacity(isMaterialized ? 0.65 : 0.0)
            
            // Core Word: Pure Top-to-Bottom Vertical Gradient (No right-side color tint)
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .tracking(3.5)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.95), palette.accent.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
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
            // Vertical Symmetrical Depth Echo (Centered vertically, NO right-side offset)
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .foregroundStyle(palette.accent.opacity(0.55))
                .blur(radius: 8)
                .offset(y: isImpacted ? 4 : 22)
                .scaleEffect(isImpacted ? 1.0 : 1.3)
                .opacity(isImpacted ? 0.6 : 0.0)
            
            // Hero Word: Pure Top-to-Bottom Vertical Gradient
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .tracking(1.5)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.95), palette.accent.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
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
            // Symmetrical Soft Ambient Flare (Centered, no right bias)
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .foregroundStyle(palette.accent.opacity(0.45))
                .blur(radius: 20)
                .scaleEffect(isRolled ? 1.05 : 0.9)
            
            // Hero Word: Vertical Top-to-Bottom Gradient (No right-side color tint)
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .tracking(2.5)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.95), palette.accent.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.white.opacity(0.92), radius: 15, x: 0, y: 0)
                .shadow(color: palette.accent.opacity(0.85), radius: 36, x: 0, y: 0)
                .shadow(color: palette.primary.opacity(0.65), radius: 55, x: 0, y: 0)
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
