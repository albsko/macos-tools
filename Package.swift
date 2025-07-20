// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "swift-tools",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0")
    ],
    targets: [
        // .executableTarget(
        //     name: "swift-tools",
        //     dependencies: [
        //         .product(name: "ArgumentParser", package: "swift-argument-parser")
        //     ]
        // ),
        .executableTarget(
            name: "focus-window",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        // .testTarget(
        //     name: "swift_toolsTests",
        //     dependencies: ["swift-tools"]
        // ),
    ]
)
