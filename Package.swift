// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "lilshot",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "LilshotCore", targets: ["LilshotCore"]),
        .library(name: "LilshotMac", targets: ["LilshotMac"]),
        .executable(name: "lilshot", targets: ["lilshot"]),
        .executable(name: "LilshotApp", targets: ["LilshotApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .target(name: "LilshotCore"),
        .target(
            name: "LilshotMac",
            dependencies: ["LilshotCore"]
        ),
        .executableTarget(
            name: "lilshot",
            dependencies: [
                "LilshotCore",
                "LilshotMac",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .executableTarget(
            name: "LilshotApp",
            dependencies: [
                "LilshotCore",
                "LilshotMac",
            ],
            resources: [
                .copy("assets"),
            ]
        ),
        .testTarget(
            name: "LilshotCoreTests",
            dependencies: ["LilshotCore"]
        ),
    ]
)
