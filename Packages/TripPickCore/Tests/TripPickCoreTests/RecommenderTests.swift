import Testing
@testable import TripPickCore

private func r(_ id: String, _ flags: QualityFlags = [], sharp: Double = 300, aes: Double = 0, failed: Bool = false) -> AnalysisResult {
    AnalysisResult(id: id, flags: flags, sharpness: sharp, aesthetics: aes, featurePrint: nil, failed: failed)
}

@Test func picksHighestScore() {
    let set = ReviewSet(id: "x", kind: .similar, itemIDs: ["a", "b", "c"])
    #expect(Recommender.recommendation(for: set, analyses: ["a": r("a", aes: 0.1), "b": r("b", aes: 0.8), "c": r("c", .eyesClosed, aes: 0.9)]) == "b")
}
@Test func screenshotsPickSharpest() {
    let set = ReviewSet(id: "x", kind: .screenshots, itemIDs: ["a", "b"])
    #expect(Recommender.recommendation(for: set, analyses: ["a": r("a", sharp: 900, aes: -1), "b": r("b", sharp: 100, aes: 1)]) == "a")
}
@Test func failedAreSkippedAndAllFailedGivesNil() {
    let set = ReviewSet(id: "x", kind: .similar, itemIDs: ["a", "b"])
    #expect(Recommender.recommendation(for: set, analyses: ["a": r("a", aes: 1, failed: true), "b": r("b")]) == "b")
    #expect(Recommender.recommendation(for: set, analyses: ["a": r("a", failed: true)]) == nil)
}
@Test func tieGoesToEarlierShot() {
    let set = ReviewSet(id: "x", kind: .similar, itemIDs: ["a", "b"])
    #expect(Recommender.recommendation(for: set, analyses: ["a": r("a"), "b": r("b")]) == "a")
}
@Test func flaggedSetsHaveNoRecommendation() {
    #expect(Recommender.recommendation(for: ReviewSet(id: "x", kind: .flagged, itemIDs: ["a"]), analyses: ["a": r("a")]) == nil)
}
