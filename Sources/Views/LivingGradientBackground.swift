import SwiftUI

public struct LivingGradientBackground: View {
    let palette: ArtworkPalette
    let opacity: Double
    let showParticles: Bool
    
    @State private var phase: Double = 0
    @State private var timer: Timer?
    
    public init(palette: ArtworkPalette, opacity: Double = 0.85, showParticles: Bool = true) {
        self.palette = palette
        self.opacity = opacity
        self.showParticles = showParticles
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base Dark Fluid Tint
                palette.backgroundDark
                
                // Living Color Orb 1: Primary Album Art Color (Top-Left / Center Drift)
                Circle()
                    .fill(palette.primary.opacity(0.48))
                    .frame(width: geo.size.width * 0.75, height: geo.size.width * 0.75)
                    .blur(radius: 110)
                    .offset(
                        x: sin(phase * 0.7) * (geo.size.width * 0.25) - geo.size.width * 0.15,
                        y: cos(phase * 0.5) * (geo.size.height * 0.2) - geo.size.height * 0.15
                    )
                
                // Living Color Orb 2: Secondary Album Art Color (Bottom-Right Drift)
                Circle()
                    .fill(palette.secondary.opacity(0.42))
                    .frame(width: geo.size.width * 0.7, height: geo.size.width * 0.7)
                    .blur(radius: 120)
                    .offset(
                        x: cos(phase * 0.8) * (geo.size.width * 0.3) + geo.size.width * 0.15,
                        y: sin(phase * 0.6) * (geo.size.height * 0.25) + geo.size.height * 0.15
                    )
                
                // Living Color Orb 3: Luminous Accent Flare (Rotating Orbital)
                Circle()
                    .fill(palette.accent.opacity(0.35))
                    .frame(width: geo.size.width * 0.5, height: geo.size.width * 0.5)
                    .blur(radius: 95)
                    .offset(
                        x: sin(phase * 1.1) * (geo.size.width * 0.22),
                        y: cos(phase * 1.1) * (geo.size.height * 0.22)
                    )
                
                // Atmospheric Dark Vignette
                RadialGradient(
                    colors: [Color.clear, palette.backgroundDark.opacity(0.65), palette.backgroundDark.opacity(0.95)],
                    center: .center,
                    startRadius: geo.size.width * 0.2,
                    endRadius: geo.size.width * 0.85
                )
                
                // Ambient Stardust Particles
                if showParticles {
                    AmbientParticlesView(accentColor: palette.accent, phase: phase)
                }
            }
        }
        .opacity(opacity)
        .animation(.easeInOut(duration: 1.2), value: palette)
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                phase += 0.015
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}

// Subtle floating bokeh particles
struct AmbientParticlesView: View {
    let accentColor: Color
    let phase: Double
    
    let particles: [(x: CGFloat, y: CGFloat, size: CGFloat, speed: Double)] = [
        (0.15, 0.20, 4.0, 1.2),
        (0.80, 0.25, 3.0, 0.8),
        (0.35, 0.75, 5.0, 1.5),
        (0.70, 0.80, 3.5, 0.9),
        (0.50, 0.40, 4.5, 1.1),
        (0.20, 0.60, 2.5, 0.7),
        (0.85, 0.65, 4.0, 1.3)
    ]
    
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<particles.count, id: \.self) { i in
                let p = particles[i]
                let yOffset = sin(phase * p.speed + Double(i)) * 25
                let xOffset = cos(phase * p.speed * 0.7 + Double(i)) * 20
                
                Circle()
                    .fill(accentColor.opacity(0.45))
                    .frame(width: p.size, height: p.size)
                    .blur(radius: 1.5)
                    .position(
                        x: geo.size.width * p.x + CGFloat(xOffset),
                        y: geo.size.height * p.y + CGFloat(yOffset)
                    )
            }
        }
    }
}

