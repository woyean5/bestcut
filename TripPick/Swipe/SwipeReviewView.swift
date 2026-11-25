import SwiftUI
import TripPickCore

/// One photo at a time: swipe right to keep, left to mark for deletion.
struct SwipeReviewView: View {
    let session: TripSession
    let singlesOnly: Bool

    @State private var queue: [String] = []
    @State private var index = 0
    @State private var drag: CGSize = .zero
    @State private var loaded = false

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 16) {
                if index < queue.count {
                    let size = cardSize(in: geo.size)
                    ZStack {
                        // The next photo waits behind at the same size, so nothing zooms when it comes forward.
                        if index + 1 < queue.count {
                            card(queue[index + 1], size: size)
                        }
                        card(queue[index], size: size)
                            .offset(x: drag.width, y: drag.height * 0.2)
                            .rotationEffect(.degrees(Double(drag.width / 22)))
                            .overlay { decisionHint(width: geo.size.width) }
                            .gesture(
                                DragGesture()
                                    .onChanged { drag = $0.translation }
                                    .onEnded { value in
                                        let limit = geo.size.width * 0.3
                                        if value.translation.width > limit { decide(keep: true) }
                                        else if value.translation.width < -limit { decide(keep: false) }
                                        else { withAnimation(.spring) { drag = .zero } }
                                    }
                            )
                    }
                    .padding(.horizontal, 20)
                    .frame(maxHeight: .infinity)
                    controls
                } else if loaded {
                    finished
                }
            }
        }
        .navigationTitle(singlesOnly ? Text("Single photos") : Text("One by one"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if index < queue.count {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(index + 1) / \(queue.count)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: index)
        .onAppear {
            guard !loaded else { return }
            queue = session.swipeQueue(singlesOnly: singlesOnly)
            loaded = true
        }
    }

    /// One fixed card size for every photo, whatever its shape.
    private func cardSize(in space: CGSize) -> CGSize {
        let width = max(0, space.width - 40)
        let height = min(width * 4 / 3, max(0, space.height - 150))
        return CGSize(width: width, height: height)
    }

    /// The whole photo, never cropped: a blurred copy fills the card behind it.
    private func card(_ id: String, size: CGSize) -> some View {
        ZStack {
            AssetImageView(id: id, maxPixel: 120, contentMode: .fill)
                .blur(radius: 24)
                .opacity(0.6)
            AssetImageView(id: id, maxPixel: 1400, contentMode: .fit, isVideo: session.items[id]?.kind == .video)
        }
        .frame(width: size.width, height: size.height)
        .background(.black)
        .clipShape(.rect(cornerRadius: 28))
            .overlay(alignment: .topLeading) {
                BadgeRow(flags: session.analyses[id]?.flags ?? [], isFavorite: session.items[id]?.isFavorite ?? false)
                    .padding(14)
            }
            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
            .id(id)
    }

    @ViewBuilder private func decisionHint(width: CGFloat) -> some View {
        let strength = min(1, abs(drag.width) / (width * 0.3))
        if drag.width != 0 {
            let keep = drag.width > 0
            Label(keep ? "Keep" : "Delete later", systemImage: keep ? "heart.fill" : "xmark")
                .font(.title2.bold())
                .foregroundStyle(keep ? .green : .red)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .glassEffect(.regular, in: .capsule)
                .opacity(strength)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: keep ? .topLeading : .topTrailing)
                .padding(32)
        }
    }

    private var controls: some View {
        GlassEffectContainer(spacing: 24) {
            HStack(spacing: 24) {
                Button { decide(keep: false) } label: {
                    Image(systemName: "xmark").font(.title2.bold()).foregroundStyle(.red).frame(width: 64, height: 64)
                }
                .glassEffect(.regular.interactive(), in: .circle)
                .accessibilityLabel(Text("Delete later"))
                Button { undo() } label: {
                    Image(systemName: "arrow.uturn.backward").font(.title3).frame(width: 48, height: 48)
                }
                .glassEffect(.regular.interactive(), in: .circle)
                .accessibilityLabel(Text("Undo"))
                Button { decide(keep: true) } label: {
                    Image(systemName: "heart.fill").font(.title2.bold()).foregroundStyle(.green).frame(width: 64, height: 64)
                }
                .glassEffect(.regular.interactive(), in: .circle)
                .accessibilityLabel(Text("Keep"))
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 12)
    }

    private var finished: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.seal").font(.system(size: 56, weight: .light)).foregroundStyle(.tint)
            Text("All picked").font(.title2.bold())
            Text("Nothing left to decide here.").foregroundStyle(.secondary)
            NavigationLink(value: HomeRoute.summary) { Text("See results") }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func decide(keep: Bool) {
        guard index < queue.count else { return }
        session.swipe(queue[index], keep: keep)
        withAnimation(.snappy) {
            drag = .zero
            index += 1
        }
    }

    private func undo() {
        guard let id = session.undo(), let position = queue.firstIndex(of: id) else { return }
        withAnimation(.snappy) { index = position; drag = .zero }
    }
}
