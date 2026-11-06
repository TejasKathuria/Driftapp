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
    @State private var activeSegment: TimedPhraseSegment? = nil
    
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
        let resolvedWord = currentActiveWord(words: timedWords)
        let wordToDisplay = activeWord ?? resolvedWord
        let wordIndex = wordToDisplay?.id ?? 0
        let variation = wordIndex % 5
        
        let prevWord = wordToDisplay.flatMap { previousWordText(for: $0, in: timedWords) }
        let nextWord = wordToDisplay.flatMap { nextWordText(for: $0, in: timedWords) }
        
        // Pop Style Segments (2-3 words per segment with live word ignition)
        let segments = line.timedPhraseSegments(speedMultiplier: appState.pacingSpeedMultiplier)
        let resolvedSegment = currentActiveSegment(segments: segments)
        let segmentToDisplay = activeSegment ?? resolvedSegment
        let segIndex = segmentToDisplay?.id ?? 0
        let popVariation = segIndex % 6
        
        VStack {
            Spacer()
            
            // Section Tag Badge (Minimal & Floating)
            if let section = line.sectionName, !section.isEmpty {
                Text(section.uppercased())
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .tracking(3.5)
                    .foregroundStyle(palette.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(palette.primary.opacity(0.35))
                    )
                    .shadow(color: palette.accent.opacity(0.5), radius: 14)
                    .padding(.bottom, 22)
                    .transition(.opacity)
            }
            
            // DYNAMIC KINETIC LYRIC CANVAS
            Group {
                switch appState.kineticStyle {
                case .threeSlotReel:
                    // STYLE A: 3-Slot Kinetic Vertical Reel (CleanShot Inspired)
                    threeSlotReelCanvas(
                        hero: wordToDisplay,
                        prev: prevWord,
                        next: nextWord
                    )
                    
                case .popPosterCanvas:
                    // STYLE B: Pop Kinetic Posters with Live Word-by-Word Ignition (e.g. "मेरी" white, "जान" accent)
                    popPosterCanvas(
                        segment: segmentToDisplay,
                        variation: popVariation
                    )
                    
                case .staircaseCascade:
                    // STYLE D: CleanShot Diagonal Staircase Cascade with Star Badge ("Dance under stars")
                    staircaseCascadeCanvas(
                        segment: segmentToDisplay
                    )
                    
                case .soloCinematicStream:
                    // STYLE C: Solo Cinematic Word Stream (Stranger Things & 3D Tumble)
                    soloCinematicStreamCanvas(
                        hero: wordToDisplay,
                        variation: variation
                    )
                }
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSeek()
        }
        .onAppear {
            updateActiveWord()
            updateActiveSegment()
        }
        .onChange(of: currentPosition) { _, _ in
            updateActiveWord()
            updateActiveSegment()
        }
    }
    
    // MARK: - Style A: 3-Slot Kinetic Vertical Reel
    
    @ViewBuilder
    private func threeSlotReelCanvas(hero: TimedWord?, prev: String?, next: String?) -> some View {
        VStack(spacing: 24) {
            // 1. Previous Word (Top Slot - Dimmed)
            ZStack {
                if let prev = prev {
                    Text(prev)
                        .font(fontChoice.font(size: 32, weight: .bold, sectionName: line.sectionName))
                        .foregroundStyle(Color.white.opacity(0.42))
                        .shadow(color: Color.black.opacity(0.3), radius: 8)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.6).combined(with: .offset(y: 45)).combined(with: .opacity),
                                removal: .offset(y: -45).combined(with: .opacity)
                            )
                        )
                        .id("prev-\(prev)")
                }
            }
            .frame(height: 48)
            
            // 2. Active Hero Word (Center Slot - Massive, Tilted & Radiant)
            ZStack {
                if let hero = hero {
                    Text(hero.text)
                        .font(fontChoice.font(size: dynamicFontSize(for: hero.text), weight: .black, sectionName: line.sectionName))
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
                        .shadow(color: palette.accent.opacity(0.40), radius: 30, x: 0, y: 0)
                        .rotationEffect(organicTilt(for: hero.text))
                        .transition(
                            .asymmetric(
                                insertion: .offset(y: 40).combined(with: .scale(scale: 0.8)).combined(with: .opacity),
                                removal: .offset(y: -25).combined(with: .opacity)
                            )
                        )
                        .zIndex(10)
                        .id("hero-\(hero.id)-\(hero.text)")
                } else {
                    breathingDots()
                }
            }
            .frame(height: 195)
            
            // 3. Next Word (Bottom Slot - Upcoming Preview)
            ZStack {
                if let next = next {
                    Text(next)
                        .font(fontChoice.font(size: 32, weight: .bold, sectionName: line.sectionName))
                        .foregroundStyle(Color.white.opacity(0.42))
                        .shadow(color: Color.black.opacity(0.3), radius: 8)
                        .transition(
                            .asymmetric(
                                insertion: .offset(y: 35).combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                        .id("next-\(next)")
                }
            }
            .frame(height: 48)
        }
    }
    
    // MARK: - Style B: Pop Kinetic Posters with Live Word-by-Word Ignition
    
    @ViewBuilder
    private func popPosterCanvas(segment: TimedPhraseSegment?, variation: Int) -> some View {
        ZStack {
            if let seg = segment {
                Group {
                    switch variation {
                    case 0:
                        // Variation 0: 🎟️ Bold Accent Banner Card with Live Word Ignition
                        BannerCardPosterView(
                            segment: seg,
                            currentPosition: currentPosition,
                            palette: palette,
                            fontChoice: fontChoice,
                            sectionName: line.sectionName
                        )
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.60).combined(with: .opacity),
                                removal: .scale(scale: 1.25).combined(with: .opacity)
                            )
                        )
                        
                    case 1:
                        // Variation 1: 🎵 4-Corner Floating Musical Notes Frame
                        MusicalNotesPosterView(
                            segment: seg,
                            currentPosition: currentPosition,
                            palette: palette,
                            fontChoice: fontChoice,
                            sectionName: line.sectionName
                        )
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.75).combined(with: .offset(y: 40)).combined(with: .opacity),
                                removal: .scale(scale: 0.75).combined(with: .offset(y: -40)).combined(with: .opacity)
                            )
                        )
                        
                    case 2:
                        // Variation 2: 🌊 Undulating Wave Arch (Exact Match to "मेरी जान" Screenshot!)
                        WaveSplitPosterView(
                            segment: seg,
                            currentPosition: currentPosition,
                            palette: palette,
                            fontChoice: fontChoice,
                            sectionName: line.sectionName
                        )
                        .transition(
                            .asymmetric(
                                insertion: .offset(x: -70).combined(with: .opacity),
                                removal: .offset(x: 70).combined(with: .opacity)
                            )
                        )
                        
                    case 3:
                        // Variation 3: 🪜 Diagonal Staircase Cascade with Star Badge (CleanShot 12.30.31 PM)
                        StaircaseCascadePosterView(
                            segment: seg,
                            currentPosition: currentPosition,
                            palette: palette,
                            fontChoice: fontChoice,
                            sectionName: line.sectionName
                        )
                        .transition(
                            .asymmetric(
                                insertion: .offset(x: -45, y: -25).combined(with: .scale(scale: 0.88)).combined(with: .opacity),
                                removal: .offset(x: 45, y: 25).combined(with: .scale(scale: 1.12)).combined(with: .opacity)
                            )
                        )
                        
                    case 4:
                        // Variation 4: ↗️ Diagonal Dynamic Kick
                        DiagonalKickPosterView(
                            segment: seg,
                            currentPosition: currentPosition,
                            palette: palette,
                            fontChoice: fontChoice,
                            sectionName: line.sectionName
                        )
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 1.25).combined(with: .offset(x: 45)).combined(with: .opacity),
                                removal: .scale(scale: 0.65).combined(with: .offset(x: -45)).combined(with: .opacity)
                            )
                        )
                        
                    default:
                        // Variation 5: 🔄 3D Revolving Letter Flip
                        Flip3DPosterView(
                            segment: seg,
                            currentPosition: currentPosition,
                            palette: palette,
                            fontChoice: fontChoice,
                            sectionName: line.sectionName
                        )
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.75).combined(with: .opacity),
                                removal: .scale(scale: 1.25).combined(with: .opacity)
                            )
                        )
                    }
                }
                .id("popseg-\(seg.id)-\(seg.text)")
            } else {
                breathingDots()
            }
        }
        .frame(height: 310)
        .animation(.spring(response: 0.48, dampingFraction: 0.72), value: segment?.id)
    }
    
    // MARK: - Style D: CleanShot Diagonal Staircase Cascade
    
    @ViewBuilder
    private func staircaseCascadeCanvas(segment: TimedPhraseSegment?) -> some View {
        ZStack {
            if let seg = segment {
                StaircaseCascadePosterView(
                    segment: seg,
                    currentPosition: currentPosition,
                    palette: palette,
                    fontChoice: fontChoice,
                    sectionName: line.sectionName
                )
                .transition(
                    .asymmetric(
                        insertion: .offset(x: -35, y: -20).combined(with: .scale(scale: 0.90)).combined(with: .opacity),
                        removal: .opacity
                    )
                )
                .id("staircase-\(seg.id)-\(seg.text)")
            } else {
                breathingDots()
            }
        }
        .frame(height: 320)
    }
    
    // MARK: - Style C: Solo Cinematic Word Stream
    
    @ViewBuilder
    private func soloCinematicStreamCanvas(hero: TimedWord?, variation: Int) -> some View {
        ZStack {
            if let word = hero {
                Group {
                    switch variation {
                    case 0:
                        StrangerThingsZoomWordView(
                            word: word,
                            palette: palette,
                            fontChoice: fontChoice,
                            sectionName: line.sectionName
                        )
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.70).combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                    case 1:
                        KineticTumbleWordView(
                            word: word,
                            palette: palette,
                            fontChoice: fontChoice,
                            sectionName: line.sectionName
                        )
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.75).combined(with: .offset(y: -45)),
                                removal: .opacity
                            )
                        )
                    case 2:
                        EtherealSmokeFadeWordView(
                            word: word,
                            palette: palette,
                            fontChoice: fontChoice,
                            sectionName: line.sectionName
                        )
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 1.15)),
                                removal: .opacity
                            )
                        )
                    case 3:
                        HyperspaceImpactWordView(
                            word: word,
                            palette: palette,
                            fontChoice: fontChoice,
                            sectionName: line.sectionName
                        )
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 1.35).combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                    default:
                        PrismaticRollWordView(
                            word: word,
                            palette: palette,
                            fontChoice: fontChoice,
                            sectionName: line.sectionName
                        )
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.85).combined(with: .offset(y: 30)),
                                removal: .opacity
                            )
                        )
                    }
                }
                .id("solo-\(word.id)-\(word.text)")
            } else {
                breathingDots()
            }
        }
        .frame(height: 280)
    }
    
    @ViewBuilder
    private func breathingDots() -> some View {
        HStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { dot in
                Circle()
                    .fill(palette.accent.opacity(0.85))
                    .frame(width: 14, height: 14)
                    .shadow(color: palette.accent.opacity(0.8), radius: 12)
                    .scaleEffect(sin(Double(dot) * 0.8) * 0.2 + 0.85)
            }
        }
    }
    
    private func updateActiveWord() {
        let timedWords = line.timedWords(
            speedMultiplier: appState.pacingSpeedMultiplier,
            chunkPhrases: appState.usePhraseChunking
        )
        guard let resolved = currentActiveWord(words: timedWords) else {
            if currentPosition < line.startTime - 0.5 {
                withAnimation(.easeOut(duration: 0.25)) {
                    self.activeWord = nil
                }
            }
            return
        }
        
        if activeWord == nil {
            self.activeWord = resolved
        } else if resolved.id != activeWord?.id || resolved.text != activeWord?.text {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                self.activeWord = resolved
            }
        }
    }
    
    private func updateActiveSegment() {
        let segments = line.timedPhraseSegments(speedMultiplier: appState.pacingSpeedMultiplier)
        guard let resolved = currentActiveSegment(segments: segments) else {
            if currentPosition < line.startTime - 0.5 {
                withAnimation(.easeOut(duration: 0.25)) {
                    self.activeSegment = nil
                }
            }
            return
        }
        
        if activeSegment == nil {
            self.activeSegment = resolved
        } else if resolved.id != activeSegment?.id || resolved.text != activeSegment?.text {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                self.activeSegment = resolved
            }
        }
    }
    
    // MARK: - Word & Segment Resolution
    
    private func currentActiveWord(words: [TimedWord]) -> TimedWord? {
        guard !words.isEmpty else { return nil }
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
    
    private func currentActiveSegment(segments: [TimedPhraseSegment]) -> TimedPhraseSegment? {
        guard !segments.isEmpty else { return nil }
        if currentPosition < line.startTime - 0.25 {
            return nil
        }
        for (i, seg) in segments.enumerated() {
            if currentPosition >= seg.startTime {
                if i + 1 < segments.count && currentPosition >= segments[i + 1].startTime {
                    continue
                }
                return seg
            }
        }
        return segments.last
    }
    
    // MARK: - 3-Slot Neighbors (Previous & Next Words)
    
    private func previousWordText(for word: TimedWord, in timedWords: [TimedWord]) -> String? {
        guard let idx = timedWords.firstIndex(where: { $0.id == word.id }) else { return nil }
        if idx > 0 {
            return timedWords[idx - 1].text
        }
        if let lyrics = appState.lyrics, let lineIdx = appState.activeLineIndex, lineIdx > 0 {
            let prevLine = lyrics.lines[lineIdx - 1]
            let prevWords = prevLine.timedWords(
                speedMultiplier: appState.pacingSpeedMultiplier,
                chunkPhrases: false
            )
            return prevWords.last?.text
        }
        return nil
    }
    
    private func nextWordText(for word: TimedWord, in timedWords: [TimedWord]) -> String? {
        guard let idx = timedWords.firstIndex(where: { $0.id == word.id }) else { return nil }
        if idx + 1 < timedWords.count {
            return timedWords[idx + 1].text
        }
        if let lyrics = appState.lyrics, let lineIdx = appState.activeLineIndex, lineIdx + 1 < lyrics.lines.count {
            let nextLine = lyrics.lines[lineIdx + 1]
            let nextWords = nextLine.timedWords(
                speedMultiplier: appState.pacingSpeedMultiplier,
                chunkPhrases: false
            )
            return nextWords.first?.text
        }
        return nil
    }
    
    // MARK: - Dynamic Organic Tilt
    
    private func organicTilt(for text: String) -> Angle {
        let hash = abs(text.hashValue)
        let angles: [Double] = [-4.0, 3.5, -2.5, 4.0, -3.0, 2.0, -1.5, 3.0]
        return .degrees(angles[hash % angles.count])
    }
}

