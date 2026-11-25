/// Turns map address parts into the name people use for a city in a trip title.
public enum CityName {
    private static let tokyoNames: Set<String> = ["도쿄", "Tokyo", "東京都", "東京"]
    private static let suffixes: [String: [String]] = [
        "ko": ["특별자치시", "특별시", "광역시", "시"],
        "ja": ["都", "市"],
        "en": ["-si", "-shi"],
    ]

    public static func clean(locality: String?, admin: String?, countryCode: String?, languageCode: String) -> String? {
        // Tokyo's 23 wards come back as the city; people call the whole place Tokyo.
        if countryCode == "JP", let admin, tokyoNames.contains(admin) { return stripSuffix(admin, languageCode) }
        guard let name = locality ?? admin else { return nil }
        return stripSuffix(name, languageCode)
    }

    private static func stripSuffix(_ name: String, _ languageCode: String) -> String {
        for suffix in suffixes[languageCode] ?? [] where name.hasSuffix(suffix) {
            let base = String(name.dropLast(suffix.count))
            if base.count >= 2 { return base }
        }
        return name
    }
}
