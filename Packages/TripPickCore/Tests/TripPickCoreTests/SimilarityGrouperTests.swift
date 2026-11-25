import Testing
@testable import TripPickCore

@Test func photosCloseInTimeAndLookAlikeAreGrouped() {
    let items = [item("a", at: 0), item("b", at: 30), item("c", at: 60), item("d", at: 400)]
    #expect(SimilarityGrouper.groups(for: items, distance: { _, _ in 0.2 }) == [["a", "b", "c"]])
}
@Test func lookAlikeButFarApartInPlaceIsNotGrouped() {
    let p1 = Coordinate(latitude: 33.45, longitude: 126.57), p2 = Coordinate(latitude: 33.46, longitude: 126.57)
    #expect(SimilarityGrouper.groups(for: [item("a", location: p1), item("b", at: 10, location: p2)], distance: { _, _ in 0.1 }).isEmpty)
}
@Test func differentLookingPhotosAreNotGrouped() {
    #expect(SimilarityGrouper.groups(for: [item("a"), item("b", at: 5)], distance: { _, _ in 0.9 }).isEmpty)
}
@Test func burstIsAlwaysGrouped() {
    #expect(SimilarityGrouper.groups(for: [item("a", burst: "x"), item("b", at: 200, burst: "x")], distance: { _, _ in nil }) == [["a", "b"]])
}
@Test func screenshotsGroupSeparatelyWithWiderGap() {
    let items = [item("s1", .screenshot), item("p1", .photo, at: 10), item("s2", .screenshot, at: 600)]
    #expect(SimilarityGrouper.groups(for: items, distance: { _, _ in 0.3 }) == [["s1", "s2"]])
}
@Test func videosAreIgnored() {
    #expect(SimilarityGrouper.groups(for: [item("v1", .video), item("v2", .video, at: 1)], distance: { _, _ in 0 }).isEmpty)
}
@Test func missingDistanceDoesNotGroup() {
    #expect(SimilarityGrouper.groups(for: [item("a"), item("b", at: 5)], distance: { _, _ in nil }).isEmpty)
}
