// swift-tools-version: 6.0
import PackageDescription

// The iOS application and App Store archive remain in OrganizeItAll.xcodeproj.
// SwiftPM provides fast model tests plus a small command-line launcher that
// delegates app development actions to scripts/launch.sh.
let package = Package(
    name: "OrganizeItAll",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "OrganizeItAll",
            targets: ["OrganizeItAll"]
        ),
        .executable(
            name: "organizeitall",
            targets: ["OrganizeItAllCLI"]
        )
    ],
    targets: [
        .target(
            name: "OrganizeItAll",
            path: "OrganizeItAll/Models"
        ),
        .executableTarget(
            name: "OrganizeItAllCLI",
            path: "Sources/OrganizeItAllCLI"
        ),
        .testTarget(
            name: "OrganizeItAllTests",
            dependencies: ["OrganizeItAll"],
            path: "OrganizeItAllTests"
        )
    ]
)
