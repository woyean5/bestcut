// Draws scenic placeholder "travel photos" for App Store screenshots: swift scripts/make_store_photos.swift <outdir>
// Each scene is shot 3-4 times a few seconds apart (a similar group); some shots are blurred, one is dark.
import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

let out = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
let W = 1200, H = 1600
let base = ISO8601DateFormatter().date(from: "2026-11-22T01:00:00Z")!
let exifFormat: DateFormatter = { let f = DateFormatter(); f.dateFormat = "yyyy:MM:dd HH:mm:ss"; f.timeZone = TimeZone(identifier: "UTC"); return f }()

typealias RGB = (Double, Double, Double)
func rgb(_ hex: UInt32) -> RGB { (Double((hex >> 16) & 0xff) / 255, Double((hex >> 8) & 0xff) / 255, Double(hex & 0xff) / 255) }

struct Canvas {
    let ctx: CGContext
    let dx: Double, dy: Double, zoom: Double
    func color(_ c: RGB, _ a: Double = 1) -> CGColor { CGColor(red: c.0, green: c.1, blue: c.2, alpha: a) }
    /// Vertical gradient between y0 and y1 (top-down coordinates).
    func gradient(_ colors: [RGB], from y0: Double, to y1: Double) {
        let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors.map { color($0) } as CFArray, locations: nil)!
        ctx.saveGState()
        ctx.clip(to: CGRect(x: 0, y: y0, width: Double(W), height: y1 - y0))
        ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: y0), end: CGPoint(x: 0, y: y1), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        ctx.restoreGState()
    }
    /// A filled ridge: y = base + sum of sines, filled down to `bottom`.
    func ridge(base: Double, amps: [(Double, Double, Double)], fill: RGB, alpha: Double = 1, bottom: Double = Double(H)) {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -50, y: bottom))
        for x in stride(from: -50.0, through: Double(W) + 50, by: 8) {
            let xx = (x - dx) / zoom
            var y = base
            for (a, f, p) in amps { y += a * sin(xx * f + p) }
            path.addLine(to: CGPoint(x: x, y: y + dy))
        }
        path.addLine(to: CGPoint(x: Double(W) + 50, y: bottom))
        path.closeSubpath()
        ctx.addPath(path)
        ctx.setFillColor(color(fill, alpha))
        ctx.fillPath()
    }
    func disc(_ x: Double, _ y: Double, _ r: Double, _ c: RGB, _ a: Double = 1) {
        ctx.setFillColor(color(c, a))
        ctx.fillEllipse(in: CGRect(x: x * zoom + dx - r * zoom, y: y + dy - r * zoom, width: 2 * r * zoom, height: 2 * r * zoom))
    }
    func rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ c: RGB, _ a: Double = 1) {
        ctx.setFillColor(color(c, a))
        ctx.fill(CGRect(x: x * zoom + dx, y: y + dy, width: w * zoom, height: h))
    }
}

func makeContext() -> CGContext {
    let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    // Draw top-down like a photo.
    ctx.translateBy(x: 0, y: Double(H))
    ctx.scaleBy(x: 1, y: -1)
    return ctx
}

func beach(_ c: Canvas) {
    c.gradient([rgb(0x2b1a4f), rgb(0xd9547a), rgb(0xffa45c), rgb(0xffd89a)], from: 0, to: 980)
    c.disc(640, 900, 120, rgb(0xfff1c9))
    c.disc(640, 900, 190, rgb(0xffe0a0), 0.25)
    c.gradient([rgb(0xe98a6e), rgb(0x5a3a6e), rgb(0x23264a)], from: 960, to: 1600)
    for i in 0..<14 { c.rect(640 - 140 + Double(i % 3) * 20 - Double(i) * 4, 990 + Double(i) * 26, 280 - Double(i) * 14, 6, rgb(0xffd89a), 0.55) }
    c.ridge(base: 1380, amps: [(30, 0.004, 1), (12, 0.013, 2)], fill: rgb(0xf3c99a))
    c.ridge(base: 1470, amps: [(20, 0.006, 0)], fill: rgb(0xe8b483))
    // palm silhouette
    c.rect(150, 700, 26, 760, rgb(0x1d1430))
    for (ox, oy, r) in [(90.0, 700.0, 90.0), (240.0, 690.0, 100.0), (165.0, 640.0, 80.0), (60.0, 760.0, 70.0), (280.0, 760.0, 70.0)] {
        c.disc(ox, oy, r, rgb(0x1d1430))
    }
}

