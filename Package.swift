// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "gitnagg",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .executable(name: "gitnagg", targets: ["gitnagg"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.6.2"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.2"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.2.1"),
    ],
    targets: [
        .executableTarget(
            name: "gitnagg",
            dependencies: [
                "GitNaggCLI",
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "Sources/gitnagg"
        ),
        .target(
            name: "GitNaggCLI",
            dependencies: [
                "GitNaggKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "GitNaggKit",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Yams", package: "Yams"),
            ]
        ),
        .testTarget(
            name: "GitNaggKitTests",
            dependencies: ["GitNaggKit"]
        ),
    ]
)
