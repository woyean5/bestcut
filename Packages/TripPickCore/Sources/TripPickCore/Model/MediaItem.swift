import Foundation

public enum MediaKind: String, Codable, Sendable {
    case photo, screenshot, video
}

public struct Coordinate: Hashable, Codable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Great-circle distance in meters (haversine).
    public func distance(to other: Coordinate) -> Double {
        let r = 6_371_000.0
        let lat1 = latitude * .pi / 180, lat2 = other.latitude * .pi / 180
        let dLat = lat2 - lat1, dLon = (other.longitude - longitude) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * r * atan2(sqrt(a), sqrt(1 - a))
    }
}

public struct MediaItem: Identifiable, Hashable, Sendable {
    public var id: String
    public var kind: MediaKind
    public var creationDate: Date
    public var location: Coordinate?
    public var duration: TimeInterval
    public var isFavorite: Bool
    public var burstID: String?
    public var byteSize: Int64?

    public init(id: String, kind: MediaKind, creationDate: Date, location: Coordinate?, duration: TimeInterval,
                isFavorite: Bool, burstID: String?, byteSize: Int64?) {
        self.id = id
        self.kind = kind
        self.creationDate = creationDate
        self.location = location
        self.duration = duration
        self.isFavorite = isFavorite
        self.burstID = burstID
        self.byteSize = byteSize
    }
}
