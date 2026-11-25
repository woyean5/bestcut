import CoreGraphics
import Foundation

public struct AnalysisProgress: Sendable, Equatable {
    public var done: Int
    public var total: Int

    public init(done: Int, total: Int) {
        self.done = done
        self.total = total
    }
}

/// Analyzes the photos and screenshots of a trip, reusing cached results.
@MainActor public final class AnalysisCoordinator {
    private let library: PhotoLibrary
    private let analyzer: ImageAnalyzing
    private let cache: AnalysisCache
    private let concurrency: Int
    private let maxPixel: Int
    private let saveEvery = 50

    public init(library: PhotoLibrary, analyzer: ImageAnalyzing, cache: AnalysisCache, concurrency: Int = 4,
                maxPixel: Int = QualityThresholds.default.analysisMaxPixel) {
        self.library = library
        self.analyzer = analyzer
        self.cache = cache
        self.concurrency = max(1, concurrency)
        self.maxPixel = maxPixel
    }

    /// Results for every photo and screenshot (videos are not analyzed). On cancellation, returns what was done.
    public func analyze(_ items: [MediaItem], progress: @MainActor (AnalysisProgress) -> Void) async -> [String: AnalysisResult] {
        let images = items.filter { $0.kind != .video }
        var results = cache.results(for: images.map(\.id))
        let todo = images.filter { results[$0.id] == nil }
        let total = images.count
        progress(AnalysisProgress(done: results.count, total: total))

        var pending: [AnalysisResult] = []
        let library = self.library, analyzer = self.analyzer, maxPixel = self.maxPixel
        await withTaskGroup(of: AnalysisResult.self) { group in
            var iterator = todo.makeIterator()
            func addNext() -> Bool {
                guard !Task.isCancelled, let next = iterator.next() else { return false }
                group.addTask {
                    guard let image = await library.analysisImage(for: next.id, maxPixel: maxPixel) else {
                        return AnalysisResult(id: next.id, flags: [], sharpness: 0, aesthetics: 0, featurePrint: nil, failed: true)
                    }
                    return await analyzer.analyze(image, id: next.id, kind: next.kind)
                }
                return true
            }
            for _ in 0..<concurrency { if !addNext() { break } }
            for await result in group {
                results[result.id] = result
                // Failed loads (often iCloud-only photos while offline) are not cached, so they retry next time.
                if !result.failed { pending.append(result) }
                if pending.count >= saveEvery {
                    cache.save(pending)
                    pending.removeAll()
                }
                progress(AnalysisProgress(done: results.count, total: total))
                _ = addNext()
            }
        }
        if !pending.isEmpty { cache.save(pending) }
        return results
    }
}
