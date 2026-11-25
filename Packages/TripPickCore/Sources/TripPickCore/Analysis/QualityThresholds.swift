/// Tunable values for photo quality flags. Tune against real photos, keep the tests green.
public struct QualityThresholds: Sendable {
    public var analysisMaxPixel = 512
    public var blurryBelowSharpness: Double = 60
    public var darkBelowMeanLuminance: Double = 0.18
    public var overexposedClippedFraction: Double = 0.35
    public var clippedLuminance: Double = 0.98
    public var eyesClosedBelowOpenness: Double = 0.12

    public init() {}
    public static let `default` = QualityThresholds()
}
