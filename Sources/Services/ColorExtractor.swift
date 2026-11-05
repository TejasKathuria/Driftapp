import AppKit
import SwiftUI

public enum ColorExtractor {
    
    /// Extracts a rich 5-color palette from an NSImage
    public static func extractPalette(from image: NSImage) -> ArtworkPalette {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return ArtworkPalette()
        }
        
        let width = 40
        let height = 40
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        var rawData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return ArtworkPalette()
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        struct HSBColor {
            let r: Double
            let g: Double
            let b: Double
            let h: Double
            let s: Double
            let v: Double
            let score: Double
        }
        
        var sampledColors: [HSBColor] = []
        
        for y in 0..<height {
            for x in 0..<width {
                let byteIndex = (y * bytesPerRow) + (x * bytesPerPixel)
                let r = Double(rawData[byteIndex]) / 255.0
                let g = Double(rawData[byteIndex + 1]) / 255.0
                let b = Double(rawData[byteIndex + 2]) / 255.0
                
                let maxC = max(r, max(g, b))
                let minC = min(r, min(g, b))
                let delta = maxC - minC
                
                var h: Double = 0
                if delta > 0.0001 {
                    if maxC == r {
                        h = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
                    } else if maxC == g {
                        h = ((b - r) / delta) + 2
                    } else {
                        h = ((r - g) / delta) + 4
                    }
                    h = h / 6.0
                    if h < 0 { h += 1.0 }
                }
                
                let s = maxC > 0 ? (delta / maxC) : 0
                let v = maxC
                
                // Discard pure blacks, whites, and low-saturation grays
                if s > 0.18 && v > 0.18 && v < 0.95 {
                    // Vibrant colors get higher scores
                    let vibrancyScore = s * 0.7 + v * 0.3
                    sampledColors.append(HSBColor(r: r, g: g, b: b, h: h, s: s, v: v, score: vibrancyScore))
                }
            }
        }
        
        guard !sampledColors.isEmpty else {
            return ArtworkPalette()
        }
        
        // Sort by vibrancy score
        sampledColors.sort { $0.score > $1.score }
        
        let primarySample = sampledColors[0]
        let primary = Color(hue: primarySample.h, saturation: min(primarySample.s * 1.1, 1.0), brightness: min(primarySample.v * 1.1, 1.0))
        
        // Find a distinct secondary color at least 0.18 hue distance away
        var secondarySample = primarySample
        for sample in sampledColors {
            let hueDiff = abs(sample.h - primarySample.h)
            let distance = min(hueDiff, 1.0 - hueDiff)
            if distance > 0.16 {
                secondarySample = sample
                break
            }
        }
        let secondary = Color(hue: secondarySample.h, saturation: secondarySample.s, brightness: secondarySample.v)
        
        // Find brightest accent
        var accentSample = sampledColors.max(by: { $0.v < $1.v }) ?? primarySample
        if accentSample.s < 0.3 {
            accentSample = primarySample
        }
        let accent = Color(hue: accentSample.h, saturation: max(accentSample.s, 0.7), brightness: 0.98)
        
        // Deep background hues
        let bgDark = Color(hue: primarySample.h, saturation: 0.75, brightness: 0.08)
        let bgMid = Color(hue: secondarySample.h, saturation: 0.65, brightness: 0.18)
        
