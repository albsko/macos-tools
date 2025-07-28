// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "swift-tools",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "CUtils",
            publicHeadersPath: "include"
        ),
        .target(
            name: "Utils",
            dependencies: ["CUtils"]
        ),
        .executableTarget(
            name: "FocusWindow",
            dependencies: [
                "Utils",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
    ]
)
