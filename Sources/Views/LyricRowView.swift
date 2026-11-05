import SwiftUI

public struct LyricRowView: View {
    let line: LyricLine
    let isActive: Bool
    let progress: Double
    let fontChoice: LyricFont
    let fontSize: CGFloat
    let theme: DriftColorTheme
    let accentColor: Color
    let karaokeSweep: Bool
    let onSeek: () -> Void
    
    @State private var isHovered: Bool = false
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Verse Section Badge (e.g., [Chorus], [Verse 2])
            if let section = line.sectionName, !section.isEmpty {
                Text(section.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(isActive ? accentColor : Color.white.opacity(0.4))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(isActive ? accentColor.opacity(0.2) : Color.white.opacity(0.08))
                    )
                    .padding(.bottom, 2)
            }
            
            // Lyric Line Content
            Button(action: onSeek) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    // Lyric Text with optional Karaoke Sweep
                    if isActive && karaokeSweep {
                        karaokeText
                    } else {
                        standardText
                    }
                    
                    Spacer(minLength: 0)
                    
                    // Timestamp on hover or when active
                    if isHovered {
                        Text(line.formattedStartTime)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .transition(.opacity)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, isActive ? 10 : 6)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? Color.white.opacity(0.06) : (isHovered ? Color.white.opacity(0.03) : Color.clear))
        )
        .scaleEffect(isActive ? 1.02 : (isHovered ? 1.01 : 1.0))
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isActive)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    @ViewBuilder
    private var standardText: some View {
        Text(line.text)
            .font(fontChoice.font(size: isActive ? fontSize : fontSize * 0.85, weight: isActive ? .bold : .medium))
            .foregroundStyle(
                isActive
                ? AnyShapeStyle(theme.activeGradient(for: accentColor))
                : AnyShapeStyle(Color.white.opacity(isHovered ? 0.75 : 0.40))
            )
            .shadow(color: isActive ? theme.glowColor(for: accentColor).opacity(0.5) : Color.clear, radius: 10, x: 0, y: 0)
            .multilineTextAlignment(.leading)
            .blur(radius: isActive ? 0 : 0.2)
    }
    
    // Dynamic Karaoke Fill: As the line plays, text sweeps with vibrant color from left to right
    @ViewBuilder
    private var karaokeText: some View {
        ZStack(alignment: .leading) {
            // Background inactive text
            Text(line.text)
                .font(fontChoice.font(size: fontSize, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.35))
            
            // Foreground sweeping active text
            Text(line.text)
                .font(fontChoice.font(size: fontSize, weight: .bold))
                .foregroundStyle(theme.activeGradient(for: accentColor))
                .shadow(color: theme.glowColor(for: accentColor).opacity(0.6), radius: 12, x: 0, y: 0)
                .mask(
                    GeometryReader { geo in
                        Rectangle()
                            .frame(width: geo.size.width * CGFloat(min(max(progress, 0.0), 1.0)))
                    }
                )
        }
        .multilineTextAlignment(.leading)
    }
}