// MARK: - Dynamic Font Size Helper

fileprivate func dynamicFontSize(for text: String) -> CGFloat {
    let length = text.count
    if length <= 5 {
        return 138 // Short phrases (e.g. "मेरी जान", "light")
    } else if length <= 10 {
        return 118 // Medium phrases (e.g. "days keep", "own way")
    } else if length <= 16 {
        return 96  // Extended phrases (e.g. "Wide horizons", "calling us")
    } else {
        return 78  // Multi-word phrases (e.g. "Soft rivers find their")
    }
}

// MARK: - Interactive Karaoke Word Pill Component

struct KaraokeWordPill: View {
    let word: TimedWord
    let isSung: Bool
    let font: Font
    let tilt: Angle
    let pendingColor: Color
    
    var body: some View {
        Text(word.text)
            .font(font)
            .tracking(1.0)
            .foregroundStyle(
                isSung
                    ? AnyShapeStyle(Color.white)
                    : AnyShapeStyle(pendingColor)
            )
            .shadow(
                color: isSung ? Color.white.opacity(0.95) : pendingColor.opacity(0.35),
                radius: isSung ? 18 : 8,
                x: 0,
                y: 0
            )
            .shadow(
                color: isSung ? Color.white.opacity(0.65) : Color.clear,
                radius: isSung ? 36 : 0,
                x: 0,
                y: 0
            )
            .scaleEffect(isSung ? 1.05 : 0.96)
            .rotationEffect(tilt)
            .animation(.spring(response: 0.32, dampingFraction: 0.62), value: isSung)
    }
}

