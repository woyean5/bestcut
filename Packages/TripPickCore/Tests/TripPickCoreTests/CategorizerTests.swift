import Testing
@testable import TripPickCore

func result(_ id: String, _ flags: QualityFlags = []) -> AnalysisResult {
    AnalysisResult(id: id, flags: flags, sharpness: 1, aesthetics: 0, featurePrint: nil, failed: false)
}

@Test func bucketsSplitByKind() {
    let items = [item("g1"), item("g2", at: 5), item("blur", at: 500), item("ok", at: 900),
                 item("s1", .screenshot), item("s2", .screenshot, at: 30), item("s3", .screenshot, at: 5000),
                 item("v1", .video, duration: 1.5), item("v2", .video, duration: 30)]
    let b = Categorizer.buckets(items: items, analyses: ["blur": result("blur", .blurry)],
                                groups: [["g1", "g2"], ["s1", "s2"]], shortVideoMaxSeconds: 2)
    #expect(b.similar.map(\.itemIDs) == [["g1", "g2"]])
    #expect(b.screenshots.map(\.itemIDs) == [["s1", "s2"]])
    #expect(b.flagged.map(\.itemIDs) == [["blur"]])
    #expect(b.shortVideos.map(\.itemIDs) == [["v1"]])
    #expect(Set(b.singles) == ["ok", "s3"])
    #expect(!b.allItemIDs.contains("v2"))
    #expect(b.allItemIDs.count == 8)
}
@Test func flaggedAreChunkedByNine() {
    let items = (0..<20).map { item("f\($0)", at: Double($0) * 1000) }
    let analyses = Dictionary(uniqueKeysWithValues: items.map { ($0.id, result($0.id, .dark)) })
    let b = Categorizer.buckets(items: items, analyses: analyses, groups: [], shortVideoMaxSeconds: 2)
    #expect(b.flagged.map(\.itemIDs.count) == [9, 9, 2])
    #expect(b.flagged[0].itemIDs.first == "f0")
}
@Test func reviewSetIDsAreStable() {
    let b = Categorizer.buckets(items: [item("g1"), item("g2", at: 5)], analyses: [:], groups: [["g1", "g2"]], shortVideoMaxSeconds: 2)
    #expect(b.similar[0].id == "similar-g1")
}
