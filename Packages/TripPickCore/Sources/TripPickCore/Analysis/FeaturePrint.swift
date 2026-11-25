import CoreGraphics
import Foundation
import Vision

/// Stored visual fingerprints. Vision's feature print is preferred; when Vision cannot run
/// (for example in the iOS Simulator), a 16×16 grayscale thumbnail stands in.
public enum FeaturePrint {
    private static let thumbnailMagic = Data("TPT1".utf8)
    private static let thumbnailSide = 16
    /// Scales thumbnail RMS difference (0–1) onto Vision's distance range so one threshold fits both.
    private static let thumbnailScale: Float = 4

    static func encode(_ observation: FeaturePrintObservation) -> Data? {
        try? PropertyListEncoder().encode(observation)
    }

    public static func thumbnailPrint(_ image: CGImage) -> Data {
        let g = ImageQualityAnalyzer.grayscalePixels(image, maxPixel: thumbnailSide, square: true)
        return thumbnailMagic + Data(g.data)
    }

    /// Visual distance between two stored prints of the same kind; nil when either cannot be read or the kinds differ.
    public static func distance(_ a: Data, _ b: Data) -> Float? {
        let ta = a.starts(with: thumbnailMagic), tb = b.starts(with: thumbnailMagic)
        if ta || tb {
            guard ta, tb, a.count == b.count else { return nil }
            var sum: Float = 0
            for (x, y) in zip(a.dropFirst(thumbnailMagic.count), b.dropFirst(thumbnailMagic.count)) {
                let d = (Float(x) - Float(y)) / 255
                sum += d * d
            }
            return (sum / Float(a.count - thumbnailMagic.count)).squareRoot() * thumbnailScale
        }
        let decoder = PropertyListDecoder()
        guard let fa = try? decoder.decode(FeaturePrintObservation.self, from: a),
              let fb = try? decoder.decode(FeaturePrintObservation.self, from: b),
              let d = try? fa.distance(to: fb) else { return nil }
        return Float(d)
    }
}
