import Testing
@testable import TripPickCore

@Test func coreVersionIsSet() { #expect(TripPickCore.version == "0.1.0") }
