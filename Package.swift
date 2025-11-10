// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MakNetworkManager",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "MakNetworkManager",
            targets: ["MakNetworkManager"]),
    ],
    dependencies: [
        // No external dependencies - pure Swift implementation
    ],
    targets: [
        .target(
            name: "MakNetworkManager",
            dependencies: []),
        .testTarget(
            name: "MakNetworkManagerTests",
            dependencies: ["MakNetworkManager"]),
    ]
)