// MARK: - Style B: Pop Kinetic Poster Subviews (With Word Ignition)

// 1. 🎟️ Solid Accent Banner Card
struct BannerCardPosterView: View {
    let segment: TimedPhraseSegment
    let currentPosition: TimeInterval
    let palette: ArtworkPalette
    let fontChoice: LyricFont
    let sectionName: String?
    
    var body: some View {
        let size = dynamicFontSize(for: segment.text)
        
        HStack(spacing: 34) {
            ForEach(segment.words) { word in
                let isSung = currentPosition >= word.startTime
                KaraokeWordPill(
                    word: word,
                    isSung: isSung,
                    font: fontChoice.font(size: size, weight: .black, sectionName: sectionName),
                    tilt: .degrees(-1.8),
                    pendingColor: Color.white.opacity(0.48)
                )
            }
        }
        .padding(.horizontal, 52)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [palette.primary, palette.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.40), radius: 26, x: 0, y: 14)
                .shadow(color: palette.primary.opacity(0.35), radius: 42, x: 0, y: 18)
        )
        .rotationEffect(.degrees(-1.8))
    }
}

// 2. 🎵 4-Corner Floating Musical Notes Frame
struct MusicalNotesPosterView: View {
    let segment: TimedPhraseSegment
    let currentPosition: TimeInterval
    let palette: ArtworkPalette
    let fontChoice: LyricFont
    let sectionName: String?
    
