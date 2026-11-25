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

    /// Fetches only the requested records, in chunks so the query stays small.
    private func records(for ids: [String]) -> [DecisionRecord] {
        var out: [DecisionRecord] = []
        for chunk in ids.chunked(500) {
            let descriptor = FetchDescriptor<DecisionRecord>(predicate: #Predicate { chunk.contains($0.assetID) })
            out += (try? context.fetch(descriptor)) ?? []
        }
        return out
    }
}

extension Array {
    func chunked(_ size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}
