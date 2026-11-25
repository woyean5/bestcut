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

/// The app's display language, chosen in Settings. "System" follows the iPhone's language.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system, ko, en, ja
    var id: String { rawValue }

    static let storageKey = "appLanguage"

    static var current: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .system
    }

    /// The locale used to look up strings and format dates and numbers.
    var locale: Locale {
        switch self {
        case .system: Locale(identifier: Locale.preferredLanguages.first ?? "en")
        default: Locale(identifier: rawValue)
        }
    }

    /// Each language is shown in its own script so people can find theirs.
    var nativeName: String? {
        switch self {
        case .system: nil
        case .ko: "한국어"
        case .en: "English"
        case .ja: "日本語"
        }
    }

    /// Also tells iOS, so system-provided text in the app follows on the next launch.
    func applyToSystem() {
        if self == .system {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([rawValue], forKey: "AppleLanguages")
        }
    }
}

/// Localized strings built in code (not in a SwiftUI Text), in the app's chosen language.
enum L10n {
    static func string(_ key: String.LocalizationValue) -> String {
        String(localized: LocalizedStringResource(key, locale: AppLanguage.current.locale))
    }
}
