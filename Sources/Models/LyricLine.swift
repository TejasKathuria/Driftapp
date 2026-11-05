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
        let rawWords = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard !rawWords.isEmpty else { return [] }
        
        let totalDuration = max(endTime - startTime, 1.0)
        let totalChars = max(rawWords.reduce(0) { $0 + max($1.count, 1) }, 1)
        
        // Natural Singing Cadence Model:
        // Singing cadence typically articulates words at ~0.35s to 0.55s per word.
        // We calculate the active articulation window and leave the remaining tail of the line
        // as vocal sustain / instrumental hold for the final word.
        let naturalVocalDuration = min(totalDuration * 0.85, Double(rawWords.count) * 0.48)
        let effectiveDuration = max(naturalVocalDuration, min(totalDuration, Double(rawWords.count) * 0.32))
        
        var words: [TimedWord] = []
        var runningTime = startTime
        
        for (index, word) in rawWords.enumerated() {
            let weight = Double(max(word.count, 1)) / Double(totalChars)
            let wordDur = effectiveDuration * weight
            // The final word extends until the end of the line (sustain / musical hold)
            let wordEnd = (index == rawWords.count - 1) ? endTime : (runningTime + wordDur)
            
            words.append(TimedWord(
                id: index,
                text: word,
                startTime: runningTime,
                endTime: wordEnd
            ))
            runningTime = runningTime + wordDur
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
