import SwiftUI
import TripPickCore

/// Two photos one above the other. Pinching zooms both around their centres; photos never move. Double-tap toggles zoom.
struct CompareView: View {
    @Environment(\.dismiss) private var dismiss
    let session: TripSession
    let pair: ComparePair
    @Binding var selection: Set<String>

    @State private var scale: CGFloat = 1
    @State private var baseScale: CGFloat = 1

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                pane(pair.a)
                pane(pair.b)
            }
            .padding(.horizontal)
            .gesture(
                MagnifyGesture()
                    .onChanged { scale = min(5, max(1, baseScale * $0.magnification)) }
                    .onEnded { _ in baseScale = scale }
            )
            .onTapGesture(count: 2) {
                withAnimation(.snappy) { scale = scale > 1 ? 1 : 2.5 }
                baseScale = scale
            }
            .interactiveDismissDisabled()
            .navigationTitle(Text("Compare"))
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
