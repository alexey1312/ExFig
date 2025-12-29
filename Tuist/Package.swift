// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            // Use dynamic frameworks for SwiftUI app
            "Yams": .framework,
            "Logging": .framework,
            "Stencil": .framework,
            "StencilSwiftKit": .framework,
        ]
    )
#endif

// Third-party dependencies for ExFig Studio
// Note: ExFigKit, FigmaAPI, ExFigCore are defined as native Tuist targets
// to avoid issues with Tuist's handling of local SPM packages with binary dependencies
//
// Binary dependencies (Resvg) are defined as native Tuist targets in Project.swift
// using XCFrameworks built by Scripts/build-xcframeworks.sh
let package = Package(
    name: "ExFigDependencies",
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.3.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.0"),
        .package(url: "https://github.com/stencilproject/Stencil.git", from: "0.15.1"),
        .package(url: "https://github.com/SwiftGen/StencilSwiftKit", from: "2.10.1"),
        .package(url: "https://github.com/apple/swift-collections", "1.2.0" ..< "1.3.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
        // C libraries for image processing
        .package(url: "https://github.com/the-swift-collective/libwebp.git", from: "1.4.1"),
        .package(url: "https://github.com/the-swift-collective/libpng.git", from: "1.6.45"),
    ]
)