    @State private var notesFloating = false
    
    var body: some View {
        let size = dynamicFontSize(for: segment.text)
        
        HStack(alignment: .center, spacing: 44) {
            // Left Notes Column
            VStack(spacing: 36) {
                Text("♪")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(palette.accent)
                    .offset(y: notesFloating ? -8 : 8)
                    .rotationEffect(.degrees(notesFloating ? -15 : -5))
                
                Text("♫")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(palette.accent)
                    .offset(y: notesFloating ? 8 : -8)
                    .rotationEffect(.degrees(notesFloating ? 10 : -5))
            }
            
            // Words with Live Syllable Ignition
            HStack(spacing: 34) {
                ForEach(segment.words) { word in
                    let isSung = currentPosition >= word.startTime
                    KaraokeWordPill(
                        word: word,
                        isSung: isSung,
                        font: fontChoice.font(size: size, weight: .black, sectionName: sectionName),
                        tilt: .degrees(0),
                        pendingColor: palette.accent
                    )
                }
            }
            
            // Right Notes Column
            VStack(spacing: 36) {
                Text("♩")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(palette.accent)
                    .offset(y: notesFloating ? 8 : -8)
                    .rotationEffect(.degrees(notesFloating ? 15 : 5))
                
                Text("♪")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(palette.accent)
                    .offset(y: notesFloating ? -8 : 8)
                    .rotationEffect(.degrees(notesFloating ? -10 : 15))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                notesFloating = true
            }
        }
    }
}

