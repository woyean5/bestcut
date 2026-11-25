import SwiftUI
import TripPickCore

/// Two photos one above the other; zooming or panning one moves both.
struct CompareView: View {
    @Environment(\.dismiss) private var dismiss
    let session: TripSession
    let pair: ComparePair
    @Binding var selection: Set<String>

    @State private var scale: CGFloat = 1
    @State private var baseScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var baseOffset: CGSize = .zero

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                pane(pair.a)
                pane(pair.b)
            }
            .padding(.horizontal)
            .gesture(
                MagnifyGesture()
                    .onChanged { scale = min(6, max(1, baseScale * $0.magnification)) }
                    .onEnded { _ in baseScale = scale; if scale == 1 { offset = .zero; baseOffset = .zero } }
                    .simultaneously(with: DragGesture()
                        .onChanged { offset = CGSize(width: baseOffset.width + $0.translation.width, height: baseOffset.height + $0.translation.height) }
                        .onEnded { _ in baseOffset = offset })
            )
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") { dismiss() }
                }
            }
        }
    }

    private func pane(_ id: String) -> some View {
        let kept = selection.contains(id)
        return AssetImageView(id: id, maxPixel: 2000, contentMode: .fit)
            .scaleEffect(scale)
            .offset(offset)
            .clipShape(.rect(cornerRadius: 16))
            .contentShape(.rect)
            .overlay(alignment: .bottomTrailing) {
                Button {
                    if kept { selection.remove(id) } else { selection.insert(id) }
                } label: {
                    Label(kept ? "Keeping" : "Keep this", systemImage: kept ? "checkmark.circle.fill" : "circle")
                }
                .buttonStyle(.glass)
                .tint(kept ? .accentColor : nil)
                .padding(10)
            }
            .overlay(alignment: .topLeading) {
                BadgeRow(flags: session.analyses[id]?.flags ?? [], isFavorite: session.items[id]?.isFavorite ?? false)
                    .padding(10)
            }
    }
}
