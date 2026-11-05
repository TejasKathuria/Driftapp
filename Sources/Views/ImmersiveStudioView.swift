import SwiftUI

public struct ImmersiveStudioView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var detector = MusicDetector.shared
    
    @State private var gradientPhase: CGFloat = 0
    @State private var timer: Timer?
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Living Fluid Gradient Background
            livingGradientBackground
                .ignoresSafeArea()
            
            // Subtle dark vignette layer for maximum text readability
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Content Layout
            HStack(spacing: 60) {
                // Left Column: Album Art, Info & Full Controls
                leftPlayerColumn
                    .frame(width: 360)
                
                // Right Column: Apple Music Style Fullscreen Lyrics
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
                        .foregroundColor(.white.opacity(0.8))
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
            startGradientAnimation()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    // MARK: - Living Gradient
    
    private var livingGradientBackground: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                
                // Color blob 1
                Circle()
                    .fill(detector.currentTrack.accentColor.opacity(0.45))
                    .frame(width: geo.size.width * 0.7, height: geo.size.width * 0.7)
                    .blur(radius: 120)
                    .offset(
                        x: sin(gradientPhase) * 150 - 100,
                        y: cos(gradientPhase * 0.8) * 120 - 100
                    )
                
                // Color blob 2
                Circle()
                    .fill(Color(red: 0.1, green: 0.2, blue: 0.6).opacity(0.5))
                    .frame(width: geo.size.width * 0.65, height: geo.size.width * 0.65)
                    .blur(radius: 140)
                    .offset(
                        x: cos(gradientPhase * 1.2) * 200 + 150,
                        y: sin(gradientPhase) * 150 + 100
                    )
                
                // Color blob 3
                Circle()
                    .fill(Color(red: 0.7, green: 0.1, blue: 0.5).opacity(0.35))
                    .frame(width: geo.size.width * 0.6, height: geo.size.width * 0.6)
                    .blur(radius: 130)
                    .offset(
                        x: sin(gradientPhase * 0.7) * 180,
                        y: cos(gradientPhase * 1.1) * 200
                    )
            }
        }
    }
    
    private func startGradientAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            gradientPhase += 0.015
        }
    }
    
    // MARK: - Left Player Column
    
    private var leftPlayerColumn: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            
            // Big Album Art
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.2), Color(white: 0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .shadow(color: Color.black.opacity(0.6), radius: 35, x: 0, y: 20)
                    .shadow(color: detector.currentTrack.accentColor.opacity(0.3), radius: 30, x: 0, y: 15)
                
                VStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(detector.currentTrack.accentColor)
                    
                    if let verse = appState.currentVerseName {
                        Text(verse.uppercased())
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .tracking(2)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(detector.currentTrack.accentColor.opacity(0.3))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
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
                            .fill(detector.currentTrack.accentColor)
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
                    accentColor: detector.currentTrack.accentColor,
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
                        LazyVStack(alignment: .leading, spacing: 20) {
                            Spacer().frame(height: 200)
                            
                            ForEach(Array(lyrics.lines.enumerated()), id: \.element.id) { index, line in
                                let isActive = (index == appState.activeLineIndex)
                                let currentPos = detector.currentTrack.position + detector.syncOffset
                                let prog = line.progress(at: currentPos)
                                
                                LyricRowView(
                                    line: line,
                                    isActive: isActive,
                                    progress: prog,
                                    fontChoice: appState.fontChoice,
                                    fontSize: 34,
                                    theme: appState.colorTheme,
                                    accentColor: detector.currentTrack.accentColor,
                                    karaokeSweep: appState.karaokeProgressSweep,
                                    onSeek: {
                                        detector.seek(to: line.startTime)
                                    }
                                )
                                .id(line.id)
                            }
                            
                            Spacer().frame(height: 300)
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
                        .foregroundColor(detector.currentTrack.accentColor.opacity(0.7))
                    Text("No synchronized lyrics available")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                }
            }
        }
    }
}
