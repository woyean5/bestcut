public struct SessionSettings: Sendable, Equatable {
    public var recommendationEnabled: Bool
    public var shortVideoMaxSeconds: Int

    public init(recommendationEnabled: Bool, shortVideoMaxSeconds: Int) {
        self.recommendationEnabled = recommendationEnabled
        self.shortVideoMaxSeconds = shortVideoMaxSeconds
    }
}

public struct TripSummary: Equatable, Sendable {
    public var total: Int
    /// Kept photos and videos (the best album).
    public var best: Int
    /// Kept screenshots (the screenshot album).
    public var screenshots: Int
    public var deleteCandidates: Int
    public var untouched: Int
    public var freeableBytes: Int64
    /// Some delete candidates have no known size.
    public var bytesIsEstimate: Bool

    public init(total: Int, best: Int, screenshots: Int, deleteCandidates: Int, untouched: Int, freeableBytes: Int64, bytesIsEstimate: Bool) {
        self.total = total
        self.best = best
        self.screenshots = screenshots
        self.deleteCandidates = deleteCandidates
        self.untouched = untouched
        self.freeableBytes = freeableBytes
        self.bytesIsEstimate = bytesIsEstimate
    }
}

public struct FinalizeResult: Equatable, Sendable {
    public var albumUpdated: Bool
    public var deleted: Int
    public var deleteCancelled: Bool

    public init(albumUpdated: Bool, deleted: Int, deleteCancelled: Bool) {
        self.albumUpdated = albumUpdated
        self.deleted = deleted
        self.deleteCancelled = deleteCancelled
    }
}
