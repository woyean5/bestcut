import Foundation

public enum SimilarityGrouper {
    /// Groups of two or more similar photos or screenshots, each in shooting order, ordered by first shot.
    /// `distance` returns the visual distance between two item IDs, or nil when it is unknown.
    public static func groups(for items: [MediaItem], distance: (String, String) -> Float?,
                              thresholds: GroupingThresholds = .default) -> [[String]] {
        var result: [[String]] = []
        for kind in [MediaKind.photo, .screenshot] {
            let sorted = items.filter { $0.kind == kind }.sorted { $0.creationDate < $1.creationDate }
            var current: [MediaItem] = []
            for next in sorted {
                if let last = current.last, belongTogether(last, next, kind: kind, distance: distance, t: thresholds) {
                    current.append(next)
                } else {
                    if current.count >= 2 { result.append(current.map(\.id)) }
                    current = [next]
                }
            }
            if current.count >= 2 { result.append(current.map(\.id)) }
        }
        let firstDate = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0.creationDate) })
        return result.sorted { firstDate[$0[0]]! < firstDate[$1[0]]! }
    }

    private static func belongTogether(_ a: MediaItem, _ b: MediaItem, kind: MediaKind,
                                       distance: (String, String) -> Float?, t: GroupingThresholds) -> Bool {
        let gap = b.creationDate.timeIntervalSince(a.creationDate)
        switch kind {
        case .photo:
            if let burst = a.burstID, burst == b.burstID { return true }
            guard gap <= t.photoMaxGap else { return false }
            if let la = a.location, let lb = b.location, la.distance(to: lb) > t.photoMaxMeters { return false }
            guard let d = distance(a.id, b.id) else { return false }
            return d <= t.photoMaxFeatureDistance
        case .screenshot:
            guard gap <= t.screenshotMaxGap, let d = distance(a.id, b.id) else { return false }
            return d <= t.screenshotMaxFeatureDistance
        case .video:
            return false
        }
    }
}
