// Generates JPEG test photos with EXIF dates for the simulator: swift scripts/make_test_photos.swift <outdir>
// Scenes are shot 3-4 times a few seconds apart (similar groups), plus blurry, dark and single shots.
import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

let out = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
let W = 1200, H = 1600
var rng = SystemRandomNumberGenerator()
let base = ISO8601DateFormatter().date(from: "2026-11-10T09:00:00Z")!
let exifFormat: DateFormatter = { let f = DateFormatter(); f.dateFormat = "yyyy:MM:dd HH:mm:ss"; f.timeZone = TimeZone(identifier: "UTC"); return f }()

struct Shape { var x, y, r: Double; var color: (Double, Double, Double) }

func scene(seed: Int) -> [Shape] {
    var g = SeededRNG(seed: UInt64(seed + 1))
    return (0..<14).map { _ in
        Shape(x: .random(in: 0...1, using: &g), y: .random(in: 0...1, using: &g), r: .random(in: 0.05...0.22, using: &g),
              color: (.random(in: 0...1, using: &g), .random(in: 0...1, using: &g), .random(in: 0...1, using: &g)))
    }
}

struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed &* 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 { state ^= state << 13; state ^= state >> 7; state ^= state << 17; return state }
}

func render(_ shapes: [Shape], seed: Int, dx: Double, dy: Double, brightness: Double) -> CGImage {
    let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    var g = SeededRNG(seed: UInt64(seed + 99))
    let sky = (Double.random(in: 0.3...0.9, using: &g), Double.random(in: 0.4...0.9, using: &g), Double.random(in: 0.5...1, using: &g))
    ctx.setFillColor(red: sky.0 * brightness, green: sky.1 * brightness, blue: sky.2 * brightness, alpha: 1)
    ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
    for s in shapes {
        ctx.setFillColor(red: s.color.0 * brightness, green: s.color.1 * brightness, blue: s.color.2 * brightness, alpha: 1)
        let r = s.r * Double(W)
        ctx.fillEllipse(in: CGRect(x: s.x * Double(W) + dx - r, y: s.y * Double(H) + dy - r, width: r * 2, height: r * 2))
        ctx.setStrokeColor(gray: 0.1 * brightness, alpha: 1)
        ctx.setLineWidth(6)
        ctx.stroke(CGRect(x: s.x * Double(W) + dx - r / 2, y: s.y * Double(H) + dy - r / 2, width: r, height: r))
    }
    // Fine texture so sharp photos have detail.
    for i in stride(from: 0, to: W, by: 24) {
        ctx.setStrokeColor(gray: 0.2 * brightness, alpha: 0.5)
        ctx.setLineWidth(2)
        ctx.move(to: CGPoint(x: Double(i) + dx, y: 0)); ctx.addLine(to: CGPoint(x: Double(i) + dx, y: Double(H) * 0.15)); ctx.strokePath()
    }
    return ctx.makeImage()!
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
                                  kCGImagePropertyTIFFDictionary: [kCGImagePropertyTIFFDateTime: ds]]
    CGImageDestinationAddImage(dest, img, props as CFDictionary)
    CGImageDestinationFinalize(dest)
}

var t = base
var n = 0
for s in 0..<8 {
    let shapes = scene(seed: s)
    let shots = s % 3 == 0 ? 4 : 3
    for k in 0..<shots {
        var img = render(shapes, seed: s, dx: Double(k) * 6, dy: Double(k) * 4, brightness: 1)
        if k == 1 && s % 2 == 0 { img = blur(img, 9) }
        save(img, name: String(format: "scene%02d_%d", s, k), date: t); n += 1
        t += 8
    }
    t += 1800
    // a single, unrelated shot between scenes
    save(render(scene(seed: 100 + s), seed: 100 + s, dx: 0, dy: 0, brightness: s % 4 == 1 ? 0.12 : 1), name: String(format: "single%02d", s), date: t); n += 1
    t += 1800
}
// a blurry single
save(blur(render(scene(seed: 200), seed: 200, dx: 0, dy: 0, brightness: 1), 12), name: "single_blurry", date: t); n += 1
print("wrote \(n) photos to \(out.path)")