func mountainLake(_ c: Canvas) {
    c.gradient([rgb(0x5aa2e6), rgb(0xa9d3f5), rgb(0xe8f4fb)], from: 0, to: 900)
    c.disc(900, 260, 70, rgb(0xffffff), 0.9)
    c.ridge(base: 560, amps: [(150, 0.008, 2.0), (40, 0.025, 0.2)], fill: rgb(0xf4f8fc))
    c.ridge(base: 700, amps: [(170, 0.006, 0.4), (60, 0.019, 1.3)], fill: rgb(0x8aa4c4))
    c.ridge(base: 760, amps: [(110, 0.009, 1.1), (35, 0.031, 2.2)], fill: rgb(0x4f6d8f))
    c.ridge(base: 860, amps: [(40, 0.02, 0.5), (18, 0.07, 1)], fill: rgb(0x2f5a3e))
    c.gradient([rgb(0x3d6f8f), rgb(0x5f97b8), rgb(0x2e5470)], from: 900, to: 1600)
    c.ridge(base: 960, amps: [(-90, 0.009, 1.1), (-30, 0.031, 2.2)], fill: rgb(0x4f6d8f), alpha: 0.35, bottom: 900)
    for i in 0..<10 { c.rect(Double(i * 130 % 1100), 1000 + Double(i) * 55, 160, 4, rgb(0xffffff), 0.25) }
    c.ridge(base: 1450, amps: [(25, 0.01, 0)], fill: rgb(0x3b4a2e))
}

func cityNight(_ c: Canvas) {
    c.gradient([rgb(0x0b1030), rgb(0x23306b), rgb(0x6a4c8c), rgb(0xe08a6a)], from: 0, to: 1100)
    c.disc(300, 260, 46, rgb(0xfdf6e3))
    var g = SeededRNG(seed: 7)
    var x = -20.0
    while x < 1250 {
        let w = Double.random(in: 70...170, using: &g), h = Double.random(in: 300...900, using: &g)
        let shade = Double.random(in: 0.08...0.18, using: &g)
        c.rect(x, 1200 - h, w, h + 400, (shade, shade, shade + 0.08))
        var wy = 1200 - h + 30
        while wy < 1180 {
            var wx = x + 12
            while wx < x + w - 20 {
                if Double.random(in: 0...1, using: &g) < 0.45 { c.rect(wx, wy, 12, 18, rgb(0xffd27a), 0.9) }
                wx += 26
            }
            wy += 34
        }
        x += w + 6
    }
    c.gradient([rgb(0x141a3a), rgb(0x0a0d20)], from: 1200, to: 1600)
    for i in 0..<30 { c.rect(Double(i * 41 % 1200), 1230 + Double(i * 13 % 340), 50, 5, rgb(0xffd27a), 0.35) }
}

func forest(_ c: Canvas) {
    c.gradient([rgb(0xcfe6d8), rgb(0xf3efe0)], from: 0, to: 900)
    c.disc(780, 330, 150, rgb(0xfff6d8), 0.8)
    for (layer, color, base) in [(0, 0x9cc3a8, 760.0), (1, 0x6f9f82, 900.0), (2, 0x3f6f55, 1060.0), (3, 0x22432f, 1260.0)] {
        var g = SeededRNG(seed: UInt64(layer + 3))
        var x = -60.0
        while x < 1260 {
            let h = Double.random(in: 260...520, using: &g) * (1 + Double(layer) * 0.25)
            let w = h * 0.42
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x * c.zoom + c.dx, y: base - h + c.dy))
            path.addLine(to: CGPoint(x: (x - w / 2) * c.zoom + c.dx, y: base + c.dy))
            path.addLine(to: CGPoint(x: (x + w / 2) * c.zoom + c.dx, y: base + c.dy))
            path.closeSubpath()
            c.ctx.addPath(path)
            c.ctx.setFillColor(c.color(rgb(UInt32(color))))
            c.ctx.fillPath()
            x += w * 0.7
        }
        c.rect(-100, base - 2, 1500, 1600 - base, rgb(UInt32(color)))
    }
}

