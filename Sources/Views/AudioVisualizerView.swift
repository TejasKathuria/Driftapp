import SwiftUI

public struct AudioVisualizerView: View {
    let levels: [CGFloat]
    let accentColor: Color
    var barWidth: CGFloat = 3
    var spacing: CGFloat = 2
    var maxHeight: CGFloat = 20
    
    public init(levels: [CGFloat], accentColor: Color, barWidth: CGFloat = 3, spacing: CGFloat = 2, maxHeight: CGFloat = 20) {
        self.levels = levels
        self.accentColor = accentColor
        self.barWidth = barWidth
        self.spacing = spacing
        self.maxHeight = maxHeight
    }
    
    public var body: some View {
        HStack(alignment: .bottom, spacing: spacing) {
            ForEach(0..<levels.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: barWidth / 2)
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.6), accentColor],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: barWidth, height: max(3, levels[i] * maxHeight))
                    .animation(.spring(response: 0.15, dampingFraction: 0.6), value: levels[i])
            }
        }
    }
}

