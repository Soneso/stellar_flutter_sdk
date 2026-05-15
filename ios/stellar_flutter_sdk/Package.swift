// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "stellar_flutter_sdk",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .library(name: "stellar-flutter-sdk", targets: ["stellar_flutter_sdk"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "stellar_flutter_sdk",
            dependencies: [],
            resources: [
                // No bundled resources at present. If a privacy manifest
                // (PrivacyInfo.xcprivacy) is later required for the WebAuthn /
                // Keychain code paths, add it under
                // Sources/stellar_flutter_sdk/PrivacyInfo.xcprivacy and
                // uncomment the line below.
                // .process("PrivacyInfo.xcprivacy"),
            ]
        ),
        .testTarget(
            name: "stellar_flutter_sdkTests",
            dependencies: ["stellar_flutter_sdk"]
        )
    ]
)
