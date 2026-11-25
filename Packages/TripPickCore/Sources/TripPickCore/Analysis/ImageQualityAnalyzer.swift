import CoreGraphics
import Foundation
import Vision

public protocol ImageAnalyzing: Sendable {
    func analyze(_ image: CGImage, id: String, kind: MediaKind) async -> AnalysisResult
}

public struct ImageQualityAnalyzer: ImageAnalyzing {
    public var thresholds: QualityThresholds

    public init(thresholds: QualityThresholds = .default) {
        self.thresholds = thresholds
    }

    public func analyze(_ image: CGImage, id: String, kind: MediaKind) async -> AnalysisResult {
        let gray = Self.grayscalePixels(image, maxPixel: thresholds.analysisMaxPixel)
        let sharpness = Self.laplacianVariance(gray)
        let featurePrint = await Self.featurePrint(image)
        guard kind == .photo else {
            return AnalysisResult(id: id, flags: [], sharpness: sharpness, aesthetics: 0, featurePrint: featurePrint, failed: false)
        }
        var flags: QualityFlags = []
        if sharpness < thresholds.blurryBelowSharpness { flags.insert(.blurry) }
        let lum = Self.luminanceStats(gray, clipped: thresholds.clippedLuminance)
        if lum.mean < thresholds.darkBelowMeanLuminance { flags.insert(.dark) }
        if lum.clippedFraction > thresholds.overexposedClippedFraction { flags.insert(.overexposed) }
        if await Self.hasClosedEyes(image, below: thresholds.eyesClosedBelowOpenness) { flags.insert(.eyesClosed) }
        let aesthetics = await Self.aesthetics(image)
        return AnalysisResult(id: id, flags: flags, sharpness: sharpness, aesthetics: aesthetics, featurePrint: featurePrint, failed: false)
    }

    // MARK: Pixel measures

    struct GrayPixels {
        var width: Int, height: Int, data: [UInt8]
    }

    static func grayscalePixels(_ image: CGImage, maxPixel: Int = 512, square: Bool = false) -> GrayPixels {
        let scale = min(1, Double(maxPixel) / Double(max(image.width, image.height)))
        let w = square ? maxPixel : max(1, Int(Double(image.width) * scale))
        let h = square ? maxPixel : max(1, Int(Double(image.height) * scale))
        var data = [UInt8](repeating: 0, count: w * h)
        data.withUnsafeMutableBytes { buf in
            let ctx = CGContext(data: buf.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w,
                                space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)!
            ctx.interpolationQuality = .medium
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        return GrayPixels(width: w, height: h, data: data)
    }

    /// Variance of the 3×3 Laplacian on a ≤512px grayscale copy (0–255 scale). Low means blurry.
    public static func laplacianVariance(_ image: CGImage) -> Double {
        laplacianVariance(grayscalePixels(image))
    }

    static func laplacianVariance(_ g: GrayPixels) -> Double {
        guard g.width > 2, g.height > 2 else { return 0 }
        var sum = 0.0, sumSq = 0.0, n = 0.0
        g.data.withUnsafeBufferPointer { p in
            for y in 1..<(g.height - 1) {
                let row = y * g.width
                for x in 1..<(g.width - 1) {
                    let i = row + x
                    let v = Double(p[i - 1]) + Double(p[i + 1]) + Double(p[i - g.width]) + Double(p[i + g.width]) - 4 * Double(p[i])
                    sum += v; sumSq += v * v; n += 1
                }
            }
        }
        let mean = sum / n
        return sumSq / n - mean * mean
    }

    /// Mean luminance (0–1) and the fraction of pixels at or above `clipped`.
    public static func luminanceStats(_ image: CGImage, clipped: Double = QualityThresholds.default.clippedLuminance) -> (mean: Double, clippedFraction: Double) {
        luminanceStats(grayscalePixels(image), clipped: clipped)
    }

    static func luminanceStats(_ g: GrayPixels, clipped: Double) -> (mean: Double, clippedFraction: Double) {
        let limit = UInt8(min(255, clipped * 255))
        var total = 0, high = 0
        for v in g.data { total += Int(v); if v >= limit { high += 1 } }
        let n = Double(max(1, g.data.count))
        return (Double(total) / n / 255, Double(high) / n)
    }

    /// Height / width of the eye outline's bounding box. Low means closed.
    public static func eyeOpenness(points: [CGPoint]) -> Double {
        guard let minX = points.map(\.x).min(), let maxX = points.map(\.x).max(),
              let minY = points.map(\.y).min(), let maxY = points.map(\.y).max(), maxX > minX else { return 1 }
        return Double((maxY - minY) / (maxX - minX))
    }

    // MARK: Vision

    static func featurePrint(_ image: CGImage) async -> Data {
        if let obs = try? await GenerateImageFeaturePrintRequest().perform(on: image), let data = FeaturePrint.encode(obs) {
            return data
        }
        return FeaturePrint.thumbnailPrint(image)
    }

    static func aesthetics(_ image: CGImage) async -> Double {
        guard let obs = try? await CalculateImageAestheticsScoresRequest().perform(on: image) else { return 0 }
        return Double(obs.overallScore)
    }

    static func hasClosedEyes(_ image: CGImage, below limit: Double) async -> Bool {
        guard let faces = try? await DetectFaceLandmarksRequest().perform(on: image) else { return false }
        for face in faces {
            guard let landmarks = face.landmarks else { continue }
            for eye in [landmarks.leftEye, landmarks.rightEye] {
                let pts = eye.points.map { CGPoint(x: $0.x, y: $0.y) }
                if pts.count >= 3, eyeOpenness(points: pts) < limit { return true }
            }
        }
        return false
    }
}
