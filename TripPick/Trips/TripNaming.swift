import Foundation
import TripPickCore

/// Suggests a trip name from the places its photos were taken, like "뉴욕·워싱턴 여행".
enum TripNaming {
    static func suggestedName(for items: [MediaItem]) async -> String? {
        let locale = AppLanguage.current.locale
        let names = await TripTitle.suggestedPlaces(items: items, namer: AppleMapsPlaceNamer(), locale: locale)
        guard !names.isEmpty else { return nil }
        let places = TripTitle.join(names, languageCode: locale.language.languageCode?.identifier ?? "en")
        return L10n.string("\(places) Trip")
    }
}
