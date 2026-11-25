import SwiftUI
import TripPickCore

struct ReviewList: Hashable {
    var decision: Decision
    var screenshots: Bool?
}

/// Every photo with one decision, for a last look before finishing. Tapping a photo shows it large and lets you change it.
struct DecisionListView: View {
    let session: TripSession
    let list: ReviewList
    let title: LocalizedStringKey
    @State private var opened: OpenedPhoto?

    var body: some View {
        let ids = session.items(with: list.decision, screenshots: list.screenshots)
        ScrollView {
            if ids.isEmpty {
                ContentUnavailableView("All done here", systemImage: "checkmark.circle")
                    .padding(.top, 80)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3), spacing: 3) {
                    ForEach(ids, id: \.self) { id in
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .overlay { AssetImageView(id: id, maxPixel: 300) }
                            .clipped()
                            .overlay(alignment: .bottomLeading) {
                                if session.items[id]?.kind == .video {
                                    Image(systemName: "video.fill").font(.caption).foregroundStyle(.white).padding(5)
                                }
                            }
                            .contentShape(.rect)
                            .onTapGesture { opened = OpenedPhoto(id: id) }
                    }
                }
            }
        }
        .navigationTitle(Text(title))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $opened) { photo in
            PhotoDecisionView(session: session, id: photo.id)
                .presentationDetents([.large])
        }
    }
}

struct OpenedPhoto: Identifiable { var id: String }

/// One photo, large, with the three choices.
struct PhotoDecisionView: View {
    @Environment(\.dismiss) private var dismiss
    let session: TripSession
    let id: String

    var body: some View {
        let current = session.decision(id)
        NavigationStack {
            VStack(spacing: 16) {
                AssetImageView(id: id, maxPixel: 2000, contentMode: .fit, isVideo: session.items[id]?.kind == .video)
                    .clipShape(.rect(cornerRadius: 16))
                    .frame(maxHeight: .infinity)
                    .overlay(alignment: .topLeading) {
                        BadgeRow(flags: session.analyses[id]?.flags ?? [], isFavorite: session.items[id]?.isFavorite ?? false)
                            .padding(10)
                    }
                GlassEffectContainer {
                    HStack(spacing: 10) {
                        choice(.keep, "Keep", "heart.fill", .green, current: current)
                        choice(.deleteCandidate, "Delete later", "trash", .red, current: current)
                        choice(.untouched, "Leave as is", "circle.dashed", .secondary, current: current)
                    }
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") { dismiss() }
                }
            }
        }
    }

    private func choice(_ decision: Decision, _ title: LocalizedStringKey, _ icon: String, _ tint: Color, current: Decision) -> some View {
        Button {
            session.setDecision(decision, for: id)
            dismiss()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title2).foregroundStyle(tint)
                Text(title).font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity, minHeight: 64)
        }
        .buttonStyle(.plain)
        .glassEffect(current == decision ? .regular.tint(tint.opacity(0.25)).interactive() : .regular.interactive(),
                     in: .rect(cornerRadius: 16))
        .overlay {
            if current == decision { RoundedRectangle(cornerRadius: 16).strokeBorder(tint, lineWidth: 2) }
        }
    }
}
