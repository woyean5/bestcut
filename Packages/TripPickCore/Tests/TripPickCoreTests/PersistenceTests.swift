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

@MainActor @Test func decisionWritesStayFastWithManyStoredDecisions() throws {
    let container = try TripPickSchema.container(inMemory: true)
    let store = SwiftDataDecisionStore(context: container.mainContext)
    store.set(.keep, for: (0..<20_000).map { "old\($0)" })
    let clock = ContinuousClock()
    let elapsed = clock.measure {
        for i in 0..<100 { store.set(.deleteCandidate, for: ["new\(i)"]) }
    }
    #expect(store.decisions(for: ["new5", "old7"]) == ["new5": .deleteCandidate, "old7": .keep])
    #expect(elapsed < .seconds(2), "100 swipes took \(elapsed)")
}
@MainActor @Test func analysisCacheSaveStaysFastWithManyCachedResults() throws {
    let container = try TripPickSchema.container(inMemory: true)
    let cache = AnalysisCache(context: container.mainContext)
    func r(_ id: String) -> AnalysisResult { AnalysisResult(id: id, flags: [], sharpness: 1, aesthetics: 0, featurePrint: Data(count: 2_000), failed: false) }
    cache.save((0..<10_000).map { r("old\($0)") })
    let elapsed = ContinuousClock().measure {
        for i in 0..<20 { cache.save((0..<50).map { r("new\(i)-\($0)") }) }
    }
    #expect(cache.results(for: ["new3-7", "old9"]).count == 2)
    #expect(elapsed < .seconds(2), "20 batch saves took \(elapsed)")
}

@MainActor @Test func foldersPersistWithTrips() throws {
    let container = try TripPickSchema.container(inMemory: true)
    let folder = FolderRecord(name: "일본 여행")
    container.mainContext.insert(folder)
    container.mainContext.insert(TripRecord(name: "오사카", startDate: baseDate, endDate: baseDate, folderID: folder.id))
    container.mainContext.insert(TripRecord(name: "혼자", startDate: baseDate, endDate: baseDate))
    try container.mainContext.save()
    let fresh = ModelContext(container)
    let trips = try fresh.fetch(FetchDescriptor<TripRecord>())
    #expect(try fresh.fetch(FetchDescriptor<FolderRecord>()).map(\.name) == ["일본 여행"])
    #expect(trips.first { $0.name == "오사카" }?.folderID == folder.id)
    #expect(trips.first { $0.name == "혼자" }?.folderID == nil)
}