// 3. 🌊 Undulating Wave Arch (Exact Match to "मेरी जान" Screenshot!)
struct WaveSplitPosterView: View {
    let segment: TimedPhraseSegment
    let currentPosition: TimeInterval
    let palette: ArtworkPalette
    let fontChoice: LyricFont
    let sectionName: String?
    
    var body: some View {
        let size = dynamicFontSize(for: segment.text)
        
        HStack(spacing: 34) {
            ForEach(Array(segment.words.enumerated()), id: \.element.id) { index, word in
                let isSung = currentPosition >= word.startTime
                // Subtle organic tilt like the user's "मेरी जान" screenshot (-4° on first word, +3° on second word)
                let tiltAngle: Angle = (index % 2 == 0) ? .degrees(-4.0) : .degrees(3.0)
                let yOffset: CGFloat = (index % 2 == 0) ? -6 : 6
                
                KaraokeWordPill(
                    word: word,
                    isSung: isSung,
                    font: fontChoice.font(size: size, weight: .black, sectionName: sectionName),
                    tilt: tiltAngle,
                    pendingColor: palette.accent
                )
                .offset(y: yOffset)
            }
        }
    }
}

// 4. ↗️ Diagonal Dynamic Kick
struct DiagonalKickPosterView: View {
    let segment: TimedPhraseSegment
    let currentPosition: TimeInterval
    let palette: ArtworkPalette
    let fontChoice: LyricFont
    let sectionName: String?
    
    var body: some View {
        let size = dynamicFontSize(for: segment.text)
        
        HStack(spacing: 34) {
            ForEach(segment.words) { word in
                let isSung = currentPosition >= word.startTime
                KaraokeWordPill(
                    word: word,
                    isSung: isSung,
                    font: fontChoice.font(size: size * 1.05, weight: .black, sectionName: sectionName),
                    tilt: .degrees(-14.0),
                    pendingColor: palette.accent
                )
            }
        }
        .offset(x: -25, y: -10)
    }
}

