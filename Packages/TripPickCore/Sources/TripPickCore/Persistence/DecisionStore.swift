import Foundation
import SwiftData

@MainActor public protocol DecisionStore: AnyObject {
    func decisions(for ids: [String]) -> [String: Decision]
    /// Saving `.untouched` removes the stored decision.
    func set(_ decision: Decision, for ids: [String])
}

@MainActor public final class SwiftDataDecisionStore: DecisionStore {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func decisions(for ids: [String]) -> [String: Decision] {
        var out: [String: Decision] = [:]
        for r in records(for: ids) {
            if let d = Decision(rawValue: r.decisionRaw) { out[r.assetID] = d }
        }
        return out
    }

    public func set(_ decision: Decision, for ids: [String]) {
        let existing = Dictionary(records(for: ids).map { ($0.assetID, $0) }, uniquingKeysWith: { a, _ in a })
        for id in ids {
            if decision == .untouched {
                if let r = existing[id] { context.delete(r) }
            } else if let r = existing[id] {
                r.decisionRaw = decision.rawValue
                r.updatedAt = .now
            } else {
                context.insert(DecisionRecord(assetID: id, decisionRaw: decision.rawValue))
            }
        }
        try? context.save()
    }

    private func records(for ids: [String]) -> [DecisionRecord] {
        let wanted = Set(ids)
        let all = (try? context.fetch(FetchDescriptor<DecisionRecord>())) ?? []
        return all.filter { wanted.contains($0.assetID) }
    }
}
