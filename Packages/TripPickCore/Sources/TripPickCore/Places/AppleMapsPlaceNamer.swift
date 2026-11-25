import CoreLocation
import Foundation
import MapKit

/// Asks Apple Maps for the city at a coordinate. Only the coordinate is sent, never a photo.
/// Uses `placemark` (deprecated in iOS 26) because `addressRepresentations` has no locality, which is what gives "New York" for Brooklyn.
public struct AppleMapsPlaceNamer: PlaceNaming {
    public init() {}

    public func cityName(for coordinate: Coordinate, locale: Locale) async -> String? {
        await place(for: coordinate, locale: locale)?.city
    }

    public func place(for coordinate: Coordinate, locale: Locale) async -> PlaceName? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
        request.preferredLocale = locale
        guard let item = try? await request.mapItems.first else { return nil }
        let place = item.placemark
        guard let city = CityName.clean(locality: place.locality, admin: place.administrativeArea, countryCode: place.isoCountryCode,
                                        languageCode: locale.language.languageCode?.identifier ?? "en") else { return nil }
        return PlaceName(city: city, country: place.country)
    }
}
