import ProjectDescription

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
            dependencies: []
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
    ]
)
