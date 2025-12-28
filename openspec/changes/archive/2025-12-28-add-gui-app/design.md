# Design: ExFig Studio GUI Application

## Context

ExFig is a CLI tool for exporting Figma design assets to iOS, Android, Flutter, and Web. The configuration is defined in YAML files documented in a 1252-line CONFIG.md. Users want a visual interface that:

- Simplifies configuration creation
- Provides asset preview before export
- Allows selective export
- Shows real-time progress

**Stakeholders**: Developers using ExFig, design system maintainers

**Constraints**:

- Must share code with CLI (embedded library)
- macOS 15+ (Sequoia) minimum
- Distribution via Homebrew Cask (no App Store sandboxing)

## Goals / Non-Goals

**Goals**:

- Visual config editor replacing manual YAML editing
- Asset preview with thumbnails from Figma
- Interactive asset selection before export
- Progress visualization during export
- Export history with quick re-run
- Both OAuth and Personal Token authentication

**Non-Goals**:

- Cross-platform (Windows/Linux) — macOS only
- Figma plugin — standalone app only
- Real-time sync with Figma — manual refresh only
- App Store distribution — Homebrew Cask only

## Decisions

### Decision 1: Module Extraction (ExFigKit)

**What**: Extract reusable code from `ExFig` CLI into new `ExFigKit` library module.

**Why**: CLI and GUI need to share loaders, processors, and exporters. Currently these are mixed with CLI-specific code (TerminalUI, ArgumentParser).

**Structure**:

```
Sources/ExFigKit/
├── Config/          # Params.swift (config model)
├── Loaders/         # ColorsLoader, IconsLoader, ImagesLoader, etc.
├── Output/          # FileWriter, converters (WebP, HEIC, PNG)
├── Cache/           # VersionTracking, GranularCache
└── Progress/        # ProgressReporter protocol
```

**Alternatives considered**:

- Keep code in ExFig, use conditionally — Rejected: violates separation of concerns
- Create separate package — Rejected: unnecessary complexity for monorepo

### Decision 2: Progress Reporting Protocol

**What**: Replace TerminalUI with protocol-based progress reporting.

**Why**: CLI uses terminal spinners/progress bars. GUI needs different visualization. Protocol allows both.

**Design**:

```swift
public protocol ProgressReporter: Sendable {
    func reportProgress(_ progress: ExportProgress) async
    func reportWarning(_ warning: ExportWarning) async
    func reportError(_ error: Error) async
}

public struct ExportProgress: Sendable {
    public enum Phase {
        case fetching(current: Int, total: Int)
        case processing
        case downloading(current: Int, total: Int)
        case converting
        case writing
        case completed(count: Int)
    }
    public let assetType: String
    public let phase: Phase
    public let message: String
}
```

**CLI implementation**: `TerminalProgressReporter` wrapping TerminalUI
**GUI implementation**: `GUIProgressReporter` updating @Observable state

### Decision 3: OAuth PKCE Flow

**What**: Implement OAuth 2.0 with PKCE for Figma authentication.

**Why**: Personal Access Tokens require manual copy-paste from Figma settings. OAuth provides seamless login experience.

**Flow**:

1. Generate code verifier + challenge (S256)
2. Open Figma OAuth URL in default browser
3. Handle callback via custom URL scheme `exfig://oauth/callback`
4. Exchange code for token
5. Store tokens in Keychain
6. Refresh when expired

**Alternatives considered**:

- Embedded WebView — Works but less native feel
- Local HTTP server callback — More complex, port conflicts

### Decision 4: SwiftUI with @Observable

**What**: Use SwiftUI with @Observable macro (macOS 15+).

**Why**: Modern observation is simpler than @ObservableObject, better performance, cleaner code.

**Architecture**: MVVM

- **Views**: SwiftUI declarative UI
- **ViewModels**: @Observable classes with business logic
- **Services**: Actors for async operations (FigmaService, ExportService)

### Decision 5: Monorepo Structure with Tuist

**What**: Add GUI app to existing ExFig repository using Tuist for project generation.

**Why**:

