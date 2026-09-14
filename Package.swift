// swift-tools-version: 6.0
import PackageDescription

// The iOS application and App Store archive remain in OrganizeItAll.xcodeproj.
// This package builds the same model sources for fast, simulator-free tests.
let package = Package(
    name: "OrganizeItAll",
    platforms: [.iOS(.v17), .macOS(.v14)],
    targets: [
        .target(
            name: "OrganizeItAll",
            path: "OrganizeItAll/Models"
        ),
        .testTarget(
            name: "OrganizeItAllTests",
            dependencies: ["OrganizeItAll"],
            path: "OrganizeItAllTests"
        )
    ]
)
