// Draws the 1024×1024 app icon: swift scripts/make_icon.swift <out.png>
// Three stacked photo cards on a teal-to-blue background; the front card shows a sun and mountains with a check badge.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let S = 1024.0
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
func c(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor { CGColor(colorSpace: cs, components: [r, g, b, a])! }

// Background gradient
let bg = CGGradient(colorsSpace: cs, colors: [c(0.10, 0.74, 0.78), c(0.13, 0.42, 0.93)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: S), end: CGPoint(x: S, y: 0), options: [])

func card(center: CGPoint, angle: Double, fill: CGColor, shadow: Bool) {
    ctx.saveGState()
    ctx.translateBy(x: center.x, y: center.y)
    ctx.rotate(by: angle * .pi / 180)
    let rect = CGRect(x: -250, y: -300, width: 500, height: 600)
    if shadow { ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 40, color: c(0, 0, 0, 0.25)) }
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: 64, cornerHeight: 64, transform: nil))
    ctx.setFillColor(fill)
    ctx.fillPath()
    ctx.restoreGState()
}

card(center: CGPoint(x: 470, y: 520), angle: 14, fill: c(1, 1, 1, 0.35), shadow: false)
card(center: CGPoint(x: 500, y: 510), angle: 6, fill: c(1, 1, 1, 0.55), shadow: false)
card(center: CGPoint(x: 512, y: 500), angle: -4, fill: c(1, 1, 1, 1), shadow: true)

// Photo inside the front card
ctx.saveGState()
ctx.translateBy(x: 512, y: 500)
ctx.rotate(by: -4 * .pi / 180)
let photo = CGRect(x: -210, y: -150, width: 420, height: 410)
ctx.addPath(CGPath(roundedRect: photo, cornerWidth: 36, cornerHeight: 36, transform: nil))
ctx.clip()
let sky = CGGradient(colorsSpace: cs, colors: [c(0.55, 0.85, 1.0), c(0.98, 0.84, 0.62)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(sky, start: CGPoint(x: 0, y: photo.maxY), end: CGPoint(x: 0, y: photo.minY), options: [])
ctx.setFillColor(c(1.0, 0.72, 0.25))
ctx.fillEllipse(in: CGRect(x: 60, y: 110, width: 110, height: 110))
ctx.setFillColor(c(0.18, 0.55, 0.45))
ctx.move(to: CGPoint(x: -230, y: -150)); ctx.addLine(to: CGPoint(x: -70, y: 90)); ctx.addLine(to: CGPoint(x: 40, y: -20))
ctx.addLine(to: CGPoint(x: 120, y: 40)); ctx.addLine(to: CGPoint(x: 240, y: -150)); ctx.closePath(); ctx.fillPath()
ctx.setFillColor(c(0.10, 0.40, 0.36))
ctx.move(to: CGPoint(x: -60, y: -150)); ctx.addLine(to: CGPoint(x: 90, y: 0)); ctx.addLine(to: CGPoint(x: 240, y: -150)); ctx.closePath(); ctx.fillPath()
ctx.restoreGState()

// Check badge
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: c(0, 0, 0, 0.25))
ctx.setFillColor(c(0.20, 0.78, 0.35))
ctx.fillEllipse(in: CGRect(x: 640, y: 170, width: 230, height: 230))
ctx.restoreGState()
ctx.setStrokeColor(c(1, 1, 1))
ctx.setLineWidth(34); ctx.setLineCap(.round); ctx.setLineJoin(.round)
ctx.move(to: CGPoint(x: 700, y: 290)); ctx.addLine(to: CGPoint(x: 745, y: 240)); ctx.addLine(to: CGPoint(x: 815, y: 335)); ctx.strokePath()

let url = URL(fileURLWithPath: CommandLine.arguments[1])
let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
CGImageDestinationFinalize(dest)
print("wrote \(url.path)")
