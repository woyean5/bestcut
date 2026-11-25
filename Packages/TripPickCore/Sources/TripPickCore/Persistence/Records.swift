import Foundation
import SwiftData

@Model public final class TripRecord {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var startDate: Date
    public var endDate: Date
    public var createdAt: Date

    public init(id: UUID = UUID(), name: String, startDate: Date, endDate: Date, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = createdAt
    }

    public var range: TripRange { TripRange(start: startDate, end: endDate) }
}

@Model final class DecisionRecord {
    @Attribute(.unique) var assetID: String
    var decisionRaw: String
    var updatedAt: Date

    init(assetID: String, decisionRaw: String, updatedAt: Date = .now) {
        self.assetID = assetID
        self.decisionRaw = decisionRaw
        self.updatedAt = updatedAt
    }
}

@Model final class AnalysisRecord {
    @Attribute(.unique) var assetID: String
    var flagsRaw: Int
    var sharpness: Double
    var aesthetics: Double
    var featurePrint: Data?
    var failed: Bool
    var analyzerVersion: Int

    init(assetID: String, flagsRaw: Int, sharpness: Double, aesthetics: Double, featurePrint: Data?, failed: Bool, analyzerVersion: Int) {
        self.assetID = assetID
        self.flagsRaw = flagsRaw
        self.sharpness = sharpness
        self.aesthetics = aesthetics
        self.featurePrint = featurePrint
        self.failed = failed
        self.analyzerVersion = analyzerVersion
    }
}

public enum TripPickSchema {
    public static var models: [any PersistentModel.Type] { [TripRecord.self, DecisionRecord.self, AnalysisRecord.self] }

    public static func container(inMemory: Bool) throws -> ModelContainer {
        try ModelContainer(for: Schema(models), configurations: ModelConfiguration(isStoredInMemoryOnly: inMemory))
    }
}
