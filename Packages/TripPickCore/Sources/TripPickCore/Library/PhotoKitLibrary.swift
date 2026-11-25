import CoreGraphics
import Foundation
import Photos
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

public final class PhotoKitLibrary: PhotoLibrary {
    public init() {}

    public func permission() -> PermissionState {
        PermissionState(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    public func requestPermission() async -> PermissionState {
        PermissionState(await PHPhotoLibrary.requestAuthorization(for: .readWrite))
    }

    public func fetchMedia(in interval: DateInterval) async -> [MediaItem] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate < %@", interval.start as NSDate, interval.end as NSDate)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        options.includeAllBurstAssets = true
        let result = PHAsset.fetchAssets(with: options)
        var items: [MediaItem] = []
        items.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            let kind: MediaKind
            switch asset.mediaType {
            case .image: kind = asset.mediaSubtypes.contains(.photoScreenshot) ? .screenshot : .photo
            case .video: kind = .video
            default: return
            }
            let coord = asset.location.map { Coordinate(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude) }
            items.append(MediaItem(id: asset.localIdentifier, kind: kind, creationDate: asset.creationDate ?? interval.start,
                                   location: coord, duration: asset.duration, isFavorite: asset.isFavorite,
                                   burstID: asset.burstIdentifier, byteSize: Self.byteSize(of: asset)))
        }
        return items
    }

    private static func byteSize(of asset: PHAsset) -> Int64? {
        let resources = PHAssetResource.assetResources(for: asset)
        let primary = resources.first { $0.type == .photo || $0.type == .video } ?? resources.first
        return (primary?.value(forKey: "fileSize") as? NSNumber)?.int64Value
    }

    public func analysisImage(for id: String, maxPixel: Int) async -> CGImage? {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject else { return nil }
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        let side = CGFloat(maxPixel)
        return await withCheckedContinuation { cont in
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: side, height: side),
                                                  contentMode: .aspectFit, options: options) { image, _ in
                #if canImport(UIKit)
                guard let image, let cg = image.cgImage else { cont.resume(returning: nil); return }
                cont.resume(returning: ImageOrientation.upright(cg, CGImagePropertyOrientation(image.imageOrientation)))
                #else
                cont.resume(returning: image?.cgImage(forProposedRect: nil, context: nil, hints: nil))
                #endif
            }
        }
    }

    public func addToAlbum(named name: String, add: [String], remove: [String]) async throws {
        let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        var existing: PHAssetCollection?
        albums.enumerateObjects { c, _, stop in
            if c.localizedTitle == name { existing = c; stop.pointee = true }
        }
        let toAdd = PHAsset.fetchAssets(withLocalIdentifiers: add, options: nil)
        let toRemove = PHAsset.fetchAssets(withLocalIdentifiers: remove, options: nil)
        try await PHPhotoLibrary.shared().performChanges {
            if let existing, let req = PHAssetCollectionChangeRequest(for: existing) {
                if toAdd.count > 0 { req.addAssets(toAdd) }
                if toRemove.count > 0 { req.removeAssets(toRemove) }
            } else if toAdd.count > 0 {
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name).addAssets(toAdd)
            }
        }
    }

    public func delete(_ ids: [String]) async throws -> DeleteOutcome {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        guard assets.count > 0 else { return .deleted(0) }
        do {
            try await PHPhotoLibrary.shared().performChanges { PHAssetChangeRequest.deleteAssets(assets) }
            return .deleted(assets.count)
        } catch let error as NSError where Self.isUserCancel(error) {
            return .cancelled
        }
    }

    static func isUserCancel(_ error: NSError) -> Bool {
        (error.domain == PHPhotosErrorDomain && error.code == PHPhotosError.userCancelled.rawValue)
            || (error.domain == NSCocoaErrorDomain && error.code == 3072)
    }
}

#if canImport(UIKit)
extension CGImagePropertyOrientation {
    init(_ o: UIImage.Orientation) {
        switch o {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
#endif
