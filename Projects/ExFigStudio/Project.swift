import ProjectDescription

// MARK: - Schemes

let schemes: [Scheme] = [
    .scheme(
        name: "ExFigStudio",
        shared: true,
        buildAction: .buildAction(targets: ["ExFigStudio"]),
        testAction: .targets(
            ["ExFigStudioTests"],
            configuration: .debug,
            options: .options(coverage: true)
        ),
        runAction: .runAction(executable: "ExFigStudio")
    ),
    .scheme(
        name: "ExFigStudioTests",
        shared: true,
        buildAction: .buildAction(targets: ["ExFigStudio", "ExFigStudioTests"]),
        testAction: .targets(
            ["ExFigStudioTests"],
            configuration: .debug,
            options: .options(coverage: true)
        )
    ),
    .scheme(
        name: "ExFigStudioUITests",
        shared: true,
        buildAction: .buildAction(targets: ["ExFigStudio", "ExFigStudioUITests"]),
        testAction: .targets(
            ["ExFigStudioUITests"],
            configuration: .debug,
            options: .options(coverage: true)
        )
    ),
]

// MARK: - Project Definition

let project = Project(
    name: "ExFigStudio",
    organizationName: "ExFig",
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
        ],
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release"),
        ]
    ),
    targets: [
        // MARK: - ExFigCore (shared domain models)

        .target(
            name: "ExFigCore",
            destinations: .macOS,
            product: .framework,
            bundleId: "io.exfig.core",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .default,
            sources: .sourceFilesList(globs: [
                .glob(.relativeToRoot("Sources/ExFigCore/**/*.swift")),
            ]),
            dependencies: []
        ),

        // MARK: - FigmaAPI (API client)

        .target(
            name: "FigmaAPI",
            destinations: .macOS,
            product: .framework,
            bundleId: "io.exfig.figmaapi",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .default,
            sources: .sourceFilesList(globs: [
                .glob(.relativeToRoot("Sources/FigmaAPI/**/*.swift")),
            ]),
            dependencies: [
                .external(name: "Crypto"),
            ]
        ),

        // MARK: - ExFigKit (shared library for CLI and GUI)

        .target(
            name: "ExFigKit",
            destinations: .macOS,
            product: .framework,
            bundleId: "io.exfig.kit",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .default,
            sources: .sourceFilesList(globs: [
                .glob(.relativeToRoot("Sources/ExFigKit/**/*.swift")),
            ]),
            dependencies: [
                .target(name: "FigmaAPI"),
                .target(name: "ExFigCore"),
                .external(name: "Yams"),
                .external(name: "Logging"),
            ]
        ),

        // MARK: - SVGKit (SVG parsing and code generation)

        .target(
            name: "SVGKit",
            destinations: .macOS,
            product: .framework,
            bundleId: "io.exfig.svgkit",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .default,
            sources: .sourceFilesList(globs: [
                .glob(.relativeToRoot("Sources/SVGKit/**/*.swift")),
            ]),
            dependencies: [
                .external(name: "Logging"),
                .external(name: "Resvg"),
            ]
        ),

        // MARK: - XcodeExport (iOS/macOS export)

        .target(
            name: "XcodeExport",
            destinations: .macOS,
            product: .framework,
            bundleId: "io.exfig.xcodeexport",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .default,
            sources: .sourceFilesList(globs: [
                .glob(.relativeToRoot("Sources/XcodeExport/**/*.swift")),
            ]),
            resources: .resources([
                .folderReference(path: .relativeToRoot("Sources/XcodeExport/Resources")),
            ]),
            dependencies: [
                .target(name: "ExFigCore"),
                .external(name: "Stencil"),
                .external(name: "StencilSwiftKit"),
            ]
        ),

        // MARK: - AndroidExport (Android export)

        .target(
            name: "AndroidExport",
            destinations: .macOS,
            product: .framework,
            bundleId: "io.exfig.androidexport",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .default,
            sources: .sourceFilesList(globs: [
                .glob(.relativeToRoot("Sources/AndroidExport/**/*.swift")),
            ]),
            resources: .resources([
                .folderReference(path: .relativeToRoot("Sources/AndroidExport/Resources")),
            ]),
            dependencies: [
                .target(name: "ExFigCore"),
                .target(name: "SVGKit"),
                .external(name: "Stencil"),
                .external(name: "StencilSwiftKit"),
                .external(name: "OrderedCollections"),
            ]
        ),

        // MARK: - FlutterExport (Flutter export)

        .target(
            name: "FlutterExport",
            destinations: .macOS,
            product: .framework,
            bundleId: "io.exfig.flutterexport",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .default,
            sources: .sourceFilesList(globs: [
                .glob(.relativeToRoot("Sources/FlutterExport/**/*.swift")),
            ]),
            resources: .resources([
                .folderReference(path: .relativeToRoot("Sources/FlutterExport/Resources")),
            ]),
            dependencies: [
                .target(name: "ExFigCore"),
                .external(name: "Stencil"),
                .external(name: "StencilSwiftKit"),
            ]
        ),

        // MARK: - WebExport (Web/React export)

        .target(
            name: "WebExport",
            destinations: .macOS,
            product: .framework,
            bundleId: "io.exfig.webexport",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .default,
            sources: .sourceFilesList(globs: [
                .glob(.relativeToRoot("Sources/WebExport/**/*.swift")),
            ]),
            resources: .resources([
                .folderReference(path: .relativeToRoot("Sources/WebExport/Resources")),
            ]),
            dependencies: [
                .target(name: "ExFigCore"),
                .external(name: "Stencil"),
                .external(name: "StencilSwiftKit"),
            ]
        ),

        // MARK: - ExFig Studio App

        .target(
            name: "ExFigStudio",
            destinations: .macOS,
            product: .app,
            bundleId: "io.exfig.studio",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "ExFig Studio",
                "CFBundleShortVersionString": "1.0.0",
                "CFBundleVersion": "1",
                "LSMinimumSystemVersion": "15.0",
                "NSHumanReadableCopyright": "Copyright 2024 ExFig. All rights reserved.",
                // URL scheme for OAuth callback
                "CFBundleURLTypes": [
                    [
                        "CFBundleURLName": "OAuth Callback",
                        "CFBundleURLSchemes": ["exfig"],
                    ],
                ],
                // App category
                "LSApplicationCategoryType": "public.app-category.developer-tools",
                // Sandbox entitlements (non-sandboxed for file system access)
                "NSSupportsAutomaticTermination": true,
                "NSSupportsSuddenTermination": false,
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .target(name: "ExFigKit"),
                .target(name: "FigmaAPI"),
                .target(name: "ExFigCore"),
                .target(name: "XcodeExport"),
                .target(name: "AndroidExport"),
                .target(name: "FlutterExport"),
                .target(name: "WebExport"),
                .target(name: "SVGKit"),
                .external(name: "WebP"),
                .external(name: "LibPNG"),
            ]
        ),

        // MARK: - Unit Tests

        .target(
            name: "ExFigStudioTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "io.exfig.studio.tests",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "ExFigStudio"),
            ]
        ),

        // MARK: - UI Tests

        .target(
            name: "ExFigStudioUITests",
            destinations: .macOS,
            product: .uiTests,
            bundleId: "io.exfig.studio.uitests",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .default,
            sources: ["UITests/**"],
            dependencies: [
                .target(name: "ExFigStudio"),
            ]
        ),
    ],
    schemes: schemes
)
