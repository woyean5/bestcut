import SwiftUI
import TripPickCore

enum ReviewQueue: Hashable {
    /// Every unfinished set in order: similar, screenshots, flagged, short videos.
    case continueAll
    /// The sets of one category, starting at the first unfinished one.
    case kind(ReviewKind)
}

struct ReviewSetView: View {
    @Environment(\.dismiss) private var dismiss
    let session: TripSession
    let queue: ReviewQueue

    @State private var current: ReviewSet?
    @State private var selection: Set<String> = []
    @State private var focused: String?
    @State private var compareFirst: String?
    @State private var comparing: ComparePair?

    var body: some View {
        Group {
            if let set = current {
                content(set)
            } else {
                ContentUnavailableView("All done here", systemImage: "checkmark.circle", description: Text("Every group in this list is decided."))
            }
        }
        .onAppear { if current == nil { load(firstSet()) } }
        .sheet(item: $comparing) { pair in
            CompareView(session: session, pair: pair, selection: $selection)
        }
    }

    @ViewBuilder private func content(_ set: ReviewSet) -> some View {
        let recommended = session.recommendation(in: set)
        let focus = focused ?? set.itemIDs[0]
        VStack(spacing: 12) {
            ZStack(alignment: .top) {
                AssetImageView(id: focus, maxPixel: 1600, contentMode: .fit, isVideo: session.items[focus]?.kind == .video)
                    .clipShape(.rect(cornerRadius: 20))
                HStack {
                    BadgeRow(flags: session.analyses[focus]?.flags ?? [], isFavorite: session.items[focus]?.isFavorite ?? false,
                             isRecommended: focus == recommended)
                    Spacer()
                }
                .padding(10)
            }
            .overlay(alignment: .bottomTrailing) {
                keepToggle(focus, large: true).padding(12)
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 8) {
                    ForEach(set.itemIDs, id: \.self) { id in
                        thumbnail(id, focused: id == focus, recommended: id == recommended)
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
            .frame(height: 96)

            Text(compareFirst == nil ? "Long-press two photos to compare them" : "Long-press another photo to compare")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button {
                session.confirm(set, keeping: selection)
                load(nextSet(after: set))
            } label: {
                Group {
                    if selection.isEmpty { Text("Mark all for deletion") } else { Text("Keep \(selection.count) and continue") }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(selection.isEmpty ? .red : .accentColor)
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .navigationTitle(title(set))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func thumbnail(_ id: String, focused: Bool, recommended: Bool) -> some View {
        AssetImageView(id: id, maxPixel: 300, isVideo: session.items[id]?.kind == .video)
            .frame(width: 84, height: 84)
            .clipShape(.rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(compareFirst == id ? Color.orange : (focused ? Color.accentColor : .clear), lineWidth: 3)
            }
            .overlay(alignment: .topLeading) {
                BadgeRow(flags: session.analyses[id]?.flags ?? [], isFavorite: session.items[id]?.isFavorite ?? false,
                         isRecommended: recommended, compact: true)
                    .padding(3)
            }
            .overlay(alignment: .bottomTrailing) { keepToggle(id, large: false).padding(4) }
            .onLongPressGesture(minimumDuration: 0.4) { longPress(id) }
            .onTapGesture { self.focused = id }
    }

    private func keepToggle(_ id: String, large: Bool) -> some View {
        let kept = selection.contains(id)
        return Button {
            if kept { selection.remove(id) } else { selection.insert(id) }
        } label: {
            Image(systemName: kept ? "checkmark.circle.fill" : "circle")
                .font(large ? .title : .body)
                .foregroundStyle(kept ? Color.accentColor : .white)
                .padding(large ? 8 : 2)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(kept ? Text("Keep") : Text("Don't keep"))
    }

    private func longPress(_ id: String) {
        if let first = compareFirst, first != id {
            comparing = ComparePair(a: first, b: id)
            compareFirst = nil
        } else {
            compareFirst = id
        }
    }

    private func title(_ set: ReviewSet) -> LocalizedStringKey {
        switch set.kind {
        case .similar: "Similar photos"
        case .screenshots: "Similar screenshots"
        case .flagged: "Blurry or dark"
        case .shortVideos: "Short videos"
        }
    }

    private func firstSet() -> ReviewSet? {
        switch queue {
        case .continueAll: session.nextReviewSet()
        case .kind(let kind):
            session.buckets.sets(of: kind).first { !session.isDone($0) } ?? session.buckets.sets(of: kind).first
        }
    }

    private func nextSet(after set: ReviewSet) -> ReviewSet? {
        switch queue {
        case .continueAll: return session.nextReviewSet()
        case .kind(let kind):
            let sets = session.buckets.sets(of: kind)
            let start = (sets.firstIndex(of: set) ?? -1) + 1
            return sets[start...].first { !session.isDone($0) } ?? sets.first { !session.isDone($0) }
        }
    }

    private func load(_ set: ReviewSet?) {
        compareFirst = nil
        guard let set else { dismiss(); return }
        current = set
        selection = session.preselected(in: set)
        focused = set.itemIDs.first { selection.contains($0) } ?? set.itemIDs.first
    }
}

struct ComparePair: Identifiable, Hashable {
    var a: String
    var b: String
    var id: String { a + "|" + b }
}
