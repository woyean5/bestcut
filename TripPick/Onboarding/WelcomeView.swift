import SwiftUI

/// The first-launch "how it works" screen, in the style of Apple's welcome screens.
struct WelcomeView: View {
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 40) {
                    VStack(spacing: 8) {
                        Text("Welcome to")
                        Text(verbatim: "BestCut").foregroundStyle(.tint)
                    }
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .padding(.top, 72)

                    VStack(alignment: .leading, spacing: 28) {
                        row("square.stack.3d.up", "Similar shots, grouped", "Photos taken in a row at one spot become one group.")
                        row("camera.metering.unknown", "Blurry and dark shots, marked", "Shaky, dark, too bright and eyes-closed photos are flagged.")
                        row("hand.draw", "Pick with a swipe", "Right to keep, left to delete later. Nothing is deleted until you confirm.")
                        row("lock.shield", "Your photos stay on iPhone", "Everything is analyzed on this iPhone and never leaves it.")
                    }
                    .padding(.horizontal, 36)
                    .frame(maxWidth: 560)
                }
            }
            Button(action: onContinue) {
                Text("Continue").frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private func row(_ icon: String, _ title: LocalizedStringKey, _ detail: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 18) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(.tint)
                .frame(width: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}
