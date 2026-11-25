// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TripPickCore",
    defaultLocalization: "en",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "TripPickCore", targets: ["TripPickCore"])],
    targets: [
        .target(name: "TripPickCore"),
        .testTarget(name: "TripPickCoreTests", dependencies: ["TripPickCore"]),
    ]
)
