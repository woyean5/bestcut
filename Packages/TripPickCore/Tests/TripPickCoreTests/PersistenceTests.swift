import Foundation
import SwiftData
import Testing
@testable import TripPickCore

@MainActor @Test func decisionsPersistAndUntouchedDeletes() throws {
    let container = try TripPickSchema.container(inMemory: true)
    let store = SwiftDataDecisionStore(context: container.mainContext)
    store.set(.keep, for: ["a", "b"])
    store.set(.untouched, for: ["b"])
    let fresh = SwiftDataDecisionStore(context: ModelContext(container))
    #expect(fresh.decisions(for: ["a", "b"]) == ["a": .keep])
}
@MainActor @Test func decisionsOverwrite() throws {
    let container = try TripPickSchema.container(inMemory: true)
    let store = SwiftDataDecisionStore(context: container.mainContext)
    store.set(.keep, for: ["a"])
    store.set(.deleteCandidate, for: ["a"])
    #expect(store.decisions(for: ["a"]) == ["a": .deleteCandidate])
}
@MainActor @Test func analysisCacheRoundTripsAndIgnoresOldVersion() throws {
    let container = try TripPickSchema.container(inMemory: true)
    let cache = AnalysisCache(context: container.mainContext)
    let r = AnalysisResult(id: "a", flags: [.dark, .blurry], sharpness: 12, aesthetics: 0.4, featurePrint: Data([1, 2]), failed: false)
    cache.save([r])
    #expect(cache.results(for: ["a"])["a"] == r)
    container.mainContext.insert(AnalysisRecord(assetID: "old", flagsRaw: 0, sharpness: 1, aesthetics: 0, featurePrint: nil, failed: false, analyzerVersion: 0))
    #expect(cache.results(for: ["old"]).isEmpty)
}
@MainActor @Test func tripRecordsPersist() throws {
    let container = try TripPickSchema.container(inMemory: true)
    container.mainContext.insert(TripRecord(name: "Jeju", startDate: baseDate, endDate: baseDate))
    try container.mainContext.save()
    #expect(try ModelContext(container).fetch(FetchDescriptor<TripRecord>()).map(\.name) == ["Jeju"])
}
