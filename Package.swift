// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "lilshot",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "LilshotCore", targets: ["LilshotCore"]),
        .executable(name: "lilshot", targets: ["lilshot"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .target(name: "LilshotCore"),
        .executableTarget(
            name: "lilshot",
            dependencies: [
                "LilshotCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "LilshotCoreTests",
            dependencies: ["LilshotCore"]
        ),
    ]
)
