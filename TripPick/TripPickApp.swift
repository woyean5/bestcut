import SwiftData
import SwiftUI
import TripPickCore

@main
struct TripPickApp: App {
    @State private var model = AppModel()
    private let container: ModelContainer = {
        do { return try TripPickSchema.container(inMemory: false) }
        catch { fatalError("Could not open the database: \(error)") }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
        }
        .modelContainer(container)
    }
}

/// App-wide state: the photo library and its permission.
@MainActor @Observable final class AppModel {
    let library: PhotoLibrary = PhotoKitLibrary()
    private(set) var permission: PermissionState

    init() {
        permission = library.permission()
    }

    func requestPermission() async {
        permission = await library.requestPermission()
    }

    func refreshPermission() {
        permission = library.permission()
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppSettingsKey.appearance) private var appearance = AppearanceMode.system.rawValue
    @AppStorage(AppLanguage.storageKey) private var language = AppLanguage.system.rawValue
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    var body: some View {
        Group {
            if !hasSeenWelcome {
                WelcomeView { hasSeenWelcome = true }
            } else if model.permission.canUseLibrary {
                TripListView()
            } else {
                PermissionView(state: model.permission)
            }
        }
        .environment(\.locale, (AppLanguage(rawValue: language) ?? .system).locale)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.refreshPermission() }
        }
        // Set on the window itself so open sheets change at once and "System" truly goes back to the iPhone setting.
        .onAppear { (AppearanceMode(rawValue: appearance) ?? .system).applyToWindows() }
        .onChange(of: appearance) { _, new in (AppearanceMode(rawValue: new) ?? .system).applyToWindows() }
    }
}
