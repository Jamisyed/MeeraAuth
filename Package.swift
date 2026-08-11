// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MeeraAuth",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "MeeraAuth", targets: ["MeeraAuth"])
    ],
    targets: [
        .target(
            name: "MeeraAuth",
            path: "Sources/MeeraAuth",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "MeeraAuthTests",
            dependencies: ["MeeraAuth"],
            path: "Tests/MeeraAuthTests",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
