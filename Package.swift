// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OrganizeItAll",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
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
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "1.8.2"
        )
    ],
    targets: [
        .target(
            name: "OrganizeItAll",
            path: "OrganizeItAll/Models"
        ),
        .executableTarget(
            name: "OrganizeItAllCLI",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                )
            ]
        ),
        .plugin(
            name: "OrganizeItAllCommand",
            capability: .command(
                intent: .custom(
                    verb: "organizeitall",
                    description: "Build, test, run, and inspect the OrganizeItAll iOS app."
                )
            ),
            dependencies: ["OrganizeItAllCLI"]
        ),
        .testTarget(
            name: "OrganizeItAllTests",
            dependencies: ["OrganizeItAll"],
            path: "OrganizeItAllTests"
        )
    ]
)
