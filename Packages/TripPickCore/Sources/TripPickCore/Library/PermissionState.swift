import Photos

public enum PermissionState: Sendable, Equatable {
    case notDetermined, denied, limited, full

    public init(_ status: PHAuthorizationStatus) {
        switch status {
        case .authorized: self = .full
        case .limited: self = .limited
        case .notDetermined: self = .notDetermined
        default: self = .denied
        }
    }

    public var canUseLibrary: Bool { self == .full || self == .limited }
}
