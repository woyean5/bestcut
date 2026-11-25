import SwiftUI
import TripPickCore

struct SummaryView: View {
    let session: TripSession
    let tripName: String

    @State private var working = false
    @State private var outcome: Outcome?
    @State private var errorMessage: String?

    enum Outcome: Equatable {
        case albumOnly, deleted(Int), deleteCancelled
    }

    var body: some View {
        let s = session.summary
        List {
            if let outcome {
                Section {
                    Label(message(outcome), systemImage: outcome == .deleteCancelled ? "info.circle" : "checkmark.circle.fill")
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
                row("Best album", value: s.best, icon: "star")
                row("Screenshot album", value: s.screenshots, icon: "rectangle.on.rectangle")
                row("Marked for deletion", value: s.deleteCandidates, icon: "trash")
                row("Left as they are", value: s.untouched, icon: "circle.dashed")
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Deleted photos stay in Recently Deleted for 30 days, so you can still recover them.")
                    Text("Deleting a photo also removes it from other albums and shared albums.")
                }
            }
        }
        .navigationTitle("Results")
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
                    }
                    Button { finish(delete: false) } label: {
                        Text("Make albums only").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                }
                .controlSize(.large)
                .disabled(working || (s.best + s.screenshots + s.deleteCandidates == 0))
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .overlay { if working { ProgressView().controlSize(.large) } }
    }

    private func row(_ title: LocalizedStringKey, value: Int, icon: String) -> some View {
        LabeledContent {
            Text(value, format: .number).monospacedDigit()
        } label: {
            Label(title, systemImage: icon)
        }
    }

    private func freeable(_ s: TripSummary) -> String {
        let size = ByteCountFormatter.string(fromByteCount: s.freeableBytes, countStyle: .file)
        return s.bytesIsEstimate ? String(localized: "About \(size) can be freed") : String(localized: "\(size) can be freed")
    }

    private func message(_ outcome: Outcome) -> String {
        switch outcome {
        case .albumOnly: String(localized: "Albums are ready in Photos.")
        case .deleted(let n): String(localized: "Albums are ready, and \(n) items were deleted.")
        case .deleteCancelled: String(localized: "Deletion was canceled. Your albums are ready.")
        }
    }

    private func finish(delete: Bool) {
        working = true
        errorMessage = nil
        Task {
            defer { working = false }
            do {
                let result = try await session.finalize(bestAlbum: String(localized: "\(tripName) Best"),
                                                        screenshotAlbum: String(localized: "\(tripName) Screenshots"),
                                                        deleteCandidates: delete)
                outcome = result.deleteCancelled ? .deleteCancelled : (delete ? .deleted(result.deleted) : .albumOnly)
            } catch {
                errorMessage = String(localized: "Couldn't update your photo library. Try again.")
            }
        }
    }
}