// 5. 🔄 3D Revolving Letter Flip
struct Flip3DPosterView: View {
    let segment: TimedPhraseSegment
    let currentPosition: TimeInterval
    let palette: ArtworkPalette
    let fontChoice: LyricFont
    let sectionName: String?
    
    @State private var isFlipped = false
    
    var body: some View {
        let size = dynamicFontSize(for: segment.text)
        
        HStack(spacing: 34) {
            ForEach(segment.words) { word in
                let isSung = currentPosition >= word.startTime
                KaraokeWordPill(
                    word: word,
                    isSung: isSung,
                    font: fontChoice.font(size: size, weight: .black, sectionName: sectionName),
                    tilt: .degrees(0),
                    pendingColor: palette.accent
                )
            }
        }
        .rotation3DEffect(
            .degrees(isFlipped ? 0 : 75),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.4
        )
        .scaleEffect(isFlipped ? 1.0 : 0.85)
        .onAppear {
            withAnimation(.spring(response: 0.50, dampingFraction: 0.70)) {
                isFlipped = true
            }
        }
    }
}

// MARK: - CleanShot Diagonal Staircase & Proper 5-Point Star Components

public struct ProperFivePointStarShape: Shape {
    public init() {}
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2.0
        let innerRadius = outerRadius * 0.40
        let count = 10
        let angleStep = Double.pi / 5.0
        let startAngle = -Double.pi / 2.0
        
        for i in 0..<count {
            let radius = (i % 2 == 0) ? outerRadius : innerRadius
            let angle = startAngle + Double(i) * angleStep
            let pt = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
        }
        path.closeSubpath()
        return path
    }
}

// 6. 🪜 Diagonal Staircase Cascade with Proper 5-Point Star Badge (CleanShot 12.30.31 PM)
struct StaircaseCascadePosterView: View {
    let segment: TimedPhraseSegment
    let currentPosition: TimeInterval
    let palette: ArtworkPalette
    let fontChoice: LyricFont
    let sectionName: String?
    
    @State private var starFloating = false
    
    var body: some View {
        let words = segment.words
        let count = max(words.count, 1)
        
        VStack(spacing: 8) {
            ForEach(Array(words.enumerated()), id: \.element.id) { index, word in
                stepWordRow(word: word, index: index, totalCount: count)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                starFloating = true
            }
        }
    }
    
    @ViewBuilder
    private func stepWordRow(word: TimedWord, index: Int, totalCount: Int) -> some View {
        let isLast = index == totalCount - 1
        let isSung = currentPosition >= word.startTime
        let stepOffset = calculateStepOffset(index: index, totalCount: totalCount)
        let hasArrived = (index == 0) || (currentPosition >= word.startTime - 0.04)
        
        Group {
            if isLast {
                let heroSize = calculateHeroSize(for: word.text)
                VStack(alignment: .trailing, spacing: 6) {
                    KaraokeWordPill(
                        word: word,
                        isSung: isSung,
                        font: fontChoice.font(size: heroSize, weight: .black, sectionName: sectionName),
                        tilt: .degrees(1.2),
                        pendingColor: palette.accent
                    )
                    
                    properStarSticker(isSung: isSung, hasArrived: hasArrived)
                }
            } else {
                let leadingSize = calculateHeroSize(for: word.text) * 0.62
                KaraokeWordPill(
                    word: word,
                    isSung: isSung,
                    font: fontChoice.font(size: leadingSize, weight: .bold, sectionName: sectionName),
                    tilt: .degrees(-1.8),
                    pendingColor: Color.white.opacity(0.48)
                )
            }
        }
        .offset(
            x: hasArrived ? stepOffset : (stepOffset - 28.0),
            y: hasArrived ? 0.0 : -34.0
        )
        .opacity(hasArrived ? 1.0 : 0.0)
        .scaleEffect(hasArrived ? 1.0 : 0.62)
        .animation(.spring(response: 0.40, dampingFraction: 0.65), value: hasArrived)
    }
    
