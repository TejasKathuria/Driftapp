import Foundation

public struct TimedWord: Identifiable, Equatable {
    public let id: Int
    public let text: String
    public let startTime: TimeInterval
    public let endTime: TimeInterval
    
    public func isActive(at time: TimeInterval) -> Bool {
        return time >= startTime && time < endTime
    }
    
    public func isPassed(at time: TimeInterval) -> Bool {
        return time >= endTime
    }
}

public struct LyricLine: Identifiable, Equatable {
    public let id: UUID
    public let startTime: TimeInterval
    public var endTime: TimeInterval
    public let text: String
    public var translation: String?
    public var sectionName: String?
    public var isSectionHeader: Bool
    
    public init(
        id: UUID = UUID(),
        startTime: TimeInterval,
        endTime: TimeInterval = 0,
        text: String,
        translation: String? = nil,
        sectionName: String? = nil,
        isSectionHeader: Bool = false
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
        self.translation = translation
        self.sectionName = sectionName
        self.isSectionHeader = isSectionHeader
    }
    
    public func isActive(at time: TimeInterval) -> Bool {
        return time >= startTime && time < endTime
    }
    
    public func progress(at time: TimeInterval) -> Double {
        guard endTime > startTime else { return 0 }
        if time < startTime { return 0 }
        if time >= endTime { return 1.0 }
        return (time - startTime) / (endTime - startTime)
    }
    
    public var timedWords: [TimedWord] {
        return timedWords(speedMultiplier: 1.0, chunkPhrases: false)
    }
    
    public func timedWords(speedMultiplier: Double = 1.0, chunkPhrases: Bool = false) -> [TimedWord] {
        let rawWords = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard !rawWords.isEmpty else { return [] }
        
        // Phrase chunking option: combine short particles (length <= 2 or vowels/prepositions)
        let tokens: [String]
        if chunkPhrases && rawWords.count >= 4 {
            var grouped: [String] = []
            var i = 0
            while i < rawWords.count {
                let current = rawWords[i]
                if current.count <= 2 && i + 1 < rawWords.count {
                    grouped.append("\(current) \(rawWords[i+1])")
                    i += 2
                } else if i > 0 && current.count <= 2 {
                    let last = grouped.removeLast()
                    grouped.append("\(last) \(current)")
                    i += 1
                } else {
                    grouped.append(current)
                    i += 1
                }
            }
            tokens = grouped.isEmpty ? rawWords : grouped
        } else {
            tokens = rawWords
        }
        
        let totalDuration = max(endTime - startTime, 1.0)
        let tokenCount = tokens.count
        let averageTimePerToken = totalDuration / Double(tokenCount)
        let isBalladTempo = averageTimePerToken >= 0.85
        
        // Calculate weighted presence:
        // 1. Script/syllable weight: Give non-Latin / Devanagari words higher base weight
        // 2. The final word in a line almost always has vocal vibrato / sustain
        var weights: [Double] = []
        for (i, token) in tokens.enumerated() {
            var w = Double(max(token.count, 2))
            
            // Multilingual / complex script boost (Hindi, Japanese, etc.)
            let hasNonASCII = token.unicodeScalars.contains { $0.value > 127 }
            if hasNonASCII {
                w *= 1.45
            }
            
            // Final word sustain weight
            if i == tokenCount - 1 && tokenCount > 1 {
                w *= (isBalladTempo ? 1.8 : 1.35)
            }
            
            weights.append(w)
        }
        
        let sumWeights = max(weights.reduce(0, +), 1.0)
        
        var words: [TimedWord] = []
        var runningTime = startTime
        
        // Proportionally distribute totalDuration so sum(durations) == totalDuration ALWAYS!
        for (index, token) in tokens.enumerated() {
            let fraction = weights[index] / sumWeights
            let tokenDuration = totalDuration * fraction
            let tokenEnd = (index == tokenCount - 1) ? endTime : (runningTime + tokenDuration)
            
            words.append(TimedWord(
                id: index,
                text: token,
                startTime: runningTime,
                endTime: tokenEnd
            ))
            runningTime = tokenEnd
        }
        return words
    }
    
    public var formattedStartTime: String {
        let mins = Int(startTime) / 60
        let secs = Int(startTime) % 60
        let centis = Int((startTime.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", mins, secs, centis)
    }
}
