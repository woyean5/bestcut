import SwiftData
import SwiftUI
import TripPickCore

/// Loads a trip's media, analyzes it (reusing the cache), then shows the trip home.
struct TripFlowView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var context
    let trip: TripRecord
    @State private var session: TripSession?
    @State private var progress = AnalysisProgress(done: 0, total: 0)

    var body: some View {
        Group {
            if let session {
                TripHomeView(session: session, trip: trip)
            } else {
                AnalysisProgressView(progress: progress)
            }
        }
        .task { await start() }
    }

    private func start() async {
        guard session == nil, let interval = trip.range.interval else { return }
        let settings = SessionSettings.current
        let items = await model.library.fetchMedia(in: interval)
        let coordinator = AnalysisCoordinator(library: model.library, analyzer: ImageQualityAnalyzer(), cache: AnalysisCache(context: context))
        let analyses = await coordinator.analyze(items) { progress = $0 }
        guard !Task.isCancelled else { return }
        let prints = analyses.compactMapValues(\.featurePrint)
        session = TripSession(items: items, analyses: analyses, store: SwiftDataDecisionStore(context: context), library: model.library,
                              settings: settings, distance: { a, b in
                                  guard let pa = prints[a], let pb = prints[b] else { return nil }
                                  return FeaturePrint.distance(pa, pb)
                              })
    }
}

struct AnalysisProgressView: View {
    let progress: AnalysisProgress

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.tint)
                .symbolEffect(.pulse)
            Text("Looking through your photos")
                .font(.title2.bold())
            ProgressView(value: Double(progress.done), total: Double(max(progress.total, 1)))
                .padding(.horizontal, 48)
            Text("\(progress.done) of \(progress.total)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Spacer()
            Text("Everything happens on this iPhone.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
