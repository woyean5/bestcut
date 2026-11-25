import Foundation

/// A place where several photos of a trip were taken.
public struct PlaceCluster: Equatable, Sendable {
    public var center: Coordinate
    public var count: Int
    public var firstDate: Date
}

public enum PlaceClusterer {
    /// Groups geotagged photos that lie within `radiusMeters` of a group's first photo; ordered by first visit.
    public static func clusters(_ items: [MediaItem], radiusMeters: Double = 25_000) -> [PlaceCluster] {
        var clusters: [PlaceCluster] = []
        for item in items.sorted(by: { $0.creationDate < $1.creationDate }) {
            guard let loc = item.location else { continue }
            if let i = clusters.firstIndex(where: { $0.center.distance(to: loc) <= radiusMeters }) {
                clusters[i].count += 1
            } else {
                clusters.append(PlaceCluster(center: loc, count: 1, firstDate: item.creationDate))
            }
        }
        return clusters
    }

    /// Places with enough photos to belong in a trip's name.
    public static func notable(_ clusters: [PlaceCluster], total: Int, minShare: Double = 0.1, minCount: Int = 3,
                               limit: Int = 5) -> [PlaceCluster] {
        let kept = clusters.filter { $0.count >= minCount && Double($0.count) >= minShare * Double(max(total, 1)) }
        let biggest = kept.sorted { $0.count > $1.count }.prefix(limit)
        return kept.filter { c in biggest.contains(c) }
    }
}

/// Turns coordinates into a city name, in the given language. Returns nil when it can't (offline, open sea).
public protocol PlaceNaming: Sendable {
    func cityName(for coordinate: Coordinate, locale: Locale) async -> String?
    /// City and country; by default only the city is known.
    func place(for coordinate: Coordinate, locale: Locale) async -> PlaceName?
}

public struct PlaceName: Sendable, Equatable {
    public var city: String
    public var country: String?
    public init(city: String, country: String?) {
        self.city = city
        self.country = country
    }
}

public extension PlaceNaming {
    func place(for coordinate: Coordinate, locale: Locale) async -> PlaceName? {
        await cityName(for: coordinate, locale: locale).map { PlaceName(city: $0, country: nil) }
    }
}

public enum TripTitle {
    public static let maxPlaces = 3

    /// City names for a trip, in visiting order, without repeats, at most three.
    public static func suggestedPlaces(items: [MediaItem], namer: PlaceNaming, locale: Locale) async -> [String] {
        let geotagged = items.filter { $0.location != nil }
        let places = PlaceClusterer.notable(PlaceClusterer.clusters(geotagged), total: geotagged.count)
        var names: [String] = []
        for place in places {
            guard let name = await namer.cityName(for: place.center, locale: locale), !names.contains(name) else { continue }
            names.append(name)
            if names.count == maxPlaces { break }
        }
        return names
    }

    /// "뉴욕·워싱턴", "ニューヨーク・ワシントン", "纽约、华盛顿", "New York & Washington", "Paris, Lyon & Nice".
    public static func join(_ names: [String], languageCode: String) -> String {
        switch languageCode {
        case "ko": return names.joined(separator: "·")
        case "ja": return names.joined(separator: "・")
        case "zh": return names.joined(separator: "、")
        default:
            guard names.count > 1 else { return names.first ?? "" }
            return names.dropLast().joined(separator: ", ") + " & " + names.last!
        }
    }
}
