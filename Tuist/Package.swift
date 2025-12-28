// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            // Use dynamic frameworks for SwiftUI app
            "Yams": .framework,
            "Logging": .framework,
        ]
    )
#endif

// Third-party dependencies for ExFig Studio
// Note: ExFigKit, FigmaAPI, ExFigCore are defined as native Tuist targets
// to avoid issues with Tuist's handling of local SPM packages with binary dependencies
let package = Package(
    name: "ExFigDependencies",
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.3.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.0"),
    ]
)
