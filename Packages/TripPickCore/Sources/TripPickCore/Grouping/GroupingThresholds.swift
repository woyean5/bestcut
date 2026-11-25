import Foundation

/// Tunable values for deciding which neighbouring shots belong together.
public struct GroupingThresholds: Sendable {
    public var photoMaxGap: TimeInterval = 90
    public var photoMaxFeatureDistance: Float = 0.5
    public var photoMaxMeters: Double = 100
    public var screenshotMaxGap: TimeInterval = 900
    public var screenshotMaxFeatureDistance: Float = 0.6

    public init() {}
    public static let `default` = GroupingThresholds()
}
