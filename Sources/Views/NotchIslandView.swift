import SwiftUI

public struct NotchIslandView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var detector = MusicDetector.shared
    
    @State private var isHovered: Bool = false
    
    public init() {}
    
    public var body: some View {
        let activeLine = currentActiveLine()
        let nextLine = nextUpcomingLine()
        
        VStack(spacing: 0) {
            // Main Island Capsule Bar
            HStack(spacing: 12) {
                // Spinning Vinyl / Album art
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.8))
                        .frame(width: 26, height: 26)
                    Circle()
                        .stroke(detector.currentTrack.accentColor.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    Circle()
                        .fill(detector.currentTrack.accentColor)
                        .frame(width: 8, height: 8)
                }
                .rotationEffect(.degrees(detector.currentTrack.isPlaying ? 360 : 0))
                .animation(
                    detector.currentTrack.isPlaying
                        ? .linear(duration: 6).repeatForever(autoreverses: false)
                        : .default,
                    value: detector.currentTrack.isPlaying
                )
                
                // Active Lyric Text or Song Title
                VStack(alignment: .leading, spacing: 2) {
                    if let line = activeLine {
                        HStack(spacing: 6) {
                            if let sec = line.sectionName {
                                Text(sec.uppercased())
                                    .font(.system(size: 8, weight: .black, design: .rounded))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1.5)
                                    .background(detector.currentTrack.accentColor.opacity(0.3))
                                    .foregroundColor(detector.currentTrack.accentColor)
                                    .clipShape(Capsule())
                            }
                            
                            Text(line.text)
                                .font(appState.fontChoice.font(size: 14, weight: .bold))
                                .foregroundStyle(appState.colorTheme.activeGradient(for: detector.currentTrack.accentColor))
                                .shadow(color: detector.currentTrack.accentColor.opacity(0.4), radius: 6)
                                .lineLimit(1)
                        }
                    } else {
                        Text("\(detector.currentTrack.title) • \(detector.currentTrack.artist)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                    }
                }
                
                Spacer(minLength: 8)
                
                // Mini Waveform
                AudioVisualizerView(
                    levels: Array(appState.spectrumLevels.prefix(10)),
                    accentColor: detector.currentTrack.accentColor,
                    barWidth: 2,
                    spacing: 1.5,
                    maxHeight: 12
                )
                
                // Play / Pause Mini Button
                Button(action: { detector.togglePlayPause() }) {
                    Image(systemName: detector.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.white.opacity(0.18)))
                }
                .buttonStyle(.plain)
                
                // Switch back to floating window
                Button(action: {
                    appState.displayMode = .floatingWidget
                    WindowManager.shared.switchMode(to: .floatingWidget)
                }) {
                    Image(systemName: "rectangle.fill.on.rectangle.angled.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .help("Expand to Floating HUD")
            }
            .padding(.horizontal, 14)
            .frame(height: 38)
            
            // Expanded Island view on hover
            if isHovered {
                VStack(spacing: 8) {
                    Divider()
                        .background(Color.white.opacity(0.12))
                        .padding(.horizontal, 10)
                    
                    if let next = nextLine {
                        HStack {
                            Text("NEXT:")
                                .font(.system(size: 8, weight: .heavy, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                            Text(next.text)
                                .font(appState.fontChoice.font(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Progress bar
                    HStack(spacing: 8) {
                        Text(detector.currentTrack.formattedPosition)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.2))
                                Capsule()
                                    .fill(detector.currentTrack.accentColor)
                                    .frame(width: geo.size.width * CGFloat(detector.currentTrack.progress))
                            }
                        }
                        .frame(height: 3)
                        
                        Text(detector.currentTrack.formattedDuration)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .background(Capsule().fill(Color.black.opacity(0.85)))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), detector.currentTrack.accentColor.opacity(0.4), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.6), radius: 15, x: 0, y: 8)
        )
        .frame(width: isHovered ? 480 : 440)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private func currentActiveLine() -> LyricLine? {
        guard let lyrics = appState.lyrics, let idx = appState.activeLineIndex, idx < lyrics.lines.count else {
            return nil
        }
        return lyrics.lines[idx]
    }
    
    private func nextUpcomingLine() -> LyricLine? {
        guard let lyrics = appState.lyrics, let idx = appState.activeLineIndex, idx + 1 < lyrics.lines.count else {
            return nil
        }
        return lyrics.lines[idx + 1]
    }
}
