import CoreGraphics
import CoreImage

enum TestImages {
    static let size = 512

    static func context() -> CGContext {
        CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    }

    static func checkerboard(cell: Int, light: CGFloat = 1, dark: CGFloat = 0) -> CGImage {
        let ctx = context()
        ctx.setFillColor(gray: light, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
        ctx.setFillColor(gray: dark, alpha: 1)
        for y in stride(from: 0, to: size, by: cell) {
            for x in stride(from: 0, to: size, by: cell) where (x / cell + y / cell) % 2 == 0 {
                ctx.fill(CGRect(x: x, y: y, width: cell, height: cell))
            }
        }
        return ctx.makeImage()!
    }

    static func solid(gray: CGFloat) -> CGImage {
        let ctx = context()
        ctx.setFillColor(gray: gray, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
        return ctx.makeImage()!
    }

    static func blurred(_ image: CGImage, radius: Double) -> CGImage {
        let input = CIImage(cgImage: image)
        let output = input.clampedToExtent().applyingGaussianBlur(sigma: radius).cropped(to: input.extent)
        return CIContext().createCGImage(output, from: input.extent)!
    }
}
