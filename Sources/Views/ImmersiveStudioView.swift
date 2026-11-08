import SwiftUI
import AppKit

public struct ImmersiveStudioView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var detector = MusicDetector.shared
    
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
                        wavePhase: 0,
                        onSeek: {
                            detector.seek(to: currentLine.startTime)
                        }
                    )
                    .id(activeIdx)
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
                // Top Exit & Style Switcher Bar
                HStack(spacing: 12) {
                    Spacer()
                    
                    // Mirror to External Display Pill
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            appState.mirrorOnExternalDisplay.toggle()
                            WindowManager.shared.updateExternalDisplayMirroring()
                        }
                    }) {
                        HStack(spacing: 7) {
                            Image(systemName: appState.mirrorOnExternalDisplay ? "display.2" : "display")
                            Text(appState.mirrorOnExternalDisplay ? "Mirroring: On" : "Mirror to External")
                        }
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(appState.mirrorOnExternalDisplay ? detector.currentTrack.palette.accent : .white.opacity(0.92))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(appState.mirrorOnExternalDisplay ? detector.currentTrack.palette.accent.opacity(0.8) : Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 10)
                    }
                    .buttonStyle(.plain)
                    .help(appState.mirrorOnExternalDisplay ? "Disable mirroring on external display" : "Mirror fullscreen on connected external displays")
                    
                    // Style Switcher Pill
                    Button(action: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            let all = KineticAnimationStyle.allCases
                            if let idx = all.firstIndex(of: appState.kineticStyle) {
                                let nextIdx = (idx + 1) % all.count
                                appState.kineticStyle = all[nextIdx]
                            }
                        }
                    }) {
                        HStack(spacing: 7) {
                            Image(systemName: appState.kineticStyle.icon)
                            Text("Style: \(styleShortName(appState.kineticStyle))")
                        }
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 10)
                    }
                    .buttonStyle(.plain)
                    
                    // Exit Fullscreen Button
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
            setupKeyboardMonitor()
        }
        .onDisappear {
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
    
    private func styleShortName(_ style: KineticAnimationStyle) -> String {
        switch style {
        case .threeSlotReel: return "3-Slot Reel"
        case .popPosterCanvas: return "Pop Posters"
        case .staircaseCascade: return "Staircase"
        case .soloCinematicStream: return "Solo Cinematic"
        }
    }
}
