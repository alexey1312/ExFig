// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "exfig",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "exfig", targets: ["ExFig"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections", "1.2.0" ..< "1.3.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.3.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.0"),
        .package(url: "https://github.com/stencilproject/Stencil.git", from: "0.15.1"),
        .package(url: "https://github.com/SwiftGen/StencilSwiftKit", from: "2.10.1"),
        .package(url: "https://github.com/tuist/XcodeProj.git", from: "8.27.0"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.0"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "4.2.0"),
        .package(url: "https://github.com/the-swift-collective/libwebp.git", from: "1.4.1"),
        .package(url: "https://github.com/the-swift-collective/libpng.git", from: "1.6.45"),
        .package(url: "https://github.com/toon-format/toon-swift", from: "0.3.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.5"),
        .package(url: "https://github.com/alexey1312/swift-resvg.git", exact: "0.45.1-swift.2"),
    ],
    targets: [
        // Main target
        .executableTarget(
            name: "ExFig",
            dependencies: [
                "FigmaAPI",
                "ExFigCore",
                "XcodeExport",
                "AndroidExport",
                "FlutterExport",
                "WebExport",
                "SVGKit",
                .product(name: "Resvg", package: "swift-resvg"),
                .product(name: "XcodeProj", package: "XcodeProj"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Yams", package: "Yams"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Rainbow", package: "Rainbow"),
                .product(name: "WebP", package: "libwebp"),
                .product(name: "LibPNG", package: "libpng"),
                .product(name: "ToonFormat", package: "toon-swift"),
            ]
        ),

        // Shared target
        .target(
            name: "ExFigCore"
        ),

        // Loads data via Figma REST API
        .target(
            name: "FigmaAPI"
        ),

        // Exports resources to Xcode project
        .target(
            name: "XcodeExport",
            dependencies: [
                "ExFigCore", .product(name: "Stencil", package: "Stencil"),
                "StencilSwiftKit",
            ],
            resources: [
                .copy("Resources/"),
            ]
        ),

        // SVG parsing and code generation
        .target(
            name: "SVGKit",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
            ]
        ),

        // Exports resources to Android project
        .target(
            name: "AndroidExport",
            dependencies: [
                "ExFigCore",
                "SVGKit",
                "Stencil",
                "StencilSwiftKit",
                .product(name: "OrderedCollections", package: "swift-collections"),
            ],
            resources: [
                .copy("Resources/"),
            ]
        ),

        // Exports resources to Flutter project
        .target(
            name: "FlutterExport",
            dependencies: ["ExFigCore", "Stencil", "StencilSwiftKit"],
            resources: [
                .copy("Resources/"),
            ]
        ),

        // Exports resources to Web/React project
        .target(
            name: "WebExport",
            dependencies: ["ExFigCore", "Stencil", "StencilSwiftKit"],
            resources: [
                .copy("Resources/"),
            ]
        ),

        // MARK: - Tests

        .testTarget(
            name: "FigmaAPITests",
            dependencies: [
                "FigmaAPI",
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ],
            resources: [
                .copy("Fixtures/"),
            ]
        ),
        .testTarget(
            name: "ExFigTests",
            dependencies: [
                "ExFig",
                "FigmaAPI",
                .product(name: "CustomDump", package: "swift-custom-dump"),
                .product(name: "LibPNG", package: "libpng"),
            ]
        ),
        .testTarget(
            name: "ExFigCoreTests",
            dependencies: [
                "ExFigCore",
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ]
        ),
        .testTarget(
            name: "XcodeExportTests",
            dependencies: [
                "XcodeExport", .product(name: "CustomDump", package: "swift-custom-dump"),
                "StencilSwiftKit",
            ]
        ),
        .testTarget(
            name: "AndroidExportTests",
            dependencies: [
                "AndroidExport",
                .product(name: "CustomDump", package: "swift-custom-dump"),
                .product(name: "OrderedCollections", package: "swift-collections"),
            ]
        ),
        .testTarget(
            name: "FlutterExportTests",
            dependencies: [
                "FlutterExport", .product(name: "CustomDump", package: "swift-custom-dump"),
            ]
        ),
        .testTarget(
            name: "WebExportTests",
            dependencies: [
                "WebExport", .product(name: "CustomDump", package: "swift-custom-dump"),
            ]
        ),
        .testTarget(
            name: "SVGKitTests",
            dependencies: ["SVGKit", .product(name: "CustomDump", package: "swift-custom-dump")]
        ),
    ]
)
