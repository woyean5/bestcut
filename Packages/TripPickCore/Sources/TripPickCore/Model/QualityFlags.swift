public struct QualityFlags: OptionSet, Codable, Hashable, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let blurry = QualityFlags(rawValue: 1 << 0)
    public static let dark = QualityFlags(rawValue: 1 << 1)
    public static let overexposed = QualityFlags(rawValue: 1 << 2)
    public static let eyesClosed = QualityFlags(rawValue: 1 << 3)
}
