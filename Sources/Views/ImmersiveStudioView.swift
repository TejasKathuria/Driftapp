import SwiftUI

public struct ImmersiveStudioView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var detector = MusicDetector.shared
    
    @State private var wavePhase: CGFloat = 0
    @State private var timer: Timer?
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Living Album Cover Gradient Background
            LivingGradientBackground(palette: detector.currentTrack.palette, opacity: 1.0, showParticles: true)
                .ignoresSafeArea()
            
            // Subtle dark vignette layer for maximum text readability
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            
            // Content Layout
            HStack(spacing: 60) {
                // Left Column: Album Art, Info & Full Controls
                leftPlayerColumn
                    .frame(width: 360)
                
                // Right Column: Apple Music Style Fullscreen Lyrics with Spatial Animations
                rightLyricsColumn
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(48)
            
            // Top Right Controls (Exit Fullscreen)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        appState.displayMode = .floatingWidget
                        WindowManager.shared.switchMode(to: .floatingWidget)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.right.and.arrow.up.left")
                            Text("Exit Fullscreen (Esc)")
                        }
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(24)
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if detector.currentTrack.isPlaying {
                wavePhase += 0.04
            }
        }
    }
    
    // MARK: - Left Player Column
    
    private var leftPlayerColumn: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            
            // High-Resolution Album Art
            ZStack {
                if let art = detector.currentTrack.artworkImage {
                    Image(nsImage: art)
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1.2)
                        )
                        .shadow(color: Color.black.opacity(0.6), radius: 35, x: 0, y: 20)
                        .shadow(color: detector.currentTrack.palette.primary.opacity(0.4), radius: 35, x: 0, y: 15)
                } else {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [detector.currentTrack.palette.backgroundMid, detector.currentTrack.palette.backgroundDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .stroke(detector.currentTrack.palette.accent.opacity(0.3), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.6), radius: 35, x: 0, y: 20)
                        .shadow(color: detector.currentTrack.palette.accent.opacity(0.3), radius: 30, x: 0, y: 15)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .font(.system(size: 64, weight: .light))
                            .foregroundColor(detector.currentTrack.palette.accent)
                        
                        if let verse = appState.currentVerseName {
                            Text(verse.uppercased())
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .tracking(2)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(detector.currentTrack.palette.accent.opacity(0.3))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .frame(maxWidth: 320)
            
            // Track Info
            VStack(alignment: .leading, spacing: 6) {
                Text(detector.currentTrack.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(detector.currentTrack.artist)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                
                if !detector.currentTrack.album.isEmpty {
                    Text(detector.currentTrack.album)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.45))
                        .lineLimit(1)
                }
            }
            
            // Scrubber
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.2))
                            .frame(height: 6)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [detector.currentTrack.palette.primary, detector.currentTrack.palette.accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(detector.currentTrack.progress), height: 6)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { val in
                                let pct = min(max(val.location.x / geo.size.width, 0), 1)
                                detector.seek(to: pct * detector.currentTrack.duration)
                            }
                    )
                }
                .frame(height: 12)
                
                HStack {
                    Text(detector.currentTrack.formattedPosition)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    Text(detector.currentTrack.formattedDuration)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Full Transport Controls
            HStack(spacing: 28) {
                Button(action: { detector.previousTrack() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
                
                Button(action: { detector.togglePlayPause() }) {
                    Image(systemName: detector.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(Color.white))
                        .shadow(color: Color.white.opacity(0.3), radius: 10)
                }
                .buttonStyle(.plain)
                
                Button(action: { detector.nextTrack() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                AudioVisualizerView(
                    levels: appState.spectrumLevels,
                    accentColor: detector.currentTrack.palette.accent,
                    barWidth: 3,
                    spacing: 2,
                    maxHeight: 24
                )
            }
            
            Spacer()
        }
    }
    
    // MARK: - Right Lyrics Column
    
    private var rightLyricsColumn: some View {
        VStack {
            if let lyrics = appState.lyrics, !lyrics.lines.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 22) {
                            Spacer().frame(height: 180)
                            
                            ForEach(Array(lyrics.lines.enumerated()), id: \.element.id) { index, line in
                                let currentPos = detector.currentTrack.position + detector.syncOffset
                                let prog = line.progress(at: currentPos)
                                
                                LyricRowView(
                                    line: line,
                                    index: index,
                                    activeLineIndex: appState.activeLineIndex,
                                    progress: prog,
                                    fontChoice: appState.fontChoice,
                                    fontSize: 34,
                                    theme: appState.colorTheme,
                                    palette: detector.currentTrack.palette,
                                    karaokeSweep: appState.karaokeProgressSweep,
                                    wavePhase: wavePhase,
                                    onSeek: {
                                        detector.seek(to: line.startTime)
                                    }
                                )
                                .id(line.id)
                            }
                            
                            Spacer().frame(height: 280)
                        }
                    }
                    .onChange(of: appState.activeLineIndex) { _, newIndex in
                        if let idx = newIndex, idx < lyrics.lines.count {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                proxy.scrollTo(lyrics.lines[idx].id, anchor: .center)
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "music.note.list")
                        .font(.system(size: 60))
                        .foregroundColor(detector.currentTrack.palette.accent.opacity(0.7))
                    Text("No synchronized lyrics available")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                }
            }
        }
    }
}
