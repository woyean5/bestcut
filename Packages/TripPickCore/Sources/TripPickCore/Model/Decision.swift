public enum Decision: String, Codable, Sendable {
    /// Goes into the best album.
    case keep
    /// Deleted only after the user confirms on the summary screen.
    case deleteCandidate
    /// Not decided; never added to an album, never deleted.
    case untouched
}
