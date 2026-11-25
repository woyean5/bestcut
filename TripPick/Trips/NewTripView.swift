import SwiftData
import SwiftUI
import TripPickCore

struct NewTripView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var onCreate: (TripRecord) -> Void

    @State private var start = Calendar.current.date(byAdding: .day, value: -6, to: .now) ?? .now
    @State private var end = Date.now
    @State private var media: [MediaItem] = []
    @State private var loading = false

    private var range: TripRange { TripRange(start: start, end: end) }
    private var handled: [MediaItem] {
        let limit = Double(SessionSettings.current.shortVideoMaxSeconds)
        return media.filter { $0.kind != .video || $0.duration <= limit }
    }
    private var issue: TripRangeIssue? { loading ? nil : TripRange.validate(range, mediaCount: handled.count) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Start", selection: $start, displayedComponents: .date)
                    DatePicker("End", selection: $end, displayedComponents: .date)
                } header: {
                    Text("Which trip should we organize?")
                }
                Section {
                    if loading {
                        ProgressView()
                    } else {
                        let photos = handled.filter { $0.kind != .video }.count
                        let videos = handled.count - photos
                        Text("\(photos) photos · \(videos) short videos")
                            .font(.headline)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 4), spacing: 4) {
                            ForEach(handled.prefix(8)) { item in
                                AssetImageView(id: item.id, maxPixel: 200)
                                    .aspectRatio(1, contentMode: .fit)
                                    .clipShape(.rect(cornerRadius: 6))
                            }
                        }
                    }
                    if let issue {
                        Label(issue == .endBeforeStart ? "The end date is before the start date." : "There are no photos on these dates.",
                              systemImage: "exclamationmark.circle")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("New trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Start organizing") { create() }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .disabled(loading || issue != nil)
                    .padding(.bottom, 8)
            }
            .task(id: range) { await load() }
        }
    }

    private func load() async {
        guard let interval = range.interval else { media = []; return }
        loading = true
        media = await model.library.fetchMedia(in: interval)
        loading = false
    }

    private func create() {
        let trip = TripRecord(name: TripName.dates(range), startDate: start, endDate: end)
        context.insert(trip)
        try? context.save()
        dismiss()
        onCreate(trip)
    }
}
