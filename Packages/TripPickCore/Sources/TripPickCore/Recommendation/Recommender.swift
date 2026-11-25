public enum Recommender {
    /// The best shot of a similar-photo or screenshot set; nil for other sets or when nothing was analyzed.
    public static func recommendation(for set: ReviewSet, analyses: [String: AnalysisResult]) -> String? {
        guard set.kind == .similar || set.kind == .screenshots else { return nil }
        var best: (id: String, score: Double)?
        for id in set.itemIDs {
            guard let a = analyses[id], !a.failed else { continue }
            let s = set.kind == .screenshots ? a.sharpness : photoScore(a)
            if best == nil || s > best!.score { best = (id, s) }
        }
        return best?.id
    }

    static func photoScore(_ a: AnalysisResult) -> Double {
        var s = 0.5 * (a.aesthetics + 1) / 2 + 0.5 * min(a.sharpness / 500, 1)
        if a.flags.contains(.blurry) { s -= 0.3 }
        if a.flags.contains(.eyesClosed) { s -= 0.3 }
        if a.flags.contains(.dark) { s -= 0.15 }
        if a.flags.contains(.overexposed) { s -= 0.15 }
        return s
    }
}
