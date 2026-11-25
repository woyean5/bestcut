public enum DecisionRules {
    /// The decision that applies to an item: what the user stored, else favorites are kept, else untouched.
    public static func effective(stored: Decision?, item: MediaItem) -> Decision {
        if let stored { return stored }
        return item.isFavorite ? .keep : .untouched
    }
}
