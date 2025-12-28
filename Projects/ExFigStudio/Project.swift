import ProjectDescription

let project = Project(
    name: "ExFigStudio",
    organizationName: "ExFig",
    targets: [
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
                .external(name: "ExFigKit"),
                .external(name: "FigmaAPI"),
                .external(name: "ExFigCore"),
            ]
        ),
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
    ]
)
