// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "MacOSTools",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "CUtils", targets: ["CUtils"]),
        .library(name: "Utils", targets: ["Utils"]),
        .executable(name: "focus-window", targets: ["FocusWindow"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0")
    ],
    targets: [
        .target(name: "CUtils"),
        .target(name: "Utils", dependencies: ["CUtils"]),

        .executableTarget(
            name: "FocusWindow",
            dependencies: [
                "Utils", .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
    ],
)
