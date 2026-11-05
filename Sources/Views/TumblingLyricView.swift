import SwiftUI

public struct TumblingWord: Identifiable {
    public let id: String
    public let text: String
    public let index: Int
    public let tiltAngle: Angle
    public let xStagger: CGFloat
    public let hasStickerBox: Bool
    
    public init(text: String, index: Int, lineId: String) {
        self.id = "\(lineId)-word-\(index)-\(text)"
        self.text = text
        self.index = index
        
        // Organic tumbling tilt angles (-8° to +8°) matching the reference style
        let hash = abs("\(text)-\(index)".hashValue)
        let angles: [Double] = [-6.5, 4.2, -4.8, 5.5, -7.2, 3.8, -3.5, 6.0, -5.0]
        self.tiltAngle = .degrees(angles[hash % angles.count])
        
        // Staggered horizontal positioning
        let staggers: [CGFloat] = [-30, 25, -15, 35, -40, 20, 0, -25, 30]
        self.xStagger = staggers[hash % staggers.count]
        
        // Key words get vibrant sticker tape boxes (like "my" in the user's reference image)
        self.hasStickerBox = (index % 2 == 1) || (text.count <= 3) || (hash % 3 == 0)
    }
}

public struct TumblingLyricView: View {
    let line: LyricLine
    let isActive: Bool
    let progress: Double
    let palette: ArtworkPalette
    let fontChoice: LyricFont
    let wavePhase: Double
    let onSeek: () -> Void
    
    @State private var appearAnimation: Bool = false
    
    public var body: some View {
        let rawWords = line.text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let tumblingWords = rawWords.enumerated().map { TumblingWord(text: $1, index: $0, lineId: line.id.uuidString) }
        let activeWordIdx = min(max(Int(progress * Double(tumblingWords.count)), 0), max(tumblingWords.count - 1, 0))
        
        VStack(spacing: 18) {
            // Section Tag Badge if present
            if let section = line.sectionName, !section.isEmpty {
                Text(section.uppercased())
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .tracking(2.5)
                    .foregroundStyle(palette.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(palette.primary.opacity(0.3))
                            .overlay(Capsule().stroke(palette.accent.opacity(0.6), lineWidth: 1.2))
                    )
                    .shadow(color: palette.accent.opacity(0.5), radius: 10)
                    .padding(.bottom, 8)
            }
            
            // Staggered Tumbling Word Stack
            ForEach(tumblingWords) { word in
                let isWordActive = (word.index == activeWordIdx)
                let isWordPassed = (word.index < activeWordIdx)
                
                tumblingWordView(
                    word: word,
                    isWordActive: isWordActive,
                    isWordPassed: isWordPassed,
                    totalWords: tumblingWords.count
                )
                .offset(x: word.xStagger)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSeek()
        }
    }
    
    // MARK: - Individual Tumbling Word with Sticker Box
    
    @ViewBuilder
    private func tumblingWordView(
        word: TumblingWord,
        isWordActive: Bool,
        isWordPassed: Bool,
        totalWords: Int
    ) -> some View {
        // Dynamic floating tumble wave
        let waveBounce = sin(wavePhase * 3.2 + Double(word.index) * 0.8) * 4.5
        let currentTilt = word.tiltAngle + .degrees(sin(wavePhase * 2.0 + Double(word.index)) * 1.5)
        
        let textColor: Color = {
            if isWordActive {
                return word.hasStickerBox ? Color.white : palette.accent
            } else if isWordPassed {
                return Color.white.opacity(0.85)
            } else {
                return Color.white.opacity(0.40)
            }
        }()
        
        ZStack {
            // Sticker Box Card (matching user reference image where words like "my" have a colored background block!)
            if word.hasStickerBox {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        isWordActive
                            ? AnyShapeStyle(palette.accentGradient)
                            : AnyShapeStyle(Color.black.opacity(0.45))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                isWordActive
                                    ? palette.accent.opacity(0.8)
                                    : Color.white.opacity(0.12),
                                lineWidth: isWordActive ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isWordActive ? palette.primary.opacity(0.8) : Color.black.opacity(0.4),
                        radius: isWordActive ? 25 : 8,
                        x: 0,
                        y: isWordActive ? 8 : 4
                    )
                    .scaleEffect(isWordActive ? 1.08 : 1.0)
            }
            
            // Giant Bold Typography
            Text(word.text)
                .font(fontChoice.font(size: isWordActive ? 74 : 64, weight: .black, sectionName: line.sectionName))
                .tracking(0.5)
                .foregroundStyle(textColor)
                .shadow(
                    color: isWordActive ? palette.accent.opacity(0.9) : Color.black.opacity(0.6),
                    radius: isWordActive ? 20 : 6,
                    x: 0,
                    y: isWordActive ? 0 : 3
                )
                .padding(.horizontal, word.hasStickerBox ? 22 : 8)
                .padding(.vertical, word.hasStickerBox ? 10 : 4)
        }
        // Tumbling Spatial Physics: Tilt, Scale, Wave Bounce & 3D Depth
        .rotationEffect(currentTilt)
        .rotation3DEffect(
            .degrees(isWordActive ? sin(wavePhase * 2.5) * 6 : 0),
            axis: (x: 1, y: 0.2, z: 0)
        )
        .scaleEffect(isWordActive ? 1.12 : (isWordPassed ? 1.02 : 0.95))
        .offset(y: waveBounce)
        .animation(.spring(response: 0.38, dampingFraction: 0.62), value: isWordActive)
    }
}
