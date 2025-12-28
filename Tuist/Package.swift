// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            // Use dynamic frameworks for shared code
            "ExFigKit": .framework,
            "FigmaAPI": .framework,
            "ExFigCore": .framework,
        ]
    )
#endif

let package = Package(
    name: "ExFigDependencies",
    dependencies: [
        // Reference the local SPM package for ExFigKit and FigmaAPI
        .package(path: ".."),
    ]
)