func desert(_ c: Canvas) {
    c.gradient([rgb(0x3f8fd8), rgb(0x9cd0f0), rgb(0xfbe3c0)], from: 0, to: 820)
    c.disc(260, 300, 80, rgb(0xfffbe8))
    c.ridge(base: 800, amps: [(70, 0.004, 0.3), (30, 0.011, 1)], fill: rgb(0xe9a86a))
    c.ridge(base: 960, amps: [(90, 0.005, 2.1), (20, 0.017, 0.4)], fill: rgb(0xd98b4e))
    c.ridge(base: 1040, amps: [(-60, 0.005, 2.1)], fill: rgb(0xb8693a), alpha: 0.6)
    c.ridge(base: 1180, amps: [(110, 0.004, 4.0), (25, 0.02, 1.1)], fill: rgb(0xf0b97c))
    c.ridge(base: 1360, amps: [(70, 0.006, 1.7)], fill: rgb(0xc77a43))
    for i in 0..<5 { c.disc(560 + Double(i) * 36, 1150 - Double(i) * 8, 9, rgb(0x3a2a1e)) }
}

func blossom(_ c: Canvas) {
    c.gradient([rgb(0xbfe0f7), rgb(0xf7e9f0)], from: 0, to: 1600)
    var g = SeededRNG(seed: 11)
    c.ridge(base: 1300, amps: [(30, 0.006, 0.2)], fill: rgb(0x8bb67a))
    for _ in 0..<5 {
        let bx = Double.random(in: 0...1200, using: &g)
        c.rect(bx - 12, 700, 24, 700, rgb(0x5b3a2e))
        for _ in 0..<70 {
            let r = Double.random(in: 40...90, using: &g)
            c.disc(bx + Double.random(in: -260...260, using: &g), Double.random(in: 280...820, using: &g), r,
                   Double.random(in: 0...1, using: &g) < 0.5 ? rgb(0xf6b6c8) : rgb(0xfbd3de), 0.9)
        }
    }
    c.ridge(base: 1450, amps: [(12, 0.02, 0)], fill: rgb(0xd9c2a3))
}

struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed &* 0x9E3779B97F4A7C15 | 1 }
    mutating func next() -> UInt64 { state ^= state << 13; state ^= state >> 7; state ^= state << 17; return state }
}

func render(_ scene: (Canvas) -> Void, shot k: Int, brightness: Double = 1) -> CGImage {
    let ctx = makeContext()
    scene(Canvas(ctx: ctx, dx: Double(k) * 14 - 20, dy: Double(k) * 6, zoom: 1 + Double(k) * 0.015))
    var img = ctx.makeImage()!
    if brightness != 1 {
        let ci = CIImage(cgImage: img).applyingFilter("CIExposureAdjust", parameters: [kCIInputEVKey: log2(brightness)])
        img = CIContext().createCGImage(ci, from: ci.extent)!
    }
    return img
}

func blur(_ img: CGImage, _ sigma: Double) -> CGImage {
    let ci = CIImage(cgImage: img)
    return CIContext().createCGImage(ci.clampedToExtent().applyingGaussianBlur(sigma: sigma).cropped(to: ci.extent), from: ci.extent)!
}

func save(_ img: CGImage, name: String, date: Date) {
    let url = out.appendingPathComponent(name + ".jpg")
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil)!
    let ds = exifFormat.string(from: date)
    let props: [CFString: Any] = [kCGImagePropertyExifDictionary: [kCGImagePropertyExifDateTimeOriginal: ds, kCGImagePropertyExifDateTimeDigitized: ds],
                                  kCGImagePropertyTIFFDictionary: [kCGImagePropertyTIFFDateTime: ds],
                                  kCGImageDestinationLossyCompressionQuality: 0.9]
    CGImageDestinationAddImage(dest, img, props as CFDictionary)
    CGImageDestinationFinalize(dest)
}

let scenes: [(String, (Canvas) -> Void)] = [("beach", beach), ("lake", mountainLake), ("city", cityNight),
                                            ("forest", forest), ("desert", desert), ("blossom", blossom)]
var t = base
var n = 0
for (i, (name, scene)) in scenes.enumerated() {
    let shots = i % 2 == 0 ? 4 : 3
    for k in 0..<shots {
        var img = render(scene, shot: k)
        if k == 1 { img = blur(img, 10) }
        save(img, name: "\(name)_\(k)", date: t); n += 1
        t += 6
    }
    t += 3 * 3600
}
// A dark single and a sharp single on their own.
save(render(cityNight, shot: 3, brightness: 0.18), name: "single_dark", date: t); n += 1
t += 3 * 3600
save(render(forest, shot: 5), name: "single_forest", date: t); n += 1
print("wrote \(n) photos to \(out.path)")
