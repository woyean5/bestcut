import Foundation
import SwiftData

@MainActor public final class AnalysisCache {
    public static let analyzerVersion = 1
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// Cached results made by the current analyzer version.
    public func results(for ids: [String]) -> [String: AnalysisResult] {
        let wanted = Set(ids)
        let all = (try? context.fetch(FetchDescriptor<AnalysisRecord>())) ?? []
        var out: [String: AnalysisResult] = [:]
        for r in all where wanted.contains(r.assetID) && r.analyzerVersion == Self.analyzerVersion {
            out[r.assetID] = AnalysisResult(id: r.assetID, flags: QualityFlags(rawValue: r.flagsRaw), sharpness: r.sharpness,
                                            aesthetics: r.aesthetics, featurePrint: r.featurePrint, failed: r.failed)
        }
        return out
    }

    public func save(_ results: [AnalysisResult]) {
        let ids = Set(results.map(\.id))
        let all = (try? context.fetch(FetchDescriptor<AnalysisRecord>())) ?? []
        for r in all where ids.contains(r.assetID) { context.delete(r) }
        for r in results {
            context.insert(AnalysisRecord(assetID: r.id, flagsRaw: r.flags.rawValue, sharpness: r.sharpness, aesthetics: r.aesthetics,
                                          featurePrint: r.featurePrint, failed: r.failed, analyzerVersion: Self.analyzerVersion))
        }
        try? context.save()
    }
}
