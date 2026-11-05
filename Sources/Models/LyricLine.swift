import Foundation

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
    
    public var formattedStartTime: String {
        let mins = Int(startTime) / 60
        let secs = Int(startTime) % 60
        let centis = Int((startTime.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", mins, secs, centis)
    }
}

