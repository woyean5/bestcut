import SwiftUI
import TripPickCore

enum AppSettingsKey {
    static let recommendation = "recommendationEnabled"
    static let shortVideoSeconds = "shortVideoMaxSeconds"
    static let appearance = "appearance"
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var label: LocalizedStringKey {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

extension SessionSettings {
    /// The user's current settings.
    static var current: SessionSettings {
        let d = UserDefaults.standard
        let rec = d.object(forKey: AppSettingsKey.recommendation) as? Bool ?? true
        let secs = d.object(forKey: AppSettingsKey.shortVideoSeconds) as? Int ?? 2
        return SessionSettings(recommendationEnabled: rec, shortVideoMaxSeconds: min(10, max(1, secs)))
    }
}
