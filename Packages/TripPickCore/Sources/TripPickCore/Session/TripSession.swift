import Foundation
import Observation

/// One trip being organized: what is in it, what the user decided, and how it ends.
@MainActor @Observable public final class TripSession {
    public private(set) var items: [String: MediaItem]
    public let analyses: [String: AnalysisResult]
    public private(set) var buckets: TripBuckets
    public let settings: SessionSettings

    private var stored: [String: Decision]
    private var undoStack: [(id: String, previous: Decision?)] = []
    @ObservationIgnored private let store: DecisionStore
    @ObservationIgnored private let library: PhotoLibrary
    @ObservationIgnored private let distance: (String, String) -> Float?

    public init(items: [MediaItem], analyses: [String: AnalysisResult], store: DecisionStore, library: PhotoLibrary,
                settings: SessionSettings, distance: @escaping (String, String) -> Float?) {
        self.items = Dictionary(items.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        self.analyses = analyses
        self.store = store
        self.library = library
        self.settings = settings
        self.distance = distance
        let buckets = Self.makeBuckets(items, analyses: analyses, settings: settings, distance: distance)
        self.buckets = buckets
        self.stored = store.decisions(for: buckets.allItemIDs)
    }

    private static func makeBuckets(_ items: [MediaItem], analyses: [String: AnalysisResult], settings: SessionSettings,
                                    distance: (String, String) -> Float?) -> TripBuckets {
        let groups = SimilarityGrouper.groups(for: items, distance: distance)
        return Categorizer.buckets(items: items, analyses: analyses, groups: groups, shortVideoMaxSeconds: settings.shortVideoMaxSeconds)
    }

    // MARK: Decisions

    public func decision(_ id: String) -> Decision {
        guard let item = items[id] else { return .untouched }
        return DecisionRules.effective(stored: stored[id], item: item)
    }

    public func isDone(_ set: ReviewSet) -> Bool {
        set.itemIDs.allSatisfy { decision($0) != .untouched }
    }

    /// The first unfinished set: similar photos, then screenshots, then flagged photos, then short videos.
    public func nextReviewSet() -> ReviewSet? {
        for kind in ReviewKind.allCases {
            if let set = buckets.sets(of: kind).first(where: { !isDone($0) }) { return set }
        }
        return nil
    }

    public func recommendation(in set: ReviewSet) -> String? {
        Recommender.recommendation(for: set, analyses: analyses)
    }

    /// What starts selected as "keep" on the review screen.
    public func preselected(in set: ReviewSet) -> Set<String> {
        var ids = Set(set.itemIDs.filter { decision($0) == .keep })
        if settings.recommendationEnabled, !isDone(set), let rec = recommendation(in: set) { ids.insert(rec) }
        return ids
    }

    /// The user finished a set: the selection is kept, the rest become delete candidates.
    public func confirm(_ set: ReviewSet, keeping: Set<String>) {
        let keep = set.itemIDs.filter { keeping.contains($0) }
        let rest = set.itemIDs.filter { !keeping.contains($0) }
        write(.keep, keep)
        write(.deleteCandidate, rest)
    }

    public func swipeQueue(singlesOnly: Bool) -> [String] {
        (singlesOnly ? buckets.singles : buckets.allItemIDs).filter { decision($0) == .untouched }
    }

    public func swipe(_ id: String, keep: Bool) {
        undoStack.append((id, stored[id]))
        write(keep ? .keep : .deleteCandidate, [id])
    }

    /// Reverts the last swipe; returns its item.
    public func undo() -> String? {
        guard let last = undoStack.popLast() else { return nil }
        write(last.previous ?? .untouched, [last.id])
        return last.id
    }

    private func write(_ decision: Decision, _ ids: [String]) {
        guard !ids.isEmpty else { return }
        store.set(decision, for: ids)
        for id in ids { stored[id] = decision == .untouched ? nil : decision }
    }

    // MARK: Progress and summary

    public var progress: Double {
        let all = buckets.allItemIDs
        guard !all.isEmpty else { return 0 }
        return Double(all.filter { decision($0) != .untouched }.count) / Double(all.count)
    }

    public var summary: TripSummary {
        var s = TripSummary(total: buckets.allItemIDs.count, best: 0, screenshots: 0, deleteCandidates: 0, untouched: 0,
                            freeableBytes: 0, bytesIsEstimate: false)
        for id in buckets.allItemIDs {
            switch decision(id) {
            case .keep:
                if items[id]?.kind == .screenshot { s.screenshots += 1 } else { s.best += 1 }
            case .deleteCandidate:
                s.deleteCandidates += 1
                if let bytes = items[id]?.byteSize { s.freeableBytes += bytes } else { s.bytesIsEstimate = true }
            case .untouched:
                s.untouched += 1
            }
        }
        return s
    }

    // MARK: Finish

    /// Puts kept items into the albums, takes this trip's delete candidates out of them, and optionally deletes those.
    public func finalize(bestAlbum: String, screenshotAlbum: String, deleteCandidates: Bool) async throws -> FinalizeResult {
        let all = buckets.allItemIDs
        let isShot = { (id: String) in self.items[id]?.kind == .screenshot }
        let keep = all.filter { decision($0) == .keep }
        let deletes = all.filter { decision($0) == .deleteCandidate }
        var updated = false
        for (name, shots) in [(bestAlbum, false), (screenshotAlbum, true)] {
            let add = keep.filter { isShot($0) == shots }
            let remove = deletes.filter { isShot($0) == shots }
            guard !add.isEmpty || !remove.isEmpty else { continue }
            try await library.addToAlbum(named: name, add: add, remove: remove)
            updated = true
        }
        guard deleteCandidates, !deletes.isEmpty else {
            return FinalizeResult(albumUpdated: updated, deleted: 0, deleteCancelled: false)
        }
        switch try await library.delete(deletes) {
        case .cancelled:
            return FinalizeResult(albumUpdated: updated, deleted: 0, deleteCancelled: true)
        case .deleted(let n):
            write(.untouched, deletes)
            for id in deletes { items[id] = nil }
            undoStack.removeAll()
            buckets = Self.makeBuckets(Array(items.values), analyses: analyses, settings: settings, distance: distance)
            return FinalizeResult(albumUpdated: updated, deleted: n, deleteCancelled: false)
        }
    }
}
