import Foundation

/// One day of a date range and the city most of its geotagged photos were taken in.
public struct DayCity: Sendable, Equatable {
    public var day: Date
    public var city: String?
    public var country: String?
    public var count: Int

    public init(day: Date, city: String?, country: String?, count: Int) {
        self.day = day
        self.city = city
        self.country = country
        self.count = count
    }
}

/// Consecutive days spent in one city.
public struct CitySegment: Sendable, Equatable, Hashable {
    public var city: String
    public var country: String?
    public var start: Date
    /// Midnight of the last day.
    public var end: Date
    public var photoCount: Int
    var days: Int = 1
}

public enum TripSplitter {
    static let minPhotos = 3
    static let mergeRadiusMeters = 25_000.0

    /// City segments for a date range; empty unless there are at least two.
    public static func segments(days input: [DayCity], calendar: Calendar) -> [CitySegment] {
        var days = input.sorted { $0.day < $1.day }
        guard let firstKnown = days.firstIndex(where: { $0.city != nil }) else { return [] }
        // Days without a located photo join the previous city (the first ones join the next).
        var last = days[firstKnown]
        for i in days.indices {
            if days[i].city == nil {
                days[i].city = last.city
                days[i].country = last.country
            } else {
                last = days[i]
            }
        }
        var runs: [CitySegment] = []
        for d in days {
            if var run = runs.last, run.city == d.city {
                run.end = d.day
                run.photoCount += d.count
                run.days += 1
                runs[runs.count - 1] = run
            } else {
                runs.append(CitySegment(city: d.city!, country: d.country, start: d.day, end: d.day, photoCount: d.count))
            }
        }
        // Fold one-day or tiny stops into the bigger neighbour.
        while runs.count > 1, let i = runs.firstIndex(where: { $0.days == 1 || $0.photoCount < minPhotos }) {
            let prev = i > 0 ? i - 1 : nil, next = i + 1 < runs.count ? i + 1 : nil
            let target: Int = switch (prev, next) {
            case let (p?, n?): runs[p].photoCount >= runs[n].photoCount ? p : n
            case let (p?, nil): p
            case let (nil, n?): n
            default: i
            }
            var merged = runs[target]
            merged.start = min(merged.start, runs[i].start)
            merged.end = max(merged.end, runs[i].end)
            merged.photoCount += runs[i].photoCount
            merged.days += runs[i].days
            runs[target] = merged
            runs.remove(at: i)
            // Neighbours that now share a city become one.
            var j = 1
            while j < runs.count {
                if runs[j].city == runs[j - 1].city {
                    runs[j - 1].end = runs[j].end
                    runs[j - 1].photoCount += runs[j].photoCount
                    runs[j - 1].days += runs[j].days
                    runs.remove(at: j)
                } else { j += 1 }
            }
        }
        return runs.count >= 2 ? runs : []
    }

    /// Stretches segments so together they cover every day of the chosen range with no gaps:
    /// the first starts on the range's first day, each ends the day before the next starts, the last ends on the range's last day.
    public static func fill(_ segments: [CitySegment], range: DateInterval, calendar: Calendar) -> [CitySegment] {
        guard !segments.isEmpty else { return [] }
        var out = segments
        out[0].start = calendar.startOfDay(for: range.start)
        for i in out.indices.dropLast() {
            out[i].end = calendar.date(byAdding: .day, value: -1, to: out[i + 1].start) ?? out[i].end
        }
        let lastDay = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: range.end)) ?? out[out.count - 1].end
        out[out.count - 1].end = max(lastDay, out[out.count - 1].end)
        return out
    }

    /// Suggested city segments for the photos of a date range; empty when it's one place or locations are missing.
    public static func suggest(items: [MediaItem], namer: PlaceNaming, locale: Locale, range: DateInterval? = nil,
                               calendar: Calendar = .current) async -> [CitySegment] {
        let located = items.filter { $0.location != nil }
        var named: [(center: Coordinate, place: PlaceName)] = []
        for cluster in PlaceClusterer.clusters(located) where cluster.count >= minPhotos {
            if let place = await namer.place(for: cluster.center, locale: locale) { named.append((cluster.center, place)) }
        }
        guard named.count >= 2 else { return [] }

        var perDay: [Date: (places: [String: (PlaceName, Int)], total: Int)] = [:]
        for item in items {
            let day = calendar.startOfDay(for: item.creationDate)
            var entry = perDay[day] ?? ([:], 0)
            entry.total += 1
            if let loc = item.location,
               let nearest = named.min(by: { $0.center.distance(to: loc) < $1.center.distance(to: loc) }),
               nearest.center.distance(to: loc) <= mergeRadiusMeters {
                let current = entry.places[nearest.place.city]?.1 ?? 0
                entry.places[nearest.place.city] = (nearest.place, current + 1)
            }
            perDay[day] = entry
        }
        let days = perDay.map { day, entry -> DayCity in
            let top = entry.places.values.max { $0.1 < $1.1 }
            return DayCity(day: day, city: top?.0.city, country: top?.0.country, count: entry.total)
        }
        let found = segments(days: days, calendar: calendar)
        guard let range else { return found }
        return fill(found, range: range, calendar: calendar)
    }
}
