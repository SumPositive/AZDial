// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AZDial",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "AZDial",
            targets: ["AZDial"]
        ),
    ],
    targets: [
        .target(
            name: "AZDial"
        ),
        .testTarget(
            name: "AZDialTests",
            dependencies: ["AZDial"]
        ),
    ]
)
