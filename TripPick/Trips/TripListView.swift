import Photos
import PhotosUI
import SwiftData
import SwiftUI
import TripPickCore

struct TripListView: View {
    @Environment(AppModel.self) private var model
    @Query(sort: \TripRecord.createdAt, order: .reverse) private var trips: [TripRecord]
    @Query(sort: \FolderRecord.createdAt, order: .reverse) private var folders: [FolderRecord]
    private var looseTrips: [TripRecord] { trips.filter { $0.folderID == nil } }
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
                if !folders.isEmpty {
                    Section("Folders") {
                        ForEach(folders) { folder in
                            NavigationLink(value: FolderLink(id: folder.id)) {
                                Label {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(folder.name).font(.headline)
                                        Text("\(trips.filter { $0.folderID == folder.id }.count) places")
                                            .font(.subheadline).foregroundStyle(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: "folder.fill").foregroundStyle(.tint)
                                }
                            }
                        }
                        .onDelete(perform: deleteFolders)
                    }
                }
                if !looseTrips.isEmpty {
                    Section("Your cleanups") {
                        ForEach(looseTrips) { trip in
                            NavigationLink(value: trip.id) { TripRow(trip: trip) }
                        }
                        .onDelete(perform: deleteTrips)
                    }
                }
            }
            .overlay {
                if trips.isEmpty && folders.isEmpty {
                    ContentUnavailableView {
                        Label("Start your first cleanup", systemImage: "airplane.departure")
                    } description: {
                        Text("Pick a date range, like a trip, a weekend, or last month. BestCut groups similar shots and flags blurry ones so you only have to pick.")
                    }
                }
            }
            .safeAreaBar(edge: .bottom) {
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
            .navigationDestination(for: FolderLink.self) { link in
                if let folder = folders.first(where: { $0.id == link.id }) {
                    FolderView(folder: folder, trips: trips.filter { $0.folderID == folder.id })
                }
            }
            .sheet(isPresented: $showNewTrip) {
                NewTripView(onCreate: { trip in path.append(trip.id) },
                            onCreateFolder: { folder in path.append(FolderLink(id: folder.id)) })
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }

    @Environment(\.modelContext) private var context

    private func deleteTrips(at offsets: IndexSet) {
        for i in offsets { context.delete(looseTrips[i]) }
        try? context.save()
    }

    /// Removes the folder and its cleanups from the app. Photos and albums stay as they are.
    private func deleteFolders(at offsets: IndexSet) {
        for i in offsets {
            let folder = folders[i]
            for trip in trips where trip.folderID == folder.id { context.delete(trip) }
            context.delete(folder)
        }
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
        let style = Date.FormatStyle.dateTime.month(.abbreviated).day().locale(AppLanguage.current.locale)
        let start = range.start.formatted(style)
        if Calendar.current.isDate(range.start, inSameDayAs: range.end) { return start }
        return "\(start) – \(range.end.formatted(style))"
    }
}

struct FolderLink: Hashable { var id: UUID }

/// A cleanup's name with its dates underneath when the name isn't the dates.
struct TripRow: View {
    let trip: TripRecord
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(trip.name).font(.headline)
            if trip.name != TripName.dates(trip.range) {
                Text(TripName.dates(trip.range)).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

/// The city cleanups inside one folder, in date order.
struct FolderView: View {
    @Environment(\.modelContext) private var context
    let folder: FolderRecord
    let trips: [TripRecord]
    @State private var renaming = false
    @State private var newName = ""

    var body: some View {
        List {
            ForEach(trips.sorted { $0.startDate < $1.startDate }) { trip in
                NavigationLink(value: trip.id) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(trip.name).font(.headline)
                        Text(TripName.dates(trip.range)).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Rename", systemImage: "pencil") { newName = folder.name; renaming = true }
            }
        }
        .alert("Rename", isPresented: $renaming) {
            TextField("Name", text: $newName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                let name = newName.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { folder.name = name; try? context.save() }
            }
        }
    }
}
