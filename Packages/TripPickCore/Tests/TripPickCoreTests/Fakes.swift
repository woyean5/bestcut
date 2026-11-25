import CoreGraphics
import Foundation
@testable import TripPickCore

let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

func item(_ id: String, _ kind: MediaKind = .photo, at seconds: TimeInterval = 0, favorite: Bool = false,
          duration: TimeInterval = 0, location: Coordinate? = nil, burst: String? = nil, bytes: Int64? = 1_000) -> MediaItem {
    MediaItem(id: id, kind: kind, creationDate: baseDate.addingTimeInterval(seconds), location: location,
              duration: duration, isFavorite: favorite, burstID: burst, byteSize: bytes)
}

final class FakePhotoLibrary: PhotoLibrary, @unchecked Sendable {
    var items: [MediaItem] = []
    var images: [String: CGImage] = [:]
    var albums: [String: [String]] = [:]
    var deleted: [String] = []
    var deleteShouldCancel = false
    var state: PermissionState = .full

    func permission() -> PermissionState { state }
    func requestPermission() async -> PermissionState { state }
    func fetchMedia(in interval: DateInterval) async -> [MediaItem] {
        items.filter { interval.contains($0.creationDate) }.sorted { $0.creationDate < $1.creationDate }
    }
    func analysisImage(for id: String, maxPixel: Int) async -> CGImage? { images[id] }
    func addToAlbum(named name: String, add: [String], remove: [String]) async throws {
        var current = albums[name] ?? []
        for id in add where !current.contains(id) { current.append(id) }
        current.removeAll { remove.contains($0) }
        albums[name] = current
    }
    func delete(_ ids: [String]) async throws -> DeleteOutcome {
        if deleteShouldCancel { return .cancelled }
        deleted += ids
        items.removeAll { ids.contains($0.id) }
        return .deleted(ids.count)
    }
}
