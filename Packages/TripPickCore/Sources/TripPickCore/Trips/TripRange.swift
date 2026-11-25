import Foundation

public enum TripRangeIssue: Sendable, Equatable {
    case endBeforeStart, noMedia
}

public struct TripRange: Sendable, Equatable {
    public var start: Date
    public var end: Date

    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }

    /// From the start day's midnight to the midnight after the end day; nil when the end is before the start.
    public var interval: DateInterval? {
        let cal = Calendar.current
        let from = cal.startOfDay(for: start)
        guard let to = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: end)), to > from else { return nil }
        return DateInterval(start: from, end: to)
    }

    public static func validate(_ range: TripRange, mediaCount: Int) -> TripRangeIssue? {
        if range.interval == nil { return .endBeforeStart }
        if mediaCount == 0 { return .noMedia }
        return nil
    }
}
