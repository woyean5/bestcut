import CoreGraphics
import Foundation

public enum DeleteOutcome: Sendable, Equatable {
    case deleted(Int)
    /// The user declined the system confirmation.
    case cancelled
}

/// Everything the app needs from the photo library. Tests use a fake.
public protocol PhotoLibrary: Sendable {
    func permission() -> PermissionState
    func requestPermission() async -> PermissionState
    /// Photos, screenshots and videos created inside the interval, in shooting order.
    func fetchMedia(in interval: DateInterval) async -> [MediaItem]
    /// A downscaled image for analysis or display; nil when it cannot be loaded.
    func analysisImage(for id: String, maxPixel: Int) async -> CGImage?
    /// Adds to (creating if needed) the album with this exact name, and removes the given items from it.
    /// With a folder name, the album lives inside that Photos folder (created if needed).
    func addToAlbum(named name: String, add: [String], remove: [String], inFolder folder: String?) async throws
    func delete(_ ids: [String]) async throws -> DeleteOutcome
}

public extension PhotoLibrary {
    func addToAlbum(named name: String, add: [String], remove: [String]) async throws {
        try await addToAlbum(named: name, add: add, remove: remove, inFolder: nil)
    }
}
