import SwiftUI
import AppKit

public struct ImmersiveStudioView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var detector = MusicDetector.shared
    
    @State private var wavePhase: Double = 0
    @State private var timer: Timer?
    @State private var showControls: Bool = false
    @State private var hideControlsTimer: Timer?
    @State private var eventMonitor: Any?
    
    public init() {}
    
    public var body: some View {
        let currentPos = detector.currentTrack.position + detector.syncOffset
        
        ZStack {
            // 1. Living Album Cover Gradient Background
            LivingGradientBackground(palette: detector.currentTrack.palette, opacity: 1.0, showParticles: true)
                .ignoresSafeArea()
            
            // Atmospheric Vignette for deep depth & contrast
            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.35), Color.black.opacity(0.8)],
                center: .center,
                startRadius: 200,
                endRadius: 1000
            )
            .ignoresSafeArea()
            
            // 2. Solo Kinetic Word Canvas (One word moving with animation, synchronized with audio)
            ZStack {
                if let lyrics = appState.lyrics, !lyrics.lines.isEmpty {
                    let activeIdx = appState.activeLineIndex ?? 0
                    let currentLine = (activeIdx < lyrics.lines.count) ? lyrics.lines[activeIdx] : lyrics.lines[0]
                    
                    SoloKineticWordView(
                        line: currentLine,
                        currentPosition: currentPos,
                        palette: detector.currentTrack.palette,
                        fontChoice: appState.fontChoice,
                        wavePhase: wavePhase,
                        onSeek: {
                            detector.seek(to: currentLine.startTime)
                        }
                    )
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "music.note")
                            .font(.system(size: 70))
                            .foregroundStyle(detector.currentTrack.palette.accent)
                            .shadow(color: detector.currentTrack.palette.accent.opacity(0.6), radius: 30)
                        
                        Text("WAITING FOR MUSIC")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .tracking(3)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Play a track in Spotify or Apple Music, or pick a demo song in Settings.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.42, dampingFraction: 0.72), value: appState.activeLineIndex)
            
            // 3. Auto-Hiding Minimal Controls (Fades out when mouse is idle)
            VStack {
                // Top Exit Button Bar
                HStack {
                    Spacer()
                    Button(action: {
                        exitFullscreen()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.right.and.arrow.up.left")
                            Text("Exit Fullscreen (Esc)")
                        }
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(28)
                .opacity(showControls ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.25), value: showControls)
                
                Spacer()
                
                // Bottom Minimal Floating Scrubber
                HStack(spacing: 16) {
                    Button(action: { detector.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { detector.togglePlayPause() }) {
                        Image(systemName: detector.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(Color.white))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { detector.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    
                    // Mini Scrubber
                    Text(detector.currentTrack.formattedPosition)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.2))
                                .frame(height: 4)
                            Capsule()
                                .fill(detector.currentTrack.palette.accent)
                                .frame(width: geo.size.width * CGFloat(detector.currentTrack.progress), height: 4)
                        }
                        .frame(height: 14)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { val in
                                    let pct = min(max(val.location.x / geo.size.width, 0), 1)
                                    detector.seek(to: pct * detector.currentTrack.duration)
                                }
                        )
                    }
                    .frame(height: 14)
                    
                    Text(detector.currentTrack.formattedDuration)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
                .frame(maxWidth: 520)
                .padding(.bottom, 36)
                .opacity(showControls ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.25), value: showControls)
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            if hovering {
                triggerControlsVisibility()
            }
        }
        .onContinuousHover { _ in
            triggerControlsVisibility()
        }
        .onAppear {
            startAnimation()
            setupKeyboardMonitor()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
            hideControlsTimer?.invalidate()
            hideControlsTimer = nil
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
    }
    
    private func triggerControlsVisibility() {
        showControls = true
        hideControlsTimer?.invalidate()
        hideControlsTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                showControls = false
            }
        }
    }
    
    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if detector.currentTrack.isPlaying {
                wavePhase += 0.04
            }
        }
    }
    
    private func setupKeyboardMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Esc key (keyCode 53)
            if event.keyCode == 53 {
                exitFullscreen()
                return nil
            }
            // Spacebar (keyCode 49)
            if event.keyCode == 49 {
                detector.togglePlayPause()
                return nil
            }
            return event
        }
    }
    
    private func exitFullscreen() {
        appState.displayMode = .floatingWidget
        WindowManager.shared.switchMode(to: .floatingWidget)
    }
}
