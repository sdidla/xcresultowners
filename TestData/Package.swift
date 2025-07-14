// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TestProject",
    products: [],
    targets: [
        .target(name: "ModuleA"),
        .target(name: "ModuleB"),
        .testTarget(name: "ModuleATests", dependencies: ["ModuleA"]),
        .testTarget(name: "ModuleBTests", dependencies: ["ModuleB"])
    ]
)
