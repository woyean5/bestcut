import Foundation
import Testing
@testable import TripPickCore

@Test func endBeforeStartIsInvalid() {
    let r = TripRange(start: .init(timeIntervalSince1970: 1_700_200_000), end: .init(timeIntervalSince1970: 1_700_000_000))
    #expect(r.interval == nil)
    #expect(TripRange.validate(r, mediaCount: 5) == .endBeforeStart)
}
@Test func emptyRangeIsInvalid() {
    #expect(TripRange.validate(TripRange(start: baseDate, end: baseDate), mediaCount: 0) == .noMedia)
}
@Test func validRangeHasNoIssue() {
    #expect(TripRange.validate(TripRange(start: baseDate, end: baseDate), mediaCount: 3) == nil)
}
@Test func sameDayRangeCoversWholeDay() {
    #expect(TripRange(start: baseDate, end: baseDate).interval!.duration == 86_400)
}
