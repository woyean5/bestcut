import Testing
@testable import TripPickCore

@MainActor @Test func usesCacheAndSkipsVideos() async throws {
    let container = try TripPickSchema.container(inMemory: true)
    let lib = FakePhotoLibrary(), analyzer = RecordingAnalyzer(), cache = AnalysisCache(context: container.mainContext)
    cache.save([AnalysisResult(id: "cached", flags: [], sharpness: 1, aesthetics: 0, featurePrint: nil, failed: false)])
    lib.images = ["new": TestImages.solid(gray: 0.5)]
    var last = AnalysisProgress(done: 0, total: 0)
    let out = await AnalysisCoordinator(library: lib, analyzer: analyzer, cache: cache)
        .analyze([item("cached"), item("new"), item("v", .video, duration: 1)]) { last = $0 }
    #expect(analyzer.calls == ["new"])
    #expect(Set(out.keys) == ["cached", "new"])
    #expect(last.done == 2 && last.total == 2)
    #expect(cache.results(for: ["new"])["new"] != nil)
}
@MainActor @Test func test_thumbnailFailure_marksFailedWithoutFlags() async throws {
    let container = try TripPickSchema.container(inMemory: true)
    let out = await AnalysisCoordinator(library: FakePhotoLibrary(), analyzer: RecordingAnalyzer(), cache: AnalysisCache(context: container.mainContext))
        .analyze([item("icloudOnly")]) { _ in }
    #expect(out["icloudOnly"]?.failed == true)
    #expect(out["icloudOnly"]?.flags.isEmpty == true)
}
@MainActor @Test func analyzesManyItems() async throws {
    let container = try TripPickSchema.container(inMemory: true)
    let lib = FakePhotoLibrary()
    let items = (0..<120).map { item("p\($0)", at: Double($0)) }
    for i in items { lib.images[i.id] = TestImages.solid(gray: 0.5) }
    let out = await AnalysisCoordinator(library: lib, analyzer: RecordingAnalyzer(), cache: AnalysisCache(context: container.mainContext))
        .analyze(items) { _ in }
    #expect(out.count == 120)
}
