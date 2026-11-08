import SwiftUI

public struct FloatingLyricsView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var detector = MusicDetector.shared
    
    @State private var isHeaderHovered: Bool = false
    @State private var isDraggingScrubber: Bool = false
    @State private var scrubPosition: Double = 0
    @State private var showSettingsSheet: Bool = false
    @State private var wavePhase: Double = 0
    @State private var waveTimer: Timer?
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // 0. Base Window Drag Area for the entire floating card
            WindowDragArea()
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            
            // 1. Living Album Cover Gradient Background
            LivingGradientBackground(palette: detector.currentTrack.palette, opacity: appState.backgroundOpacity, showParticles: true)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .allowsHitTesting(false)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.35),
                                    detector.currentTrack.palette.accent.opacity(0.4),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: Color.black.opacity(0.55), radius: 30, x: 0, y: 15)
                .shadow(color: detector.currentTrack.palette.accent.opacity(0.25), radius: 25, x: 0, y: 10)
            
            VStack(spacing: 0) {
                // Top Grab Handle Pill (Visual drag cue)
                HStack {
                    Spacer()
                    Capsule()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 38, height: 4)
                        .padding(.top, 8)
                        .padding(.bottom, 2)
                    Spacer()
                }
                .background(WindowDragArea())
                
                // Top Header: Song Info & Controls
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 12)
                    .background(WindowDragArea())
                
                Divider()
                    .background(Color.white.opacity(0.12))
                    .padding(.horizontal, 16)
                
                // Lyrics Content Area with Spatial Fly-In & Floating Wave
                lyricsContentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Divider()
                    .background(Color.white.opacity(0.12))
                    .padding(.horizontal, 16)
                
                // Bottom Bar: Progress Scrubber & Fine-Tuning
                bottomBarView
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(WindowDragArea())
            }
        }
        .frame(minWidth: 460, idealWidth: 520, minHeight: 500, idealHeight: 580)
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView()
        }
        .onAppear {
            waveTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                if detector.currentTrack.isPlaying {
                    wavePhase += 0.04
                }
            }
        }
        .onDisappear {
            waveTimer?.invalidate()
            waveTimer = nil
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 14) {
            // Album Art or Vinyl Icon
            ZStack {
                if let art = detector.currentTrack.artworkImage {
                    Image(nsImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: detector.currentTrack.palette.accent.opacity(0.4), radius: 6)
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.2), Color(white: 0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.black.opacity(0.4), radius: 4)
                    
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        .frame(width: 32, height: 32)
                    
                    Circle()
                        .fill(detector.currentTrack.palette.accent)
                        .frame(width: 14, height: 14)
                    
                    Image(systemName: detector.currentTrack.isPlaying ? "music.note" : "pause.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .rotationEffect(.degrees(detector.currentTrack.artworkImage == nil && detector.currentTrack.isPlaying ? 360 : 0))
            .animation(
                detector.currentTrack.isPlaying
                    ? .linear(duration: 8).repeatForever(autoreverses: false)
                    : .default,
                value: detector.currentTrack.isPlaying
            )
            
            // Song & Artist Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(detector.currentTrack.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if let verse = appState.currentVerseName {
                        Text(verse.uppercased())
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(detector.currentTrack.palette.accent.opacity(0.25))
                            .foregroundColor(detector.currentTrack.palette.accent)
                            .clipShape(Capsule())
                    }
                }
                
                Text(detector.currentTrack.artist)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Playback Controls
            HStack(spacing: 12) {
                Button(action: { detector.previousTrack() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                
                Button(action: { detector.togglePlayPause() }) {
                    Image(systemName: detector.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.white.opacity(0.15)))
                }
                .buttonStyle(.plain)
                
                Button(action: { detector.nextTrack() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 6)
            
            // Mode & Settings Buttons
            HStack(spacing: 8) {
                // Click-Through Lock toggle
                Button(action: {
                    appState.isClickThrough.toggle()
                    WindowManager.shared.updateClickThrough(appState.isClickThrough)
                }) {
                    Image(systemName: appState.isClickThrough ? "lock.fill" : "lock.open")
                        .font(.system(size: 12))
                        .foregroundColor(appState.isClickThrough ? detector.currentTrack.palette.accent : .white.opacity(0.6))
                        .padding(6)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .help(appState.isClickThrough ? "Click-Through Active (Locks overlay)" : "Click-Through Disabled")
                
                // Switch to Notch Island
                Button(action: {
                    appState.displayMode = .notchIsland
                    WindowManager.shared.switchMode(to: .notchIsland)
                }) {
                    Image(systemName: "capsule.portrait.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(6)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .help("Switch to Notch Island")
                
                // Fullscreen Immersive Studio
                Button(action: {
                    appState.displayMode = .immersiveStudio
                    WindowManager.shared.switchMode(to: .immersiveStudio)
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(6)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .help("Fullscreen Immersive Studio")
                
                // Settings Gear
                Button(action: { showSettingsSheet = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(6)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .help("Drift Settings")
            }
        }
    }
    
    // MARK: - Lyrics Content
    
    @ViewBuilder
    private var lyricsContentView: some View {
        if appState.isLoadingLyrics {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(detector.currentTrack.palette.accent)
                Text("Finding synchronized lyrics...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        } else if let lyrics = appState.lyrics, !lyrics.lines.isEmpty {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 14) {
                        Spacer().frame(height: 70)
                        
                        ForEach(Array(lyrics.lines.enumerated()), id: \.element.id) { index, line in
                            let currentPos = detector.currentTrack.position + detector.syncOffset
                            let prog = line.progress(at: currentPos)
                            
                            LyricRowView(
                                line: line,
                                index: index,
                                activeLineIndex: appState.activeLineIndex,
                                progress: prog,
                                fontChoice: appState.fontChoice,
                                fontSize: appState.fontSize,
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
                        
                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 16)
                }
                .onChange(of: appState.activeLineIndex) { _, newIndex in
                    if let idx = newIndex, idx < lyrics.lines.count {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            proxy.scrollTo(lyrics.lines[idx].id, anchor: .center)
                        }
                    }
                }
            }
        } else {
            // Empty / Fallback view
            VStack(spacing: 14) {
                Image(systemName: "music.quarternote.3")
                    .font(.system(size: 40))
                    .foregroundColor(detector.currentTrack.palette.accent.opacity(0.8))
                
                Text("No Synced Lyrics Found")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Play a song in Spotify or Apple Music, or pick a demo hit song.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                HStack(spacing: 10) {
                    Button(action: {
                        detector.loadDemoTrack(index: 0, autoPlay: true)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.circle.fill")
                            Text("Play Demo (The Weeknd)")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(detector.currentTrack.palette.accent)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { showSettingsSheet = true }) {
                        Text("Search Song")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Bottom Bar
    
    private var bottomBarView: some View {
        VStack(spacing: 8) {
            // Track Scrubber Slider
            HStack(spacing: 8) {
                Text(detector.currentTrack.formattedPosition)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 36, alignment: .leading)
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [detector.currentTrack.palette.primary, detector.currentTrack.palette.accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(detector.currentTrack.progress), height: 4)
                    }
                    .frame(height: 16)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { val in
                                let pct = min(max(val.location.x / geo.size.width, 0), 1)
                                let target = pct * detector.currentTrack.duration
                                detector.seek(to: target)
                            }
                    )
                }
                .frame(height: 16)
                
                Text(detector.currentTrack.formattedDuration)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 36, alignment: .trailing)
            }
            
            // Audio Visualizer Waveform & Offset Calibration
            HStack {
                if appState.showWaveform {
                    AudioVisualizerView(
                        levels: appState.spectrumLevels,
                        accentColor: detector.currentTrack.palette.accent,
                        barWidth: 2.5,
                        spacing: 2,
                        maxHeight: 14
                    )
                }
                
                Spacer()
                
                // Sync Tuning
                HStack(spacing: 4) {
                    Text("Sync:")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Button(action: {
                        detector.syncOffset -= 0.2
                    }) {
                        Text("-0.2s")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                    
                    Text(String(format: "%+.1fs", detector.syncOffset))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(detector.syncOffset != 0 ? detector.currentTrack.palette.accent : .white.opacity(0.6))
                        .frame(width: 40)
                    
                    Button(action: {
                        detector.syncOffset += 0.2
                    }) {
                        Text("+0.2s")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
