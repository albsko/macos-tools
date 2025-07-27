// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "swift-tools",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0")
    ],
    targets: [
        .executableTarget(
            name: "FocusWindow",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(
            name: "Utils",
            dependencies: ["CUtils"]
        ),
        .target(
            name: "CUtils",
            publicHeadersPath: "include"
        ),
    ]
)
