// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SDK85",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/otabuzzman/z80.git", from: "0.1.7"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "SDK85",
            dependencies: ["z80"]),
        .testTarget(
            name: "SDK85Tests",
            dependencies: ["SDK85"]),
    ]
)
