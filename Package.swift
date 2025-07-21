// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "xcresultowners",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "xcresultowners", targets: ["xcresultowners"]),
        .library(name: "XCResultOwnersCore", targets: ["XCResultOwnersCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/indexstore-db", revision: "swift-6.1.1-RELEASE")
    ],
    targets: [
        .executableTarget(
            name: "xcresultowners",
            dependencies: [
                "XCResultOwnersCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "XCResultOwnersCore",
            dependencies: [
                .product(name: "IndexStoreDB", package: "indexstore-db")
            ]
        ),
        .testTarget(
            name: "Tests",
            dependencies: ["XCResultOwnersCore"]
        )
    ],
    swiftLanguageVersions: [.version("6"), .v5]
)

import Foundation

if ProcessInfo.processInfo.environment["CI"] == "true" {
    package.dependencies += [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.5"),
    ]
}