        return ArtworkPalette(
            primary: primary,
            secondary: secondary,
            accent: accent,
            backgroundDark: bgDark,
            backgroundMid: bgMid
        )
    }
    
    /// Predefined authentic album cover palettes for popular/demo songs
    public static func defaultPaletteForDemo(title: String, artist: String) -> ArtworkPalette {
        let t = title.lowercased()
        if t.contains("blinding") {
            // After Hours - The Weeknd: Deep Neon Scarlet & Midnight Gold
            return ArtworkPalette(
                primary: Color(red: 0.92, green: 0.12, blue: 0.18),
                secondary: Color(red: 0.68, green: 0.06, blue: 0.14),
                accent: Color(red: 1.0, green: 0.75, blue: 0.15),
                backgroundDark: Color(red: 0.08, green: 0.02, blue: 0.03),
                backgroundMid: Color(red: 0.22, green: 0.04, blue: 0.06)
            )
        } else if t.contains("bohemian") {
            // Queen - A Night at the Opera: Royal Sapphire, Amethyst & Champagne
            return ArtworkPalette(
                primary: Color(red: 0.25, green: 0.45, blue: 0.95),
                secondary: Color(red: 0.60, green: 0.15, blue: 0.85),
                accent: Color(red: 1.0, green: 0.82, blue: 0.40),
                backgroundDark: Color(red: 0.04, green: 0.05, blue: 0.12),
                backgroundMid: Color(red: 0.12, green: 0.08, blue: 0.24)
            )
        } else if t.contains("viva") {
            // Coldplay - Viva La Vida: French Tricolor & Delacroix Ochre
            return ArtworkPalette(
                primary: Color(red: 0.90, green: 0.40, blue: 0.25),
                secondary: Color(red: 0.18, green: 0.45, blue: 0.75),
                accent: Color(red: 0.98, green: 0.72, blue: 0.35),
                backgroundDark: Color(red: 0.06, green: 0.08, blue: 0.10),
                backgroundMid: Color(red: 0.18, green: 0.12, blue: 0.10)
            )
        } else if t.contains("hotel") {
            // Eagles - Hotel California: Sunset Dusk Purple, Tangerine & Beverly Hills Palm
            return ArtworkPalette(
                primary: Color(red: 0.95, green: 0.35, blue: 0.15),
                secondary: Color(red: 0.55, green: 0.20, blue: 0.75),
                accent: Color(red: 1.0, green: 0.60, blue: 0.20),
                backgroundDark: Color(red: 0.10, green: 0.03, blue: 0.08),
                backgroundMid: Color(red: 0.25, green: 0.06, blue: 0.18)
            )
        }
        
        // Harmonic algorithmic palette
        let hash = abs("\(title)\(artist)".hashValue)
        let hue1 = Double(hash % 360) / 360.0
        let hue2 = (hue1 + 0.38).truncatingRemainder(dividingBy: 1.0)
        
        return ArtworkPalette(
            primary: Color(hue: hue1, saturation: 0.85, brightness: 0.95),
            secondary: Color(hue: hue2, saturation: 0.80, brightness: 0.85),
            accent: Color(hue: (hue1 + 0.15).truncatingRemainder(dividingBy: 1.0), saturation: 0.90, brightness: 0.98),
            backgroundDark: Color(hue: hue1, saturation: 0.70, brightness: 0.07),
            backgroundMid: Color(hue: hue2, saturation: 0.60, brightness: 0.16)
        )
    }
}

/// Network service to download high-resolution album cover and extract its live palette
public actor ArtworkService {
    public static let shared = ArtworkService()
    
    private var dataCache: [String: Data] = [:]
    private var paletteCache: [String: ArtworkPalette] = [:]
    
    public func fetchArtworkDataAndPalette(for track: Track) async -> (Data?, ArtworkPalette) {
        let key = "\(track.artist.lowercased()) - \(track.title.lowercased())"
        
        if let cachedPal = paletteCache[key] {
            return (dataCache[key], cachedPal)
        }
        
        // 1. If demo track, use authentic demo palette
        if track.source == .demo {
            let pal = ColorExtractor.defaultPaletteForDemo(title: track.title, artist: track.artist)
            paletteCache[key] = pal
            return (nil, pal)
        }
        
        // 2. If Spotify provided a direct artwork URL
        if let artURL = track.artworkURL, let url = URL(string: artURL) {
            if let data = await downloadData(from: url), let img = NSImage(data: data) {
                let pal = ColorExtractor.extractPalette(from: img)
                dataCache[key] = data
                paletteCache[key] = pal
                return (data, pal)
            }
        }
        
        // 3. Fallback: Search iTunes Store API for ultra-high-res 1000x1000 artwork
        if let data = await searchITunesArtworkData(title: track.title, artist: track.artist), let img = NSImage(data: data) {
            let pal = ColorExtractor.extractPalette(from: img)
            dataCache[key] = data
            paletteCache[key] = pal
            return (data, pal)
        }
        
        // 4. Default algorithmic palette
        let defaultPal = ColorExtractor.defaultPaletteForDemo(title: track.title, artist: track.artist)
        paletteCache[key] = defaultPal
        return (nil, defaultPal)
    }
    
    private func downloadData(from url: URL) async -> Data? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 6.0
        guard let (data, resp) = try? await URLSession.shared.data(for: request),
              let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            return nil
        }
        return data
    }
    
    private func searchITunesArtworkData(title: String, artist: String) async -> Data? {
        let query = "\(artist) \(title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://itunes.apple.com/search?term=\(query)&entity=song&limit=1") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        guard let (data, resp) = try? await URLSession.shared.data(for: request),
              let http = resp as? HTTPURLResponse, http.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]],
              let first = results.first,
              let art100 = first["artworkUrl100"] as? String else {
            return nil
        }
        
        // Replace 100x100 with 600x600 for sharp Liquid Retina rendering
        let highRes = art100.replacingOccurrences(of: "100x100bb", with: "600x600bb")
        guard let artURL = URL(string: highRes) else { return nil }
        return await downloadData(from: artURL)
    }
}
