import SwiftUI
import TripPickCore

@main
struct TripPickApp: App {
    var body: some Scene {
        WindowGroup {
            Text("TripPick \(TripPickCore.version)")
        }
    }
}
