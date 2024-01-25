// swift-tools-version: 5.6

// WARNING:
// This file is automatically generated.
// Do not edit it by hand because the contents will be replaced.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "SDK85",
    defaultLocalization: "en",
    platforms: [
        .iOS("15.2")
    ],
    products: [
        .iOSApplication(
            name: "SDK85",
            targets: ["AppModule"],
            bundleIdentifier: "com.otabuzzman.sdk85.ios",
            teamIdentifier: "28FV44657B",
            displayVersion: "1.4.2",
            bundleVersion: "38",
            appIcon: .asset("AppIcon"),
            accentColor: .presetColor(.teal),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            appCategory: .education,
            additionalInfoPlistContentFilePath: "Resources/FontInfo.plist"
        )
    ],
    dependencies: [
        .package(url: "https://github.com/otabuzzman/z80.git", "0.1.12"..<"1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            dependencies: [
                .product(name: "z80", package: "z80")
            ],
            path: ".",
            resources: [
                .process("Resources"),
                .copy("Settings.bundle")
            ]
        )
    ]
)
