// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "xcresultowners",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/indexstore-db", branch: "swift-6.1.1-RELEASE")
    ],
    targets: [
        .executableTarget(
            name: "xcresultowners",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "IndexStoreDB", package: "indexstore-db")
            ]
        )
    ]
)
