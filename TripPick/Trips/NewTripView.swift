import SwiftData
import SwiftUI
import TripPickCore

struct NewTripView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var onCreate: (TripRecord) -> Void
    var onCreateFolder: (FolderRecord) -> Void = { _ in }

    @State private var start = Calendar.current.date(byAdding: .day, value: -6, to: .now) ?? .now
    @State private var end = Date.now
    @State private var media: [MediaItem] = []
    @State private var loading = false
    @State private var name = ""
    @State private var nameEdited = false
    @State private var suggesting = false
    @State private var isSuggested = false
    @State private var segments: [CitySegment] = []
    @State private var folderName = ""

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
                    Text("Which dates should we organize?")
                }
                Section {
                    HStack {
                        TextField("Name", text: Binding(get: { name }, set: { name = $0; nameEdited = true; isSuggested = false }),
                                  prompt: Text(verbatim: TripName.dates(range)))
                        if suggesting { ProgressView() }
                    }
                } header: {
                    Text("Name")
                } footer: {
                    if isSuggested { Label("Suggested from where your photos were taken.", systemImage: "mappin.and.ellipse") }
                }
                if !segments.isEmpty {
                    Section {
                        TextField("Folder name", text: $folderName)
                            .font(.headline)
                        ForEach(segments, id: \.self) { seg in
                            LabeledContent {
                                Text(verbatim: TripName.dates(TripRange(start: seg.start, end: seg.end)))
                            } label: {
                                Label(seg.city, systemImage: "mappin.circle")
                            }
                        }
                        Button("Split by city", systemImage: "folder.badge.plus") { createSplit() }
                            .buttonStyle(.glassProminent)
                            .frame(maxWidth: .infinity)
                    } header: {
                        Text("Split by city?")
                    } footer: {
                        Text("Each city becomes its own cleanup inside one folder. The same folder is made in Photos.")
                    }
                }
                Section {
                    if loading {
                        ProgressView()
                    } else {
                        let photos = handled.filter { $0.kind != .video }.count
                        let videos = handled.count - photos
                        Text("\(photos) photos · \(videos) short videos")
                            .font(.headline)
                        if !handled.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 4)], spacing: 4) {
                            ForEach(handled.prefix(8)) { item in
                                Color.clear
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay { AssetImageView(id: item.id, maxPixel: 200) }
                                    .clipShape(.rect(cornerRadius: 6))
                            }
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
            .navigationTitle(Text("New cleanup"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
            }
            .safeAreaBar(edge: .bottom) {
                Button(segments.isEmpty ? "Start organizing" : "Organize as one") { create() }
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
        segments = []
        let fetched = await model.library.fetchMedia(in: interval)
        guard !Task.isCancelled else { return }
        media = fetched
        loading = false
        await suggestName()
        await suggestSplit()
    }

    private func suggestName() async {
        guard !nameEdited else { return }
        suggesting = true
        let suggestion = await TripNaming.suggestedName(for: handled)
        suggesting = false
        guard !Task.isCancelled, !nameEdited else { return }
        name = suggestion ?? ""
        isSuggested = suggestion != nil
    }

    private func suggestSplit() async {
        let locale = AppLanguage.current.locale
        let found = await TripSplitter.suggest(items: handled, namer: AppleMapsPlaceNamer(), locale: locale, range: range.interval)
        guard !Task.isCancelled else { return }
        segments = found
        guard !found.isEmpty else { return }
        let countries = Set(found.compactMap(\.country))
        let base: String
        if countries.count == 1, found.allSatisfy({ $0.country != nil }), let country = countries.first {
            base = L10n.string("\(country) Trip")
        } else {
            let places = TripTitle.join(found.map(\.city), languageCode: locale.language.languageCode?.identifier ?? "en")
            base = L10n.string("\(places) Trip")
        }
        // Dates keep a second trip to the same country from landing in last time's folder and albums.
        folderName = "\(base) · \(TripName.dates(range))"
    }

    private func createSplit() {
        let typed = folderName.trimmingCharacters(in: .whitespaces)
        let folder = FolderRecord(name: typed.isEmpty ? TripName.dates(range) : typed)
        context.insert(folder)
        for seg in segments {
            context.insert(TripRecord(name: seg.city, startDate: seg.start, endDate: seg.end, folderID: folder.id))
        }
        try? context.save()
        dismiss()
        onCreateFolder(folder)
    }

    private func create() {
        let typed = name.trimmingCharacters(in: .whitespaces)
        let trip = TripRecord(name: typed.isEmpty ? TripName.dates(range) : typed, startDate: start, endDate: end)
        context.insert(trip)
        try? context.save()
        dismiss()
        onCreate(trip)
    }
}
