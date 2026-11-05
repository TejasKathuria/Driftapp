import AppKit
import CoreGraphics

func createIcon() {
    let size = CGSize(width: 1024, height: 1024)
    let image = NSImage(size: size)
    
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { return }
    
    // 1. Squircle background clipping
    let rect = CGRect(origin: .zero, size: size).insetBy(dx: 48, dy: 48)
    let squircle = CGPath(roundedRect: rect, cornerWidth: 220, cornerHeight: 220, transform: nil)
    ctx.addPath(squircle)
    ctx.clip()
    
    // 2. Base Dark Liquid Gradient
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        NSColor(red: 0.07, green: 0.08, blue: 0.16, alpha: 1.0).cgColor,
        NSColor(red: 0.12, green: 0.05, blue: 0.22, alpha: 1.0).cgColor,
        NSColor(red: 0.02, green: 0.02, blue: 0.06, alpha: 1.0).cgColor
    ] as CFArray
    let bgLocations: [CGFloat] = [0.0, 0.5, 1.0]
    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
        ctx.drawLinearGradient(bgGradient, start: CGPoint(x: 0, y: 1024), end: CGPoint(x: 1024, y: 0), options: [])
    }
    
    // 3. Ambient Vibrant Glow Blobs
    ctx.saveGState()
    let glowColors = [
        NSColor(red: 1.0, green: 0.2, blue: 0.6, alpha: 0.6).cgColor,
        NSColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.0).cgColor
    ] as CFArray
    if let radial = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(radial, startCenter: CGPoint(x: 350, y: 700), startRadius: 20, endCenter: CGPoint(x: 350, y: 700), endRadius: 360, options: [])
    }
    ctx.restoreGState()
    
    // 4. Stylized Glowing Lyric Waves & Music Note
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: 10), blur: 30, color: NSColor(red: 1.0, green: 0.3, blue: 0.7, alpha: 0.8).cgColor)
    
    // Glass vinyl disc ring
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.2).cgColor)
    ctx.setLineWidth(16)
    ctx.strokeEllipse(in: CGRect(x: 312, y: 312, width: 400, height: 400))
    
    ctx.setStrokeColor(NSColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 0.5).cgColor)
    ctx.setLineWidth(8)
    ctx.strokeEllipse(in: CGRect(x: 372, y: 372, width: 280, height: 280))
    
    // Center glow disc
    let centerGradColors = [
        NSColor(red: 1.0, green: 0.25, blue: 0.65, alpha: 1.0).cgColor,
        NSColor(red: 0.3, green: 0.4, blue: 1.0, alpha: 1.0).cgColor
    ] as CFArray
    if let centerGrad = CGGradient(colorsSpace: colorSpace, colors: centerGradColors, locations: [0.0, 1.0]) {
        ctx.addEllipse(in: CGRect(x: 442, y: 442, width: 140, height: 140))
        ctx.clip()
        ctx.drawLinearGradient(centerGrad, start: CGPoint(x: 442, y: 582), end: CGPoint(x: 582, y: 442), options: [])
    }
    ctx.restoreGState()
    
    // 5. Stylized Lyric Bars / Verse Waves
    let barHeights: [CGFloat] = [60, 110, 170, 240, 180, 260, 210, 140, 80]
    let startX: CGFloat = 270
    let spacing: CGFloat = 54
    for (i, h) in barHeights.enumerated() {
        let x = startX + CGFloat(i) * spacing
        let y = 190.0
        let barRect = CGRect(x: x, y: y, width: 26, height: h)
        let barPath = CGPath(roundedRect: barRect, cornerWidth: 13, cornerHeight: 13, transform: nil)
        
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: 4), blur: 16, color: NSColor(red: 0.2, green: 0.9, blue: 1.0, alpha: 0.7).cgColor)
        ctx.setFillColor(NSColor(red: 0.2 + CGFloat(i)*0.08, green: 0.7, blue: 1.0, alpha: 0.85).cgColor)
        ctx.addPath(barPath)
        ctx.fillPath()
        ctx.restoreGState()
    }
    
    // 6. Border Highlight
    ctx.addPath(squircle)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.25).cgColor)
    ctx.setLineWidth(6)
    ctx.strokePath()
    
    image.unlockFocus()
    
    // Save 1024x1024 PNG
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { return }
    
    let fm = FileManager.default
    let iconsetDir = "/tmp/Drift.iconset"
    try? fm.removeItem(atPath: iconsetDir)
    try? fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)
    
    let basePngPath = "/tmp/icon_1024.png"
    try? png.write(to: URL(fileURLWithPath: basePngPath))
    print("Generated base icon 1024x1024")
}

createIcon()
