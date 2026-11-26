import AVKit
import Photos
import SwiftUI
import TripPickCore

/// Shows a library item as an image; videos show their first frame and play on tap.
struct AssetImageView: View {
    @Environment(AppModel.self) private var model
    let id: String
    var maxPixel: Int = 400
    var contentMode: ContentMode = .fill
    var isVideo = false
    @State private var image: CGImage?
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            if image == nil && player == nil { Rectangle().fill(.quaternary) }
            if let player {
                VideoPlayer(player: player)
            } else if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            }
            if isVideo, player == nil {
                Image(systemName: "play.fill")
                    .font(.title2)
                    .padding(14)
                    .glassEffect(.regular, in: .circle)
                    .onTapGesture { Task { await play() } }
            }
        }
        .clipped()
        .modifier(FitToImage(ratio: contentMode == .fit ? image.map { CGFloat($0.width) / CGFloat(max($0.height, 1)) } : nil))
        .task(id: id) {
            player = nil
            image = await model.library.analysisImage(for: id, maxPixel: maxPixel)
        }
    }

    private func play() async {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject else { return }
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        let item: AVPlayerItem? = await withCheckedContinuation { cont in
            PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { item, _ in cont.resume(returning: item) }
        }
        guard let item else { return }
        let p = AVPlayer(playerItem: item)
        player = p
        p.play()
    }
}

/// In fit mode the view takes the photo's own shape, so badges and buttons laid over it sit on the photo's corners.
private struct FitToImage: ViewModifier {
    let ratio: CGFloat?
    func body(content: Content) -> some View {
        if let ratio { content.aspectRatio(ratio, contentMode: .fit) } else { content }
    }
}
