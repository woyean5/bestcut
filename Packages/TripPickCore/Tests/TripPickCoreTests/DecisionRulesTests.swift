import Testing
@testable import TripPickCore

@Test func storedDecisionWins() {
    #expect(DecisionRules.effective(stored: .deleteCandidate, item: item("a", favorite: true)) == .deleteCandidate)
}
@Test func favoriteDefaultsToKeep() { #expect(DecisionRules.effective(stored: nil, item: item("a", favorite: true)) == .keep) }
@Test func othersDefaultToUntouched() { #expect(DecisionRules.effective(stored: nil, item: item("a")) == .untouched) }
@Test func coordinateDistance() {
    let seoul = Coordinate(latitude: 37.5665, longitude: 126.9780), busan = Coordinate(latitude: 35.1796, longitude: 129.0756)
    #expect(abs(seoul.distance(to: busan) - 325_000) < 5_000)
}
