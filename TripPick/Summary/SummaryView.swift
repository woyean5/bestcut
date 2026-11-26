import SwiftUI
import TripPickCore

struct SummaryView: View {
    let session: TripSession
    let tripName: String
    var folderName: String? = nil

    @State private var working = false
    @State private var outcome: Outcome?
    @State private var errorMessage: String?

    enum Outcome: Equatable {
        case albumOnly, deleted(Int), deletedOnly(Int), deleteCancelled, deleteOnlyCancelled
    }

    var body: some View {
        let s = session.summary
        List {
            if let outcome {
                Section {
                    Label(message(outcome), systemImage: outcome == .deleteCancelled || outcome == .deleteOnlyCancelled ? "info.circle" : "checkmark.circle.fill")
                }
            }
            if let errorMessage {
                Section { Label(errorMessage, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
            }
            Section {
                VStack(spacing: 6) {
                    Text("\(s.total) → \(s.best)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("photos in your best album")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                if s.deleteCandidates > 0 {
                    Label(freeable(s), systemImage: "externaldrive.badge.minus")
                        .font(.headline)
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity)
                }
            }
            Section {
                row("Best album", value: s.best, icon: "star", list: .init(decision: .keep, screenshots: false))
                row("Screenshot album", value: s.screenshots, icon: "rectangle.on.rectangle", list: .init(decision: .keep, screenshots: true))
                row("Marked for deletion", value: s.deleteCandidates, icon: "trash", list: .init(decision: .deleteCandidate, screenshots: nil))
                row("Left as they are", value: s.untouched, icon: "circle.dashed", list: .init(decision: .untouched, screenshots: nil))
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Deleted photos stay in Recently Deleted for 30 days, so you can still recover them.")
                    Text("Deleting a photo also removes it from other albums and shared albums.")
                }
            }
        }
        .navigationTitle(Text("Results"))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            GlassEffectContainer {
                VStack(spacing: 10) {
                    if s.deleteCandidates > 0 {
                        Button { finish(delete: true) } label: {
                            Text("Make albums and delete \(s.deleteCandidates)").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.red)
                        Button { finish(delete: true, makeAlbums: false) } label: {
                            Text("Delete \(s.deleteCandidates) without albums").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)
                        .foregroundStyle(.red)
                    }
                    Button { finish(delete: false) } label: {
                        Text("Make albums only").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                }
                .controlSize(.large)
                .disabled(working || (s.best + s.screenshots + s.deleteCandidates == 0))
                .frame(maxWidth: 560)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .overlay { if working { ProgressView().controlSize(.large) } }
    }

    /// Tapping a row shows those photos so they can be checked, and changed, before finishing.
    @ViewBuilder private func row(_ title: LocalizedStringKey, value: Int, icon: String, list: ReviewList) -> some View {
        let content = LabeledContent {
            Text(value, format: .number).monospacedDigit()
        } label: {
            Label(title, systemImage: icon)
        }
        if value > 0 {
            NavigationLink { DecisionListView(session: session, list: list, title: title) } label: { content }
        } else {
            content
        }
    }

    private func freeable(_ s: TripSummary) -> String {
        let size = ByteCountFormatter.string(fromByteCount: s.freeableBytes, countStyle: .file)
        return s.bytesIsEstimate ? L10n.string("About \(size) can be freed") : L10n.string("\(size) can be freed")
    }

    private func message(_ outcome: Outcome) -> String {
        switch outcome {
        case .albumOnly: L10n.string("Albums are ready in Photos.")
        case .deleted(let n): L10n.string("Albums are ready, and \(n) items were deleted.")
        case .deleteCancelled: L10n.string("Deletion was canceled. Your albums are ready.")
        case .deletedOnly(let n): L10n.string("\(n) items were deleted.")
        case .deleteOnlyCancelled: L10n.string("Deletion was canceled.")
        }
    }

    private func finish(delete: Bool, makeAlbums: Bool = true) {
        working = true
        errorMessage = nil
        Task {
            defer { working = false }
            do {
                let result = try await session.finalize(bestAlbum: L10n.string("\(tripName) Best"),
                                                        screenshotAlbum: L10n.string("\(tripName) Screenshots"),
                                                        deleteCandidates: delete, folder: folderName, makeAlbums: makeAlbums)
                if !makeAlbums {
                    outcome = result.deleteCancelled ? .deleteOnlyCancelled : .deletedOnly(result.deleted)
                } else {
                    outcome = result.deleteCancelled ? .deleteCancelled : (delete ? .deleted(result.deleted) : .albumOnly)
                }
            } catch {
                errorMessage = L10n.string("Couldn't update your photo library. Try again.")
            }
        }
    }
}
