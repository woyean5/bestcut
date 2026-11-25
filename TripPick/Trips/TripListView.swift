import Photos
import PhotosUI
import SwiftData
import SwiftUI
import TripPickCore

struct TripListView: View {
    @Environment(AppModel.self) private var model
    @Query(sort: \TripRecord.createdAt, order: .reverse) private var trips: [TripRecord]
    @State private var path = NavigationPath()
    @State private var showNewTrip = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if model.permission == .limited {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("You've shared only some photos", systemImage: "photo.badge.exclamationmark")
                                .font(.subheadline.weight(.semibold))
                            Button("Select more photos") { presentLimitedPicker() }
                                .font(.subheadline)
                        }
                    }
                }
                if !trips.isEmpty {
                    Section("Your cleanups") {
                        ForEach(trips) { trip in
                            NavigationLink(value: trip.id) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(trip.name).font(.headline)
                                    if trip.name != TripName.dates(trip.range) {
                                        Text(TripName.dates(trip.range)).font(.subheadline).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteTrips)
                    }
                }
            }
            .overlay {
                if trips.isEmpty {
                    ContentUnavailableView {
                        Label("Start your first cleanup", systemImage: "airplane.departure")
                    } description: {
                        Text("Pick a date range, like a trip, a weekend, or last month. BestCut groups similar shots and flags blurry ones so you only have to pick.")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Start a new cleanup", systemImage: "plus") { showNewTrip = true }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .padding(.bottom, 8)
            }
            .navigationTitle(Text(verbatim: "BestCut"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") { showSettings = true }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let trip = trips.first(where: { $0.id == id }) { TripFlowView(trip: trip) }
            }
            .sheet(isPresented: $showNewTrip) {
                NewTripView { trip in path.append(trip.id) }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }

    @Environment(\.modelContext) private var context

    private func deleteTrips(at offsets: IndexSet) {
        for i in offsets { context.delete(trips[i]) }
        try? context.save()
    }

    private func presentLimitedPicker() {
        guard let root = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first?.rootViewController else { return }
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: root)
    }
}

enum TripName {
    /// "Nov 10 – 15" style, in the user's language.
    static func dates(_ range: TripRange) -> String {
        let start = range.start.formatted(.dateTime.month(.abbreviated).day())
        if Calendar.current.isDate(range.start, inSameDayAs: range.end) { return start }
        return "\(start) – \(range.end.formatted(.dateTime.month(.abbreviated).day()))"
    }
}
