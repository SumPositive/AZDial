// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AZDial",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "AZDial",
            targets: ["AZDial"]
        ),
    ],
    targets: [
        .target(
            name: "AZDial",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "AZDialTests",
            dependencies: ["AZDial"]
        ),
    ]
)
