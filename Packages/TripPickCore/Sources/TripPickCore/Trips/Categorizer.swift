import Foundation

public enum ReviewKind: String, Sendable, Hashable, CaseIterable {
    case similar, screenshots, flagged, shortVideos
}

/// A set of items the user reviews on one screen.
public struct ReviewSet: Identifiable, Hashable, Sendable {
    public var id: String
    public var kind: ReviewKind
    public var itemIDs: [String]

    public init(id: String, kind: ReviewKind, itemIDs: [String]) {
        self.id = id
        self.kind = kind
        self.itemIDs = itemIDs
    }

    init(kind: ReviewKind, itemIDs: [String]) {
        self.init(id: "\(kind.rawValue)-\(itemIDs[0])", kind: kind, itemIDs: itemIDs)
    }
}

public struct TripBuckets: Sendable, Equatable {
    public var similar: [ReviewSet] = []
    public var screenshots: [ReviewSet] = []
    public var flagged: [ReviewSet] = []
    public var shortVideos: [ReviewSet] = []
    /// Ungrouped photos without problems, plus ungrouped screenshots.
    public var singles: [String] = []
    /// Every item this trip handles (long videos excluded), in shooting order.
    public var allItemIDs: [String] = []

    public init() {}

    public func sets(of kind: ReviewKind) -> [ReviewSet] {
        switch kind {
        case .similar: similar
        case .screenshots: screenshots
        case .flagged: flagged
        case .shortVideos: shortVideos
        }
    }
}

public enum Categorizer {
    public static let chunkSize = 9

    public static func buckets(items: [MediaItem], analyses: [String: AnalysisResult], groups: [[String]],
                               shortVideoMaxSeconds: Int) -> TripBuckets {
        let byID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        var b = TripBuckets()
        var grouped = Set<String>()
        for group in groups where group.count >= 2 {
            guard let kind = byID[group[0]]?.kind else { continue }
            grouped.formUnion(group)
            if kind == .photo { b.similar.append(ReviewSet(kind: .similar, itemIDs: group)) }
            if kind == .screenshot { b.screenshots.append(ReviewSet(kind: .screenshots, itemIDs: group)) }
        }
        var flagged: [String] = [], videos: [String] = []
        let sorted = items.sorted { $0.creationDate < $1.creationDate }
        for item in sorted {
            switch item.kind {
            case .video:
                guard item.duration <= Double(shortVideoMaxSeconds) else { continue }
                videos.append(item.id)
            case .photo where !grouped.contains(item.id):
                if let flags = analyses[item.id]?.flags, !flags.isEmpty { flagged.append(item.id) } else { b.singles.append(item.id) }
            case .screenshot where !grouped.contains(item.id):
                b.singles.append(item.id)
            default:
                break
            }
            b.allItemIDs.append(item.id)
        }
        b.flagged = chunks(flagged).map { ReviewSet(kind: .flagged, itemIDs: $0) }
        b.shortVideos = chunks(videos).map { ReviewSet(kind: .shortVideos, itemIDs: $0) }
        return b
    }

    private static func chunks(_ ids: [String]) -> [[String]] {
        stride(from: 0, to: ids.count, by: chunkSize).map { Array(ids[$0..<min($0 + chunkSize, ids.count)]) }
    }
}
