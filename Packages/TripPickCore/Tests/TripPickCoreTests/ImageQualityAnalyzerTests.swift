import CoreGraphics
import Testing
@testable import TripPickCore

@Test func sharpImageHasHighVarianceBlurredLow() {
    let sharp = TestImages.checkerboard(cell: 8)
    #expect(ImageQualityAnalyzer.laplacianVariance(sharp) > QualityThresholds.default.blurryBelowSharpness)
    #expect(ImageQualityAnalyzer.laplacianVariance(TestImages.blurred(sharp, radius: 8)) < QualityThresholds.default.blurryBelowSharpness)
}
@Test func luminance() {
    #expect(ImageQualityAnalyzer.luminanceStats(TestImages.solid(gray: 0.05)).mean < 0.18)
    #expect(ImageQualityAnalyzer.luminanceStats(TestImages.solid(gray: 1.0)).clippedFraction > 0.9)
    #expect(ImageQualityAnalyzer.luminanceStats(TestImages.solid(gray: 0.5)).clippedFraction < 0.01)
}
@Test func eyeOpennessRatio() {
    #expect(ImageQualityAnalyzer.eyeOpenness(points: [.init(x: 0, y: 0), .init(x: 10, y: 0), .init(x: 5, y: 0.5)]) < 0.12)
    #expect(ImageQualityAnalyzer.eyeOpenness(points: [.init(x: 0, y: 0), .init(x: 10, y: 0), .init(x: 5, y: 4)]) > 0.12)
}
@Test func analyzeFlagsDarkBlurryPhoto() async {
    let img = TestImages.blurred(TestImages.solid(gray: 0.05), radius: 8)
    let r = await ImageQualityAnalyzer().analyze(img, id: "a", kind: .photo)
    #expect(r.flags.contains(.dark))
    #expect(r.flags.contains(.blurry))
    #expect(!r.failed)
}
@Test func sharpBrightPhotoHasNoFlags() async {
    let r = await ImageQualityAnalyzer().analyze(TestImages.checkerboard(cell: 8, light: 0.8, dark: 0.2), id: "a", kind: .photo)
    #expect(r.flags.rawValue == 0, "flags: \(r.flags.rawValue)")
}
@Test func screenshotsGetNoFlagsButFeaturePrint() async {
    let r = await ImageQualityAnalyzer().analyze(TestImages.solid(gray: 0.02), id: "s", kind: .screenshot)
    #expect(r.flags.isEmpty)
    #expect(r.featurePrint != nil)
}
@Test func featurePrintDistanceIdenticalIsZero() async {
    let r = await ImageQualityAnalyzer().analyze(TestImages.checkerboard(cell: 8), id: "a", kind: .photo)
    #expect(FeaturePrint.distance(r.featurePrint!, r.featurePrint!)! < 0.001)
}
@Test func featurePrintDistanceDifferentIsLarger() async {
    let a = await ImageQualityAnalyzer().analyze(TestImages.checkerboard(cell: 8), id: "a", kind: .photo)
    let b = await ImageQualityAnalyzer().analyze(TestImages.solid(gray: 0.5), id: "b", kind: .photo)
    #expect(FeaturePrint.distance(a.featurePrint!, b.featurePrint!)! > 0.1)
}

@Test func thumbnailPrintSeparatesSimilarFromDifferent() {
    let a = FeaturePrint.thumbnailPrint(TestImages.solid(gray: 0.5))
    let b = FeaturePrint.thumbnailPrint(TestImages.solid(gray: 0.53))
    let c = FeaturePrint.thumbnailPrint(TestImages.checkerboard(cell: 64))
    #expect(FeaturePrint.distance(a, a)! < 0.001)
    #expect(FeaturePrint.distance(a, b)! < GroupingThresholds.default.photoMaxFeatureDistance)
    #expect(FeaturePrint.distance(a, c)! > GroupingThresholds.default.photoMaxFeatureDistance)
}
@Test func mixedPrintKindsHaveNoDistance() async {
    let vision = await ImageQualityAnalyzer().analyze(TestImages.checkerboard(cell: 8), id: "a", kind: .photo).featurePrint!
    #expect(FeaturePrint.distance(vision, FeaturePrint.thumbnailPrint(TestImages.solid(gray: 0.5))) == nil)
}
