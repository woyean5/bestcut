// Draws the app icon in iOS's three styles: swift scripts/make_icon.swift <out-dir>
// Simple and Apple-like: a photo card lifted from a stack, with a small check. Light, dark, and tinted (grayscale).
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let S: CGFloat = 1024
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
func c(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor { CGColor(colorSpace: cs, components: [r, g, b, a])! }

struct Style {
    var bgTop, bgBottom: CGColor          // background gradient (top-left → bottom-right)
    var backCard, card: CGColor           // stacked card and front card
    var sky, sun, hill, hillDark: CGColor // the little photo
    var badge, check: CGColor
    var shadow: CGColor
}

let light = Style(bgTop: c(0.36, 0.78, 0.98), bgBottom: c(0.12, 0.45, 0.95),
                  backCard: c(1, 1, 1, 0.45), card: c(1, 1, 1),
                  sky: c(0.82, 0.92, 1.0), sun: c(1.0, 0.76, 0.22), hill: c(0.27, 0.70, 0.52), hillDark: c(0.16, 0.55, 0.42),
                  badge: c(0.20, 0.78, 0.35), check: c(1, 1, 1), shadow: c(0, 0.1, 0.3, 0.28))
let dark = Style(bgTop: c(0.13, 0.14, 0.17), bgBottom: c(0.05, 0.05, 0.07),
                 backCard: c(0.40, 0.62, 0.95, 0.35), card: c(0.20, 0.21, 0.24),
                 sky: c(0.16, 0.30, 0.50), sun: c(1.0, 0.76, 0.22), hill: c(0.25, 0.66, 0.50), hillDark: c(0.15, 0.50, 0.38),
                 badge: c(0.20, 0.78, 0.35), check: c(1, 1, 1), shadow: c(0, 0, 0, 0.5))
// Tinted: grayscale on black; iOS tints the light parts.
let tinted = Style(bgTop: c(0, 0, 0), bgBottom: c(0, 0, 0),
                   backCard: c(1, 1, 1, 0.35), card: c(1, 1, 1),
                   sky: c(0.82, 0.82, 0.82), sun: c(0.45, 0.45, 0.45), hill: c(0.55, 0.55, 0.55), hillDark: c(0.40, 0.40, 0.40),
                   badge: c(1, 1, 1), check: c(0, 0, 0), shadow: c(0, 0, 0, 0))

func draw(_ s: Style) -> CGImage {
    let ctx = CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.translateBy(x: 0, y: S); ctx.scaleBy(x: 1, y: -1)   // top-left origin
    let bg = CGGradient(colorsSpace: cs, colors: [s.bgTop, s.bgBottom] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(bg, start: .zero, end: CGPoint(x: S, y: S), options: [])

    let cardSize = CGSize(width: 520, height: 420)
    func cardPath(_ center: CGPoint, _ angle: CGFloat) -> CGPath {
        var t = CGAffineTransform(translationX: center.x, y: center.y).rotated(by: angle * .pi / 180)
        return CGPath(roundedRect: CGRect(x: -cardSize.width / 2, y: -cardSize.height / 2, width: cardSize.width, height: cardSize.height),
                      cornerWidth: 64, cornerHeight: 64, transform: &t)
    }

    // One card behind, tilted.
    ctx.addPath(cardPath(CGPoint(x: 548, y: 560), 10)); ctx.setFillColor(s.backCard); ctx.fillPath()

    // The front card, lifted.
    let front = CGPoint(x: 492, y: 500), angle: CGFloat = -6
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: 22), blur: 48, color: s.shadow)
    ctx.addPath(cardPath(front, angle)); ctx.setFillColor(s.card); ctx.fillPath()
    ctx.restoreGState()

    // The photo inside the card.
    ctx.saveGState()
    ctx.translateBy(x: front.x, y: front.y); ctx.rotate(by: angle * .pi / 180)
    let photo = CGRect(x: -cardSize.width / 2 + 36, y: -cardSize.height / 2 + 36, width: cardSize.width - 72, height: cardSize.height - 72)
    ctx.addPath(CGPath(roundedRect: photo, cornerWidth: 34, cornerHeight: 34, transform: nil)); ctx.clip()
    ctx.setFillColor(s.sky); ctx.fill(photo)
    ctx.setFillColor(s.sun); ctx.fillEllipse(in: CGRect(x: photo.maxX - 140, y: photo.minY + 44, width: 92, height: 92))
    ctx.setFillColor(s.hill)
    ctx.move(to: CGPoint(x: photo.minX - 10, y: photo.maxY)); ctx.addLine(to: CGPoint(x: photo.minX + 150, y: photo.minY + 130))
    ctx.addLine(to: CGPoint(x: photo.minX + 300, y: photo.maxY)); ctx.closePath(); ctx.fillPath()
    ctx.setFillColor(s.hillDark)
    ctx.move(to: CGPoint(x: photo.minX + 170, y: photo.maxY)); ctx.addLine(to: CGPoint(x: photo.minX + 320, y: photo.minY + 175))
    ctx.addLine(to: CGPoint(x: photo.maxX + 20, y: photo.maxY)); ctx.closePath(); ctx.fillPath()
    ctx.restoreGState()

    // Check badge on the picked card's corner.
    let badge = CGRect(x: 640, y: 610, width: 210, height: 210)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: 12), blur: 28, color: s.shadow)
    ctx.setFillColor(s.badge); ctx.fillEllipse(in: badge)
    ctx.restoreGState()
    ctx.setStrokeColor(s.check); ctx.setLineWidth(30); ctx.setLineCap(.round); ctx.setLineJoin(.round)
    ctx.move(to: CGPoint(x: 694, y: 718)); ctx.addLine(to: CGPoint(x: 734, y: 758)); ctx.addLine(to: CGPoint(x: 800, y: 676)); ctx.strokePath()
    return ctx.makeImage()!
}

func save(_ img: CGImage, _ path: String) {
    let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, nil); CGImageDestinationFinalize(dest)
}
let dir = CommandLine.arguments[1]
save(draw(light), dir + "/AppIcon-1024.png")
save(draw(dark), dir + "/AppIcon-1024-dark.png")
save(draw(tinted), dir + "/AppIcon-1024-tinted.png")
print("wrote light, dark and tinted icons to \(dir)")
