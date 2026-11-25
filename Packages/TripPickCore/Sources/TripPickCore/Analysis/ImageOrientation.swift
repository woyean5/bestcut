import CoreGraphics
import CoreImage
import ImageIO

/// Camera photos are often stored sideways with an orientation tag; this turns the pixels upright
/// so both the screen and Vision see the photo the way it was taken.
public enum ImageOrientation {
    private static let context = CIContext()

    public static func upright(_ image: CGImage, _ orientation: CGImagePropertyOrientation) -> CGImage {
        guard orientation != .up else { return image }
        let ci = CIImage(cgImage: image).oriented(orientation)
        return context.createCGImage(ci, from: ci.extent) ?? image
    }
}
