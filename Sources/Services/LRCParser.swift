import Foundation

public struct ParsedLyrics {
    public let lines: [LyricLine]
    public let metadata: [String: String]
    
    public init(lines: [LyricLine], metadata: [String: String] = [:]) {
        self.lines = lines
        self.metadata = metadata
    }
    
    public func activeLineIndex(for time: TimeInterval) -> Int? {
        guard !lines.isEmpty else { return nil }
        
        if time < lines[0].startTime {
            return nil
        }
        
        // Active line is the latest line whose startTime is <= current playback time
        for index in (0..<lines.count).reversed() {
            if time >= lines[index].startTime {
                return index
            }
        }
        
        return nil
    }
}

public enum LRCParser {
    public static func parse(_ rawLRC: String) -> ParsedLyrics {
        var lines: [LyricLine] = []
        var metadata: [String: String] = [:]
        
        let rawLines = rawLRC.components(separatedBy: .newlines)
        
        // Regex for time tags like [01:23.45] or [01:23]
        let timeTagPattern = "\\[(\\d{1,2}):(\\d{2})(?:\\.(\\d{1,3}))?\\]"
        let timeRegex = try? NSRegularExpression(pattern: timeTagPattern, options: [])
        
        // Regex for section headers like [Verse 1], [Chorus], [Bridge], [Intro], [Outro]
        let sectionPattern = "^\\[(Verse|Chorus|Bridge|Pre-Chorus|Intro|Outro|Hook|Solo|Refrain)[^\\]]*\\]"
        let sectionRegex = try? NSRegularExpression(pattern: sectionPattern, options: [.caseInsensitive])
        
        var currentSection: String? = nil
        
        for rawLine in rawLines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }
            
            // Check for metadata tags like [ar:Artist], [ti:Title], [length:03:45]
            if line.hasPrefix("[") && line.contains(":") {
                let closingIndex = line.firstIndex(of: "]")
                if let closeIdx = closingIndex {
                    let insideTag = String(line[line.index(after: line.startIndex)..<closeIdx])
                    let parts = insideTag.split(separator: ":", maxSplits: 1)
                    if parts.count == 2 {
                        let key = parts[0].trimmingCharacters(in: .whitespaces).lowercased()
                        let val = parts[1].trimmingCharacters(in: .whitespaces)
                        
                        // Check if key is metadata (ar, ti, al, by, offset, length)
                        if ["ar", "artist", "ti", "title", "al", "album", "by", "offset", "length"].contains(key) {
                            metadata[key] = val
                            continue
                        }
                    }
                }
            }
            
            // Check for section headers like [Chorus] or [Verse 1]
            let nsLine = line as NSString
            if let secMatch = sectionRegex?.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)) {
                let secTag = nsLine.substring(with: secMatch.range)
                currentSection = secTag.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
                
                // If there's no lyric text after the section header, continue
                let remaining = nsLine.substring(from: secMatch.range.length).trimmingCharacters(in: .whitespaces)
                if remaining.isEmpty {
                    continue
                }
            }
            
            // Find all time tags in the line
            guard let timeRegex = timeRegex else { continue }
            let matches = timeRegex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
            
            if !matches.isEmpty {
                var lastTagEnd = 0
                var timestamps: [TimeInterval] = []
                
                for match in matches {
                    let minStr = nsLine.substring(with: match.range(at: 1))
                    let secStr = nsLine.substring(with: match.range(at: 2))
                    let milliStr = match.range(at: 3).location != NSNotFound ? nsLine.substring(with: match.range(at: 3)) : "0"
                    
                    let mins = Double(minStr) ?? 0
                    let secs = Double(secStr) ?? 0
                    var fraction = Double("0.\(milliStr)") ?? 0
                    if milliStr.count == 2 {
                        fraction = (Double(milliStr) ?? 0) / 100.0
                    }
                    
                    let totalTime = mins * 60.0 + secs + fraction
                    timestamps.append(totalTime)
                    lastTagEnd = max(lastTagEnd, match.range.location + match.range.length)
                }
                
                var text = nsLine.substring(from: lastTagEnd).trimmingCharacters(in: .whitespaces)
                
                // If text after timestamps is a section tag like [Chorus] or [Intro]
                let nsText = text as NSString
                if let secMatch = sectionRegex?.firstMatch(in: text, range: NSRange(location: 0, length: nsText.length)) {
                    let secTag = nsText.substring(with: secMatch.range)
                    currentSection = secTag.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
                    let afterSec = nsText.substring(from: secMatch.range.length).trimmingCharacters(in: .whitespaces)
                    text = afterSec
                }
                
                // If lyric text is empty (e.g. instrumental prelude/break), show animated dots or section note
                var isHeader = false
                if text.isEmpty {
                    if currentSection != nil {
                        text = "• • •"
                        isHeader = true
                    } else {
                        // Empty line with no section
                        continue
                    }
                }
                
                for timestamp in timestamps {
                    lines.append(LyricLine(
                        startTime: timestamp,
                        endTime: 0,
                        text: text,
                        sectionName: currentSection,
                        isSectionHeader: isHeader
                    ))
                }
            } else if line.hasPrefix("[") && line.hasSuffix("]") {
                // Bracketed line without timestamp, e.g. [Chorus]
                currentSection = line.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
            }
        }
        
        // Sort lines chronologically
        lines.sort { $0.startTime < $1.startTime }
        
        // Calculate appropriate endTime for each line
        for i in 0..<lines.count {
            if i + 1 < lines.count {
                let nextStart = lines[i + 1].startTime
                if nextStart > lines[i].startTime {
                    let gap = nextStart - lines[i].startTime
                    lines[i].endTime = lines[i].startTime + min(gap, 8.0)
                } else {
                    lines[i].endTime = lines[i].startTime + 1.0
                }
            } else {
                // Last line lasts 5 seconds
                lines[i].endTime = lines[i].startTime + 5.0
            }
        }
        
        return ParsedLyrics(lines: lines, metadata: metadata)
    }
}
