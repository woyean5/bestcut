import SwiftData
import SwiftUI
import TripPickCore

enum HomeRoute: Hashable {
    case review(ReviewQueue)
    case swipe(singlesOnly: Bool)
    case summary
}

struct TripHomeView: View {
    @Environment(\.modelContext) private var context
    let session: TripSession
    let trip: TripRecord
    @State private var renaming = false
    @State private var newName = ""

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(Int((session.progress * 100).rounded()))% organized")
                        .font(.headline)
                    ProgressView(value: session.progress)
                }
                .padding(.vertical, 4)
            }
            Section {
                row(.similar, title: "Similar photos", icon: "square.stack.3d.up")
                row(.screenshots, title: "Similar screenshots", icon: "rectangle.on.rectangle")
                row(.flagged, title: "Blurry or dark", icon: "camera.metering.unknown")
                row(.shortVideos, title: "Short videos", icon: "video")
                NavigationLink(value: HomeRoute.swipe(singlesOnly: true)) {
                    rowLabel("Single photos", icon: "photo", detail: Text("\(session.buckets.singles.count) photos"),
                             done: session.swipeQueue(singlesOnly: true).isEmpty && !session.buckets.singles.isEmpty)
                }
            }
        }
        .navigationTitle(trip.name)
        .safeAreaInset(edge: .bottom) {
            GlassEffectContainer {
                HStack(spacing: 12) {
                    NavigationLink(value: HomeRoute.swipe(singlesOnly: false)) {
                        Label("Swipe", systemImage: "hand.draw")
                    }
                    .buttonStyle(.glass)
                    NavigationLink(value: session.nextReviewSet() != nil ? HomeRoute.review(.continueAll) : HomeRoute.swipe(singlesOnly: false)) {
                        Text("Continue organizing").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                }
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("More", systemImage: "ellipsis") {
                    Button("Rename trip", systemImage: "pencil") { newName = trip.name; renaming = true }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: HomeRoute.summary) { Text("Results") }
            }
        }
        .alert("Rename trip", isPresented: $renaming) {
            TextField("Trip name", text: $newName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                let name = newName.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { trip.name = name; try? context.save() }
            }
        }
        .navigationDestination(for: HomeRoute.self) { route in
            switch route {
            case .review(let queue): ReviewSetView(session: session, queue: queue)
            case .swipe(let singlesOnly): SwipeReviewView(session: session, singlesOnly: singlesOnly)
            case .summary: SummaryView(session: session, tripName: trip.name)
            }
        }
    }

    @ViewBuilder private func row(_ kind: ReviewKind, title: LocalizedStringKey, icon: String) -> some View {
        let sets = session.buckets.sets(of: kind)
        let items = sets.reduce(0) { $0 + $1.itemIDs.count }
        let detail: Text = switch kind {
        case .similar, .screenshots: Text("\(sets.count) groups")
        case .flagged: Text("\(items) photos")
        case .shortVideos: Text("\(items) videos")
        }
        NavigationLink(value: HomeRoute.review(.kind(kind))) {
            rowLabel(title, icon: icon, detail: detail, done: !sets.isEmpty && sets.allSatisfy(session.isDone))
        }
        .disabled(sets.isEmpty)
    }

    private func rowLabel(_ title: LocalizedStringKey, icon: String, detail: Text, done: Bool) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            detail.foregroundStyle(.secondary)
            if done { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
        }
    }
}
