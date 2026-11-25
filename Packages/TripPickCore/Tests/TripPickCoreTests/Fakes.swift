import Foundation
@testable import TripPickCore

let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

func item(_ id: String, _ kind: MediaKind = .photo, at seconds: TimeInterval = 0, favorite: Bool = false,
          duration: TimeInterval = 0, location: Coordinate? = nil, burst: String? = nil, bytes: Int64? = 1_000) -> MediaItem {
    MediaItem(id: id, kind: kind, creationDate: baseDate.addingTimeInterval(seconds), location: location,
              duration: duration, isFavorite: favorite, burstID: burst, byteSize: bytes)
}
