import Foundation
import Vision

public enum FeaturePrint {
    static func encode(_ observation: FeaturePrintObservation) -> Data? {
        try? PropertyListEncoder().encode(observation)
    }

    /// Visual distance between two stored feature prints; nil when either cannot be read.
    public static func distance(_ a: Data, _ b: Data) -> Float? {
        let decoder = PropertyListDecoder()
        guard let fa = try? decoder.decode(FeaturePrintObservation.self, from: a),
              let fb = try? decoder.decode(FeaturePrintObservation.self, from: b),
              let d = try? fa.distance(to: fb) else { return nil }
        return Float(d)
    }
}
