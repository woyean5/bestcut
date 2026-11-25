import Foundation
import SwiftData

@MainActor public final class AnalysisCache {
    public static let analyzerVersion = 2
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// Cached results made by the current analyzer version.
    public func results(for ids: [String]) -> [String: AnalysisResult] {
        var out: [String: AnalysisResult] = [:]
        for r in records(for: ids) where r.analyzerVersion == Self.analyzerVersion {
            out[r.assetID] = AnalysisResult(id: r.assetID, flags: QualityFlags(rawValue: r.flagsRaw), sharpness: r.sharpness,
                                            aesthetics: r.aesthetics, featurePrint: r.featurePrint, failed: r.failed)
        }
        return out
    }

    public func save(_ results: [AnalysisResult]) {
        for r in records(for: results.map(\.id)) { context.delete(r) }
        for r in results {
            context.insert(AnalysisRecord(assetID: r.id, flagsRaw: r.flags.rawValue, sharpness: r.sharpness, aesthetics: r.aesthetics,
                                          featurePrint: r.featurePrint, failed: r.failed, analyzerVersion: Self.analyzerVersion))
        }
        try? context.save()
    }

    private func records(for ids: [String]) -> [AnalysisRecord] {
        var out: [AnalysisRecord] = []
        for chunk in ids.chunked(500) {
            let descriptor = FetchDescriptor<AnalysisRecord>(predicate: #Predicate { chunk.contains($0.assetID) })
            out += (try? context.fetch(descriptor)) ?? []
        }
        return out
    }
}