    @ViewBuilder
    private func properStarSticker(isSung: Bool, hasArrived: Bool) -> some View {
        let fillGradient = LinearGradient(
            colors: [palette.accent, palette.primary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        let scaleVal: CGFloat = isSung ? 1.18 : (starFloating ? 1.05 : 0.94)
        let rotDeg: Double = isSung ? -20.0 : (starFloating ? -14.0 : -4.0)
        
        ProperFivePointStarShape()
            .fill(fillGradient)
            .overlay(
                ProperFivePointStarShape()
                    .stroke(Color.white.opacity(0.45), lineWidth: 1.2)
            )
            .frame(width: 44, height: 44)
            .rotationEffect(.degrees(hasArrived ? rotDeg : (rotDeg - 40.0)))
            .scaleEffect(hasArrived ? scaleVal : 0.1)
            .opacity(hasArrived ? 1.0 : 0.0)
            .shadow(color: palette.accent.opacity(0.65), radius: 14, x: 2, y: 6)
            .shadow(color: isSung ? Color.white.opacity(0.85) : Color.clear, radius: 18)
            .offset(x: -8, y: 2)
            .animation(.spring(response: 0.42, dampingFraction: 0.58).delay(0.06), value: hasArrived)
    }
    
    private func calculateStepOffset(index: Int, totalCount: Int) -> CGFloat {
        let centerIndex = Double(totalCount - 1) / 2.0
        let stepWidth: CGFloat = totalCount <= 2 ? 115.0 : 82.0
        return CGFloat(Double(index) - centerIndex) * stepWidth
    }
    
    private func calculateHeroSize(for text: String) -> CGFloat {
        if text.count > 8 {
            return 86.0
        } else if text.count > 5 {
            return 98.0
        } else {
            return 116.0
        }
    }
}

// MARK: - Style C: Solo Cinematic Stream Subviews

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
            Text(word.text)
                .font(fontChoice.font(size: size * 1.04, weight: .black, sectionName: sectionName))
                .tracking(7.0)
                .foregroundStyle(neonGlowColor.opacity(0.45))
                .blur(radius: 36)
                .scaleEffect(isZooming ? 1.20 : 0.92)
            
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

struct KineticTumbleWordView: View {
    let word: TimedWord
    let palette: ArtworkPalette
    let fontChoice: LyricFont
    let sectionName: String?
    
    @State private var isTumbled: Bool = false
    
    var body: some View {
        let size = dynamicFontSize(for: word.text)
        
        ZStack {
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .foregroundStyle(palette.accent.opacity(0.35))
                .blur(radius: 20)
                .offset(y: isTumbled ? 28 : 50)
                .scaleEffect(isTumbled ? 0.95 : 0.7)
            
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

struct EtherealSmokeFadeWordView: View {
    let word: TimedWord
    let palette: ArtworkPalette
    let fontChoice: LyricFont
    let sectionName: String?
    
    @State private var isMaterialized: Bool = false
    
    var body: some View {
        let size = dynamicFontSize(for: word.text)
        
        ZStack {
            Text(word.text)
                .font(fontChoice.font(size: size * 1.08, weight: .black, sectionName: sectionName))
                .foregroundStyle(palette.primary.opacity(0.40))
                .blur(radius: isMaterialized ? 22 : 40)
                .scaleEffect(isMaterialized ? 1.05 : 1.4)
                .opacity(isMaterialized ? 0.50 : 0.0)
            
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

struct HyperspaceImpactWordView: View {
    let word: TimedWord
    let palette: ArtworkPalette
    let fontChoice: LyricFont
    let sectionName: String?
    
    @State private var isImpacted: Bool = false
    
    var body: some View {
        let size = dynamicFontSize(for: word.text)
        
        ZStack {
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .foregroundStyle(palette.accent.opacity(0.35))
                .blur(radius: 8)
                .offset(y: isImpacted ? 4 : 22)
                .scaleEffect(isImpacted ? 1.0 : 1.3)
                .opacity(isImpacted ? 0.5 : 0.0)
            
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

struct PrismaticRollWordView: View {
    let word: TimedWord
    let palette: ArtworkPalette
    let fontChoice: LyricFont
    let sectionName: String?
    
    @State private var isRolled: Bool = false
    
    var body: some View {
        let size = dynamicFontSize(for: word.text)
        
        ZStack {
            Text(word.text)
                .font(fontChoice.font(size: size, weight: .black, sectionName: sectionName))
                .foregroundStyle(palette.accent.opacity(0.30))
                .blur(radius: 18)
                .scaleEffect(isRolled ? 1.05 : 0.9)
            
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
