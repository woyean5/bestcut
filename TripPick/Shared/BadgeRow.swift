import SwiftUI
import TripPickCore

/// Small labels shown on a photo: best shot, problems, favorite.
struct BadgeRow: View {
    var flags: QualityFlags
    var isFavorite = false
    var isRecommended = false
    var compact = false

    var body: some View {
        HStack(spacing: 4) {
            if isRecommended { badge("Best", "star.fill", .yellow) }
            if isFavorite { badge("Favorite", "heart.fill", .pink) }
            if flags.contains(.blurry) { badge("Blurry", "camera.metering.unknown", .orange) }
            if flags.contains(.eyesClosed) { badge("Eyes closed", "eye.slash", .orange) }
            if flags.contains(.dark) { badge("Dark", "moon.fill", .orange) }
            if flags.contains(.overexposed) { badge("Too bright", "sun.max.fill", .orange) }
        }
        // Labels only: touches go to the photo underneath, so tapping or long-pressing near a badge still works.
        .allowsHitTesting(false)
    }

    @ViewBuilder private func badge(_ title: LocalizedStringKey, _ icon: String, _ tint: Color) -> some View {
        Group {
            if compact {
                Image(systemName: icon).padding(5)
            } else {
                Label(title, systemImage: icon).padding(.horizontal, 8).padding(.vertical, 4)
            }
        }
        .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
        .foregroundStyle(tint)
        .glassEffect(.regular, in: .capsule)
    }
}
