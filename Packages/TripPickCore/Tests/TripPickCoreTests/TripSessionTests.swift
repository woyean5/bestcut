import Foundation
import SwiftData
import Testing
@testable import TripPickCore

private let defaults = SessionSettings(recommendationEnabled: true, shortVideoMaxSeconds: 2)
@MainActor private var retained: [ModelContainer] = []

@MainActor private func memoryStore() -> SwiftDataDecisionStore {
    let c = try! TripPickSchema.container(inMemory: true)
    retained.append(c)
    return SwiftDataDecisionStore(context: c.mainContext)
}

@MainActor private func makeSessionWithLibrary(items: [MediaItem], analyses: [String: AnalysisResult] = [:],
                                               settings: SessionSettings = defaults, store: DecisionStore? = nil) -> (TripSession, FakePhotoLibrary) {
    let lib = FakePhotoLibrary()
    lib.items = items
    let s = TripSession(items: items, analyses: analyses, store: store ?? memoryStore(), library: lib, settings: settings,
                        distance: { _, _ in 0.1 })
    return (s, lib)
}

@MainActor private func makeSession(items: [MediaItem], analyses: [String: AnalysisResult] = [:],
                                    settings: SessionSettings = defaults, store: DecisionStore? = nil) -> TripSession {
    makeSessionWithLibrary(items: items, analyses: analyses, settings: settings, store: store).0
}

@MainActor @Test func unseenPhotosAreNeverDeleteCandidates() {
    let s = makeSession(items: [item("a"), item("b", at: 10), item("c", at: 5000)])
    #expect(s.summary.deleteCandidates == 0)
    #expect(s.summary.untouched == 3)
}
@MainActor @Test func confirmGroupKeepsSelectionAndMarksRest() {
    let s = makeSession(items: [item("a"), item("b", at: 10), item("c", at: 20)])
    let set = s.nextReviewSet()!
    s.confirm(set, keeping: ["b"])
    #expect(s.decision("b") == .keep)
    #expect(s.decision("a") == .deleteCandidate)
    #expect(s.isDone(set))
    #expect(s.nextReviewSet() == nil)
}
@MainActor @Test func recommendationPreselectedOnlyWhenEnabled() {
    let items = [item("a"), item("b", at: 10)]
    let analyses = ["a": AnalysisResult(id: "a", flags: .blurry, sharpness: 10, aesthetics: 0, featurePrint: nil, failed: false),
                    "b": AnalysisResult(id: "b", flags: [], sharpness: 400, aesthetics: 0.5, featurePrint: nil, failed: false)]
    let on = makeSession(items: items, analyses: analyses)
    #expect(on.preselected(in: on.nextReviewSet()!) == ["b"])
    #expect(on.summary.best == 0)
    let off = makeSession(items: items, analyses: analyses, settings: .init(recommendationEnabled: false, shortVideoMaxSeconds: 2))
    #expect(off.preselected(in: off.nextReviewSet()!).isEmpty)
}
@MainActor @Test func favoritesStartAsKeepAndStayOutOfSwipeQueue() {
    let s = makeSession(items: [item("fav", favorite: true), item("x", at: 9000)])
    #expect(s.decision("fav") == .keep)
    #expect(s.swipeQueue(singlesOnly: false) == ["x"])
}
@MainActor @Test func swipeAndUndoSharedWithGroups() {
    let s = makeSession(items: [item("a"), item("b", at: 10)])
    s.swipe("a", keep: false)
    s.swipe("b", keep: true)
    #expect(s.isDone(s.buckets.similar[0]))
    #expect(s.undo() == "b")
    #expect(s.decision("b") == .untouched)
    #expect(s.progress == 0.5)
}
@MainActor @Test func undoOnEmptyStackReturnsNil() {
    #expect(makeSession(items: [item("a")]).undo() == nil)
}
@MainActor @Test func swipeQueueSinglesOnly() {
    let s = makeSession(items: [item("g1"), item("g2", at: 5), item("solo", at: 9000)])
    #expect(s.swipeQueue(singlesOnly: true) == ["solo"])
    #expect(s.swipeQueue(singlesOnly: false) == ["g1", "g2", "solo"])
}
@MainActor @Test func reviewOrderIsSimilarThenScreenshotsThenFlaggedThenVideos() {
    let items = [item("v", .video, at: 0, duration: 1), item("f", at: 100), item("s1", .screenshot, at: 200), item("s2", .screenshot, at: 210),
                 item("p1", at: 300), item("p2", at: 310)]
    let s = makeSession(items: items, analyses: ["f": AnalysisResult(id: "f", flags: .dark, sharpness: 1, aesthetics: 0, featurePrint: nil, failed: false)])
    var kinds: [ReviewKind] = []
    while let set = s.nextReviewSet() { kinds.append(set.kind); s.confirm(set, keeping: []) }
    #expect(kinds == [.similar, .screenshots, .flagged, .shortVideos])
}
@MainActor @Test func summaryCountsScreenshotsSeparatelyAndBytes() {
    let s = makeSession(items: [item("p", at: 0, bytes: 3_000), item("s", .screenshot, at: 9000, bytes: nil), item("d", at: 20000, bytes: 2_000)])
    s.swipe("p", keep: true)
    s.swipe("s", keep: true)
    s.swipe("d", keep: false)
    #expect(s.summary == TripSummary(total: 3, best: 1, screenshots: 1, deleteCandidates: 1, untouched: 0, freeableBytes: 2_000, bytesIsEstimate: false))
}
@MainActor @Test func unknownSizeMakesBytesAnEstimate() {
    let s = makeSession(items: [item("d", bytes: nil)])
    s.swipe("d", keep: false)
    #expect(s.summary.bytesIsEstimate)
}
@MainActor @Test func finalizeBuildsAlbumsAndDeletes() async throws {
    let (s, lib) = makeSessionWithLibrary(items: [item("k"), item("sc", .screenshot, at: 9000), item("d", at: 20000)])
    s.swipe("k", keep: true)
    s.swipe("sc", keep: true)
    s.swipe("d", keep: false)
    let result = try await s.finalize(bestAlbum: "Jeju Best", screenshotAlbum: "Jeju Screenshots", deleteCandidates: true)
    #expect(result == FinalizeResult(albumUpdated: true, deleted: 1, deleteCancelled: false))
    #expect(lib.albums["Jeju Best"] == ["k"])
    #expect(lib.albums["Jeju Screenshots"] == ["sc"])
    #expect(lib.deleted == ["d"])
    #expect(s.summary.total == 2)
}
@MainActor @Test func finalizeAlbumOnlyDeletesNothing() async throws {
    let (s, lib) = makeSessionWithLibrary(items: [item("k"), item("d", at: 9000)])
    s.swipe("k", keep: true)
    s.swipe("d", keep: false)
    _ = try await s.finalize(bestAlbum: "B", screenshotAlbum: "S", deleteCandidates: false)
    #expect(lib.deleted.isEmpty)
    #expect(s.decision("d") == .deleteCandidate)
}
@MainActor @Test func finalizeRemovesNewDeleteCandidatesFromExistingAlbum() async throws {
    let (s, lib) = makeSessionWithLibrary(items: [item("a"), item("b", at: 9000)])
    lib.albums["B"] = ["a", "b"]
    s.swipe("a", keep: true)
    s.swipe("b", keep: false)
    _ = try await s.finalize(bestAlbum: "B", screenshotAlbum: "S", deleteCandidates: false)
    #expect(lib.albums["B"] == ["a"])
}
@MainActor @Test func test_finalize_deleteCancelled_keepsDecisions() async throws {
    let (s, lib) = makeSessionWithLibrary(items: [item("k"), item("d", at: 9000)])
    lib.deleteShouldCancel = true
    s.swipe("k", keep: true)
    s.swipe("d", keep: false)
    let result = try await s.finalize(bestAlbum: "Jeju Best", screenshotAlbum: "Jeju Screenshots", deleteCandidates: true)
    #expect(result == FinalizeResult(albumUpdated: true, deleted: 0, deleteCancelled: true))
    #expect(lib.albums["Jeju Best"] == ["k"])
    #expect(s.decision("d") == .deleteCandidate)
}
@MainActor @Test func test_missingAssets_areIgnored() {
    let store = memoryStore()
    store.set(.deleteCandidate, for: ["gone"])
    let s = makeSession(items: [item("a")], store: store)
    #expect(s.summary.total == 1)
    #expect(s.summary.deleteCandidates == 0)
}
@MainActor @Test func decisionsSurviveNewSession() {
    let store = memoryStore()
    makeSession(items: [item("a")], store: store).swipe("a", keep: true)
    #expect(makeSession(items: [item("a")], store: store).decision("a") == .keep)
}
@MainActor @Test func shortVideoThresholdChangesWhatIsShown() {
    let items = [item("v", .video, duration: 3)]
    #expect(makeSession(items: items).summary.total == 0)
    #expect(makeSession(items: items, settings: .init(recommendationEnabled: true, shortVideoMaxSeconds: 5)).summary.total == 1)
}

