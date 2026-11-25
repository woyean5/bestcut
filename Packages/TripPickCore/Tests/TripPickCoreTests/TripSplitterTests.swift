import Foundation
import Testing
@testable import TripPickCore

private var utc: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }
private let day0 = Date(timeIntervalSince1970: 1_794_787_200) // 2026-11-16 00:00 UTC
private func day(_ n: Int) -> Date { day0.addingTimeInterval(Double(n) * 86_400) }
private func d(_ n: Int, _ city: String?, _ count: Int = 10, country: String? = "Japan") -> DayCity {
    DayCity(day: day(n), city: city, country: city == nil ? nil : country, count: count)
}

@Test func twoCitiesSplitByDay() {
    let s = TripSplitter.segments(days: [d(0, "Osaka"), d(1, "Osaka"), d(2, "Osaka"), d(3, "Tokyo"), d(4, "Tokyo"), d(5, "Tokyo")], calendar: utc)
    #expect(s.map(\.city) == ["Osaka", "Tokyo"])
    #expect(s[0].start == day(0) && s[0].end == day(2))
    #expect(s[1].start == day(3) && s[1].end == day(5))
    #expect(s[0].photoCount == 30)
}
@Test func singleCityNoSplit() {
    #expect(TripSplitter.segments(days: [d(0, "Osaka"), d(1, "Osaka")], calendar: utc).isEmpty)
}
@Test func noLocationsNoSplit() {
    #expect(TripSplitter.segments(days: [d(0, nil), d(1, nil)], calendar: utc).isEmpty)
}
@Test func oneDayTripIsMerged() {
    let s = TripSplitter.segments(days: [d(0, "Osaka"), d(1, "Osaka"), d(2, "Osaka"), d(3, "Kyoto", 8), d(4, "Tokyo"), d(5, "Tokyo"), d(6, "Tokyo")], calendar: utc)
    #expect(s.map(\.city) == ["Osaka", "Tokyo"])
    #expect(s[0].end == day(3) || s[1].start == day(3))
}
@Test func daysWithoutLocationJoinPrevious() {
    let s = TripSplitter.segments(days: [d(0, "Osaka"), d(1, nil, 5), d(2, "Osaka"), d(3, "Tokyo"), d(4, nil, 4), d(5, "Tokyo")], calendar: utc)
    #expect(s.map(\.city) == ["Osaka", "Tokyo"])
    #expect(s[0].end == day(2) && s[1].end == day(5))
}
@Test func leadingDayWithoutLocationJoinsNext() {
    let s = TripSplitter.segments(days: [d(0, nil, 2), d(1, "Osaka"), d(2, "Osaka"), d(3, "Tokyo"), d(4, "Tokyo")], calendar: utc)
    #expect(s.first?.start == day(0))
}
@Test func suggestUsesNamer() async {
    struct Namer: PlaceNaming {
        func cityName(for c: Coordinate, locale: Locale) async -> String? { nil }
        func place(for c: Coordinate, locale: Locale) async -> PlaceName? {
            c.longitude > 137 ? PlaceName(city: "Tokyo", country: "Japan") : PlaceName(city: "Osaka", country: "Japan")
        }
    }
    let osaka = Coordinate(latitude: 34.69, longitude: 135.50), tokyo = Coordinate(latitude: 35.68, longitude: 139.76)
    var items: [MediaItem] = []
    for dayIndex in 0..<4 {
        let loc = dayIndex < 2 ? osaka : tokyo
        for i in 0..<5 {
            items.append(MediaItem(id: "\(dayIndex)-\(i)", kind: .photo, creationDate: day(dayIndex).addingTimeInterval(36_000 + Double(i)),
                                   location: loc, duration: 0, isFavorite: false, burstID: nil, byteSize: 1))
        }
    }
    let s = await TripSplitter.suggest(items: items, namer: Namer(), locale: Locale(identifier: "en"), calendar: utc)
    #expect(s.map(\.city) == ["Osaka", "Tokyo"])
    #expect(s.allSatisfy { $0.country == "Japan" })
}
