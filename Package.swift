// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AnythingBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "AnythingBarCore", targets: ["AnythingBarCore"])
    ],
    targets: [
        .target(
            name: "AnythingBarCore"
        ),
        .testTarget(
            name: "AnythingBarCoreTests",
            dependencies: ["AnythingBarCore"],
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ]
        )
    ]
)
