import SwiftUI
import TripPickCore

struct PermissionView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    let state: PermissionState

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "photo.stack")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(.tint)
                .padding(28)
                .glassEffect(.regular, in: .circle)
            VStack(spacing: 12) {
                Text(state == .denied ? "Photo access is off" : "Keep only your best shots")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text(state == .denied
                     ? "BestCut needs access to your photos to find blurry shots and group similar ones. You can turn it on in Settings."
                     : "BestCut finds blurry shots and groups similar photos so you only have to pick. Your photos are analyzed on this iPhone and never leave it.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            Spacer()
            Group {
                if state == .denied {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                } else {
                    Button("Allow photo access") {
                        Task { await model.requestPermission() }
                    }
                }
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
    }
}
