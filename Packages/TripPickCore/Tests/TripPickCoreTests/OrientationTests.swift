import CoreGraphics
import ImageIO
import Testing
@testable import TripPickCore

private func wide() -> CGImage {
    let ctx = CGContext(data: nil, width: 200, height: 100, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setFillColor(gray: 1, alpha: 1); ctx.fill(CGRect(x: 0, y: 0, width: 200, height: 100))
    ctx.setFillColor(gray: 0, alpha: 1); ctx.fill(CGRect(x: 0, y: 90, width: 10, height: 10)) // top-left corner (CG origin is bottom-left)
    return ctx.makeImage()!
}

private func gray(_ img: CGImage, x: Int, y: Int) -> UInt8 {
    ImageQualityAnalyzer.grayscalePixels(img, maxPixel: 1000).data[y * img.width + x]
}

@Test func uprightKeepsUpImages() {
    let img = wide()
    #expect(ImageOrientation.upright(img, .up) === img)
}
@Test func uprightRotatesSidewaysPhotos() {
    let r = ImageOrientation.upright(wide(), .right)
    #expect(r.width == 100 && r.height == 200)
}
@Test func uprightFlipsUpsideDownPhotos() {
    let r = ImageOrientation.upright(wide(), .down)
    #expect(r.width == 200 && r.height == 100)
    #expect(gray(r, x: 195, y: 95) < 50)   // the dark top-left corner is now bottom-right (row 0 = top)
    #expect(gray(r, x: 5, y: 5) > 200)
}