- Shared codebase, single source of truth
- Tuist generates .xcodeproj from Swift manifests (no manual Xcode project maintenance)
- Consistent tooling with CLI (both use mise)
- Workspace combines CLI package + GUI app

**Structure**:

```
ExFig/
├── Package.swift           # CLI + ExFigKit (SPM)
├── mise.toml               # Tools: swift, tuist, swiftformat, etc.
├── Tuist/
│   ├── Config.swift        # Tuist global config
│   └── Package.swift       # External dependencies for app
├── Workspace.swift         # Workspace: CLI + App
├── Projects/
│   └── ExFigStudio/
│       ├── Project.swift   # App target definition
│       └── Sources/
│           ├── App/
│           ├── Views/
│           ├── ViewModels/
│           └── Services/
├── Sources/                # CLI + library modules
└── .gitignore              # *.xcodeproj, *.xcworkspace
```

**Tuist manifest example** (`Projects/ExFigStudio/Project.swift`):

```swift
import ProjectDescription

let project = Project(
    name: "ExFigStudio",
    targets: [
        .target(
            name: "ExFigStudio",
            destinations: .macOS,
            product: .app,
            bundleId: "io.exfig.studio",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleURLTypes": [
                    ["CFBundleURLSchemes": ["exfig"]]
                ]
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .external(name: "ExFigKit"),
                .external(name: "FigmaAPI"),
            ]
        ),
        .target(
            name: "ExFigStudioTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "io.exfig.studio.tests",
            sources: ["Tests/**"],
            dependencies: [.target(name: "ExFigStudio")]
        )
    ]
)
```

### Decision 5a: mise for GUI App

**What**: Use mise (same as CLI) for managing Tuist and other tools.

**Why**: Consistent developer experience, self-contained `./bin/mise`, no global installs.

**mise.toml additions**:

```toml
[tools]
tuist = "4.40.0"  # Xcode project generation

[tasks."app:generate"]
description = "Generate Xcode project with Tuist"
run = "tuist generate"

[tasks."app:build"]
description = "Build ExFig Studio app"
run = "tuist build ExFigStudio"

[tasks."app:test"]
description = "Run ExFig Studio tests"
run = "tuist test ExFigStudio"

[tasks."app:open"]
description = "Open ExFig Studio in Xcode"
run = "tuist generate && open ExFig.xcworkspace"
```

### Decision 6: Asset Preview via Figma Image API

**What**: Load thumbnails using Figma's GET /images endpoint.

**Why**: Components need visual preview. Figma provides image export at various scales.

**Implementation**:

- Request scale=0.5 for thumbnails (smaller files)
- Cache with NSCache (memory) + disk cache
- Lazy loading in grid view
- Placeholder while loading

### Decision 7: Homebrew Cask Distribution

**What**: Distribute as .dmg via Homebrew Cask.

**Why**: Target audience (developers) already uses Homebrew. No App Store review delays.

**Requirements**:

- Developer ID code signing
- Notarization
- Stable GitHub Releases URL

## Risks / Trade-offs

| Risk                           | Mitigation                                             |
| ------------------------------ | ------------------------------------------------------ |
| ExFigKit extraction breaks CLI | Comprehensive tests before/after, gradual migration    |
| OAuth token security           | Keychain storage, short token lifetime, refresh tokens |
| Large refactor scope           | Phase-based implementation, feature flags              |
| macOS 15 only limits users     | Most developers update quickly, can backport if needed |

## Migration Plan

1. **Phase 1**: Extract ExFigKit without changing behavior. CLI continues working.
2. **Phase 2**: Add OAuth to FigmaAPI. CLI still uses Personal Token.
3. **Phase 3+**: Build GUI incrementally. No migration for users — new feature.

**Rollback**: Each phase is independent. Can ship CLI without GUI if needed.

## Open Questions

1. ~~App name?~~ → **ExFig Studio**
2. ~~Minimum macOS version?~~ → **macOS 15 Sequoia**
3. ~~Start with extraction or GUI skeleton?~~ → **Extraction first (Phase 1)**
