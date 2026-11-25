import Photos
import Testing
@testable import TripPickCore

@Test func permissionMapping() {
    #expect(PermissionState(.authorized) == .full)
    #expect(PermissionState(.limited) == .limited)
    #expect(PermissionState(.denied) == .denied)
    #expect(PermissionState(.restricted) == .denied)
    #expect(PermissionState(.notDetermined) == .notDetermined)
    #expect(PermissionState(.limited).canUseLibrary)
    #expect(!PermissionState(.denied).canUseLibrary)
}
