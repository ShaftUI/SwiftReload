// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftReload",

    platforms: [
        .macOS(.v14),
        .iOS(.v15),
        .watchOS(.v8),
        .tvOS(.v15),
    ],

    products: [
        .library(
            name: "SwiftReload",
            targets: ["SwiftReload"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
        .package(url: "https://github.com/swiftlang/swift-tools-support-core", branch: "main"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.1"),
    ],
    targets: [
        .target(
            name: "SwiftReload",
            dependencies: [
                "Yams",
                .product(name: "SwiftToolsSupport", package: "swift-tools-support-core"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ]
        ),
        .executableTarget(
            name: "SwiftReloadExample",
            dependencies: [
                "SwiftReload",
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
            swiftSettings: [
                .unsafeFlags(["-enable-private-imports", "-Xfrontend", "-enable-implicit-dynamic"])
            ]
        ),
        .testTarget(
            name: "SwiftReloadTests",
            dependencies: ["SwiftReload"]
        ),
    ]
)
