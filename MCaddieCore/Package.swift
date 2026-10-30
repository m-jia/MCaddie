// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MCaddieCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "MCaddieCore",
            targets: ["MCaddieCore"]),
    ],
    targets: [
        .target(
            name: "MCaddieCore",
            dependencies: []
        ),
        .testTarget(
            name: "MCaddieCoreTests",
            dependencies: ["MCaddieCore"]
        ),
    ]
)
