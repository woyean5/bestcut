import Foundation

public struct AnalysisResult: Hashable, Sendable {
    public var id: String
    public var flags: QualityFlags
    public var sharpness: Double
    /// Vision aesthetics overall score, -1...1.
    public var aesthetics: Double
    /// Archived `VNFeaturePrintObservation`.
    public var featurePrint: Data?
    /// The image could not be loaded; no flags are set.
    public var failed: Bool

    public init(id: String, flags: QualityFlags, sharpness: Double, aesthetics: Double, featurePrint: Data?, failed: Bool) {
        self.id = id
        self.flags = flags
        self.sharpness = sharpness
        self.aesthetics = aesthetics
        self.featurePrint = featurePrint
        self.failed = failed
    }
}