@MainActor @Test func finalizePutsAlbumsInFolder() async throws {
    let (s, lib) = makeSessionWithLibrary(items: [item("k"), item("sc", .screenshot, at: 9000)])
    s.swipe("k", keep: true)
    s.swipe("sc", keep: true)
    _ = try await s.finalize(bestAlbum: "오사카 Best", screenshotAlbum: "오사카 Screenshots", deleteCandidates: false, folder: "일본 여행")
    #expect(lib.albumFolders["오사카 Best"] == "일본 여행")
    #expect(lib.albumFolders["오사카 Screenshots"] == "일본 여행")
}
@MainActor @Test func finalizeWithoutFolderLeavesAlbumsAtTop() async throws {
    let (s, lib) = makeSessionWithLibrary(items: [item("k")])
    s.swipe("k", keep: true)
    _ = try await s.finalize(bestAlbum: "B", screenshotAlbum: "S", deleteCandidates: false)
    #expect(lib.albumFolders["B"] == nil)
    #expect(lib.albums["B"] == ["k"])
}

@MainActor @Test func reviewCanChangeOnePhotosDecision() {
    let s = makeSession(items: [item("a"), item("b", at: 9000), item("fav", at: 20000, favorite: true)])
    s.swipe("a", keep: false)
    s.setDecision(.keep, for: "a")
    #expect(s.decision("a") == .keep)
    s.setDecision(.untouched, for: "a")
    #expect(s.decision("a") == .untouched)
    s.setDecision(.deleteCandidate, for: "fav")
    #expect(s.decision("fav") == .deleteCandidate)
    #expect(s.summary.deleteCandidates == 1)
}
@MainActor @Test func itemsByDecisionAreInShootingOrder() {
    let s = makeSession(items: [item("late", at: 9000), item("early"), item("mid", at: 5000)])
    s.swipe("late", keep: false)
    s.swipe("early", keep: false)
    #expect(s.items(with: .deleteCandidate) == ["early", "late"])
    #expect(s.items(with: .untouched) == ["mid"])
}
@MainActor @Test func keptScreenshotsAreListedApart() {
    let s = makeSession(items: [item("p"), item("sc", .screenshot, at: 9000)])
    s.swipe("p", keep: true)
    s.swipe("sc", keep: true)
    #expect(s.items(with: .keep, screenshots: false) == ["p"])
    #expect(s.items(with: .keep, screenshots: true) == ["sc"])
}
