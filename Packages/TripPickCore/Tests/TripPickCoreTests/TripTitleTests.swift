import Foundation
import Testing
@testable import TripPickCore

private let nyc = Coordinate(latitude: 40.7580, longitude: -73.9855)
private let brooklyn = Coordinate(latitude: 40.6782, longitude: -73.9442)   // ~9 km from Times Square
private let dc = Coordinate(latitude: 38.8977, longitude: -77.0365)
private let boston = Coordinate(latitude: 42.3601, longitude: -71.0589)

private func at(_ c: Coordinate, _ n: Int, from start: TimeInterval) -> [MediaItem] {
    (0..<n).map { item("\(c.latitude)-\(start)-\($0)", at: start + Double($0), location: c) }
}

private struct FakeNamer: PlaceNaming {
    func cityName(for c: Coordinate, locale: Locale) async -> String? {
        if c.distance(to: nyc) < 30_000 { return locale.language.languageCode?.identifier == "ko" ? "뉴욕" : "New York" }
        if c.distance(to: dc) < 30_000 { return locale.language.languageCode?.identifier == "ko" ? "워싱턴" : "Washington" }
        if c.distance(to: boston) < 30_000 { return "Boston" }
        return nil
    }
}

@Test func nearbyPhotosFormOnePlace() {
    let items = at(nyc, 5, from: 0) + at(brooklyn, 5, from: 100)
    let clusters = PlaceClusterer.clusters(items)
    #expect(clusters.count == 1)
    #expect(clusters[0].count == 10)
}
@Test func placesAreOrderedByFirstVisit() {
    let items = at(dc, 4, from: 5_000) + at(nyc, 6, from: 0)
    let clusters = PlaceClusterer.clusters(items)
    #expect(clusters.count == 2)
    #expect(clusters[0].center.distance(to: nyc) < 5_000)
}
@Test func photosWithoutLocationAreIgnored() {
    #expect(PlaceClusterer.clusters([item("a"), item("b")]).isEmpty)
}
@Test func smallStopsAreLeftOut() {
    let items = at(nyc, 40, from: 0) + at(boston, 2, from: 10_000) + at(dc, 10, from: 20_000)
    let notable = PlaceClusterer.notable(PlaceClusterer.clusters(items), total: 52)
    #expect(notable.count == 2)   // Boston: 2 photos, under 3 and under 10%
}
@Test func joinNamesPerLanguage() {
    #expect(TripTitle.join(["뉴욕", "워싱턴"], languageCode: "ko") == "뉴욕·워싱턴")
    #expect(TripTitle.join(["ニューヨーク", "ワシントン"], languageCode: "ja") == "ニューヨーク・ワシントン")
    #expect(TripTitle.join(["New York", "Washington"], languageCode: "en") == "New York & Washington")
    #expect(TripTitle.join(["Paris", "Lyon", "Nice"], languageCode: "en") == "Paris, Lyon & Nice")
    #expect(TripTitle.join(["Paris"], languageCode: "en") == "Paris")
}
@Test func suggestedPlacesNamesCitiesInOrderWithoutRepeats() async {
    let items = at(nyc, 6, from: 0) + at(dc, 6, from: 10_000) + at(brooklyn, 6, from: 20_000)
    let names = await TripTitle.suggestedPlaces(items: items, namer: FakeNamer(), locale: Locale(identifier: "ko"))
    #expect(names == ["뉴욕", "워싱턴"])
}
@Test func noLocationsGivesNoSuggestion() async {
    #expect(await TripTitle.suggestedPlaces(items: [item("a")], namer: FakeNamer(), locale: Locale(identifier: "en")).isEmpty)
}
@Test func atMostThreePlaces() async {
    let far = (0..<5).flatMap { i in at(Coordinate(latitude: 10 + Double(i) * 5, longitude: 10), 5, from: Double(i) * 1_000) }
    struct Numbered: PlaceNaming {
        func cityName(for c: Coordinate, locale: Locale) async -> String? { "City\(Int(c.latitude))" }
    }
    #expect(await TripTitle.suggestedPlaces(items: far, namer: Numbered(), locale: Locale(identifier: "en")).count == 3)
}

@Test func cityNamesDropAdministrativeSuffixes() {
    #expect(CityName.clean(locality: "서울특별시", admin: "서울특별시", countryCode: "KR", languageCode: "ko") == "서울")
    #expect(CityName.clean(locality: "부산광역시", admin: "부산광역시", countryCode: "KR", languageCode: "ko") == "부산")
    #expect(CityName.clean(locality: "제주시", admin: "제주특별자치도", countryCode: "KR", languageCode: "ko") == "제주")
    #expect(CityName.clean(locality: "Jeju-si", admin: "Jeju-do", countryCode: "KR", languageCode: "en") == "Jeju")
    #expect(CityName.clean(locality: "오사카시", admin: "오사카부", countryCode: "JP", languageCode: "ko") == "오사카")
    #expect(CityName.clean(locality: "大阪市", admin: "大阪府", countryCode: "JP", languageCode: "ja") == "大阪")
    #expect(CityName.clean(locality: "뉴욕", admin: "NY", countryCode: "US", languageCode: "ko") == "뉴욕")
    #expect(CityName.clean(locality: "Paris", admin: "Île-de-France", countryCode: "FR", languageCode: "en") == "Paris")
}
@Test func tokyoWardsBecomeTokyo() {
    #expect(CityName.clean(locality: "지요다구", admin: "도쿄", countryCode: "JP", languageCode: "ko") == "도쿄")
    #expect(CityName.clean(locality: "Chiyoda", admin: "Tokyo", countryCode: "JP", languageCode: "en") == "Tokyo")
    #expect(CityName.clean(locality: "千代田区", admin: "東京都", countryCode: "JP", languageCode: "ja") == "東京")
}
@Test func shortNamesKeepTheirSuffix() {
    #expect(CityName.clean(locality: "시", admin: nil, countryCode: "KR", languageCode: "ko") == "시")
    #expect(CityName.clean(locality: nil, admin: "Bali", countryCode: "ID", languageCode: "en") == "Bali")
    #expect(CityName.clean(locality: nil, admin: nil, countryCode: nil, languageCode: "en") == nil)
}

@Test func chineseTitlesAndCityNames() {
    #expect(TripTitle.join(["纽约", "华盛顿"], languageCode: "zh") == "纽约、华盛顿")
    #expect(CityName.clean(locality: "上海市", admin: "上海市", countryCode: "CN", languageCode: "zh") == "上海")
    #expect(CityName.clean(locality: "大阪市", admin: "大阪府", countryCode: "JP", languageCode: "zh") == "大阪")
    #expect(CityName.clean(locality: "千代田区", admin: "东京都", countryCode: "JP", languageCode: "zh") == "东京")
    #expect(CityName.clean(locality: "纽约", admin: "NY", countryCode: "US", languageCode: "zh") == "纽约")
}
