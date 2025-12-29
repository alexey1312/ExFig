# Project Structure

## SPM Modules

Eight modules in `Sources/`:

| Module          | Purpose                                                            |
| --------------- | ------------------------------------------------------------------ |
| `ExFig`         | CLI commands, loaders, file I/O, terminal UI                       |
| `ExFigKit`      | Shared library: config models (Params), errors, progress reporting |
| `ExFigCore`     | Domain models (Color, Image, TextStyle), processors                |
| `FigmaAPI`      | Figma REST API client, endpoints, OAuth 2.0 authentication         |
| `XcodeExport`   | iOS export (.xcassets, Swift extensions)                           |
| `AndroidExport` | Android export (XML resources, Compose, Vector Drawables)          |
| `FlutterExport` | Flutter export (Dart code, SVG/PNG assets)                         |
| `SVGKit`        | SVG parsing, ImageVector/VectorDrawable generation                 |

## Key Directories

```
Sources/ExFigKit/
├── Config/          # Params.swift - YAML config models (public, Sendable)
├── Progress/        # ProgressReporter protocol for CLI/GUI abstraction
├── ExFigKit.swift   # Module entry point
└── ExFigKitError.swift # Error types (aliased as ExFigError)

Sources/FigmaAPI/
├── OAuth/           # OAuthClient.swift, KeychainStorage.swift (PKCE + secure storage)
├── Client/          # FigmaClient, RateLimitedClient, RetryPolicy
└── Endpoint/        # API endpoint definitions

Sources/ExFig/
├── Subcommands/     # CLI commands (ExportColors, ExportIcons, DownloadImages, etc.)
│   └── Export/      # Platform-specific export logic (iOSIconsExport, AndroidImagesExport, etc.)
├── Loaders/         # Figma data loaders (ColorsLoader, ImagesLoader, etc.)
├── Input/           # Config & CLI options (ExFigOptions, DownloadOptions, etc.)
├── Output/          # File writers, converters, factories (WebpConverterFactory, HeicConverterFactory)
├── TerminalUI/      # Progress bars, spinners, logging, output coordination
├── Cache/           # Version tracking, granular cache (GranularCacheHelper, GranularCacheManager)
├── Pipeline/        # Cross-config download pipelining (SharedDownloadQueue)
├── Batch/           # Batch processing (executor, runner, checkpoint)
└── Shared/          # Cross-cutting helpers (PlatformExportResult, HashMerger, EntryProcessor)

Projects/ExFigStudio/
├── Sources/
│   ├── Views/       # SwiftUI views (MainView, ConfigView, ExportView, etc.)
│   ├── ViewModels/  # Observable ViewModels (AuthViewModel, ExportViewModel, etc.)
│   └── App/         # App entry point, AppDelegate
├── Resources/       # Assets.xcassets, entitlements
└── Project.swift    # Tuist project definition

Sources/*/Resources/ # Stencil templates for code generation
Tests/               # Test targets mirror source structure
```

## Data Flow

- **CLI**: Config parsing → FigmaAPI fetch → ExFigCore processing → Platform export → File write
- **GUI**: OAuth login → Visual config → FigmaAPI fetch → ExFigCore processing → Export with progress
