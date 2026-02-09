# Design: ExFig v2.0 Architecture

## Context

ExFig has two architectural problems:

1. **Configuration**: YAML via Yams library lacks config inheritance. Users request multi-project setups
   with shared base configs, but YAML has no native support. Options considered: TOML (no inheritance),
   JSON (no comments), PKL (native inheritance via `amends`).

2. **Code structure**: ExFig is a monolith. `Params.swift` has 1141 lines with ~63% duplication across platforms.
   Export commands (`iOSColorsExport.swift`, `AndroidColorsExport.swift`, etc.) duplicate 70% of their logic.
   Adding a new platform requires editing 5+ files in the ExFig module.

## Goals / Non-Goals

**Goals:**

- Native configuration inheritance and composition (PKL)
- Type-safe configuration with validation at parse time
- Remote schema imports for team-wide consistency
- Plugin-based architecture with clear separation of concerns
- Unified `PlatformPlugin` and `AssetExporter` protocols
- Independent platform modules for parallel builds and testing
- Eliminate code duplication via shared `SourceConfig` type

**Non-Goals:**

- YAML backward compatibility (clean break)
- Bundling PKL CLI with ExFig releases
- Auto-migration tool from YAML to PKL
- Runtime plugin loading (compile-time linking only)

## Decisions

### 1. PKL CLI Distribution via mise

**Decision:** Users install PKL via `mise use pkl`, not bundled with ExFig.

**Rationale:**

- Follows hk pattern (`mise use hk pkl`)
- Avoids bloating release archives with 10MB binaries per platform
- mise handles version management and PATH setup
- Users already use mise for ExFig development

**Implementation:**

```swift
struct PKLLocator {
    func findPKL() throws -> URL {
        // 1. mise shim: ~/.local/share/mise/shims/pkl
        // 2. PATH fallback
        // 3. Error with install instructions
    }
}
```

### 2. PKL → JSON → Params Pipeline

**Decision:** PKL evaluates to JSON, then JSONDecoder creates `Params`.

**Rationale:**

- No changes to existing 1142-line `Params.swift`
- PKL has native `--format json` output
- JSONDecoder is built-in, no new dependencies
- Type validation happens in PKL schemas before reaching Swift

**Data flow:**

```
exfig.pkl → pkl eval --format json → String → JSONDecoder → Params
```

### 3. Schema Publishing via GitHub Releases

**Decision:** PKL schemas published as separate GitHub release artifacts.

**URL format:**

```
package://github.com/niceplaces/exfig/releases/download/schemas-v2.0.0/exfig-schemas@2.0.0#/ExFig.pkl
```

**Rationale:**

- Schemas can version independently from CLI
- Standard PKL package resolution
- GitHub handles hosting and versioning
- Users pin schema version in `amends` declaration

### 4. Complete YAML Removal

**Decision:** Remove YAML support entirely, no deprecation period.

**Rationale:**

- Clean codebase without dual-format complexity
- Forces adoption of superior tooling
- Simplifies testing and maintenance
- ExFig 2.0 is a major version (breaking changes expected)

## Architecture

### New Files

```
Sources/ExFig/
├── PKL/
│   ├── PKLError.swift         # NotFound, EvaluationFailed
│   ├── PKLLocator.swift       # Find pkl via mise/PATH
│   └── PKLEvaluator.swift     # Subprocess wrapper
└── Resources/
    └── Schemas/
        ├── PklProject         # Package manifest
        ├── ExFig.pkl          # Main schema (abstract)
        ├── Figma.pkl          # Figma settings
        ├── Common.pkl         # Shared settings
        ├── iOS.pkl            # iOS platform
        ├── Android.pkl        # Android platform
        ├── Flutter.pkl        # Flutter platform
        └── Web.pkl            # Web platform
```

### PKLEvaluator Interface

```swift
struct PKLEvaluator {
    let pklPath: URL

    func evaluate(configPath: URL) async throws -> Params {
        // 1. Run: pkl eval --format json <configPath>
        // 2. Capture stdout
        // 3. JSONDecoder.decode(Params.self, from: jsonData)
    }
}
```

### PKL Schema Structure

```pkl
// ExFig.pkl
abstract module ExFig

import "Figma.pkl"
import "Common.pkl"
import "iOS.pkl"
import "Android.pkl"
import "Flutter.pkl"
import "Web.pkl"

figma: Figma?
common: Common?
ios: iOS?
android: Android?
flutter: Flutter?
web: Web?
```

### 5. Plugin Architecture

**Decision:** Refactor ExFig into plugin-based architecture where each platform is an independent module.

**Rationale:**

- `Params.swift` has 1141 lines with ~63% duplication across platforms
- Export commands duplicate 70% of code (iOSColorsExport ≈ AndroidColorsExport)
- Adding new platform requires editing 5+ files
- Testing is difficult due to tight coupling

**Target architecture:**

```
ExFigCLI (executable)
├── ExFigCore (protocols: PlatformPlugin, AssetExporter)
├── ExFigConfig (PKL evaluation, SourceConfig, AssetConfiguration)
├── ExFig-iOS (iOSPlugin, iOSColorsExporter, iOSColorsEntry)
├── ExFig-Android (AndroidPlugin, AndroidColorsExporter, ...)
├── ExFig-Flutter (FlutterPlugin, ...)
└── ExFig-Web (WebPlugin, ...)
```

**Key abstractions:**

```swift
// PlatformPlugin — register platform
public protocol PlatformPlugin: Sendable {
    static var identifier: String { get }
    static var configKeys: [String] { get }  // ["ios.colors", "ios.icons", ...]
    func exporters() -> [any AssetExporter]
}

// AssetExporter — unified export interface
public protocol AssetExporter: Sendable {
    associatedtype Config: Decodable & Sendable
    associatedtype Output: Sendable

    static var assetType: AssetType { get }

    func load(config: Config, client: FigmaClient, ui: TerminalUI) async throws -> LoaderOutput
    func process(_ data: LoaderOutput, config: Config) async throws -> Output
    func export(_ output: Output, config: Config, options: ExportOptions) async throws -> ExportResult
}

// SourceConfig — shared Figma fields (defined once, used in all plugins)
public struct SourceConfig: Decodable, Sendable {
    public let tokensFileId: String?
    public let tokensCollectionName: String?
    public let lightModeName: String?
    public let darkModeName: String?
    public let lightHCModeName: String?
    public let darkHCModeName: String?
    public let primitivesModeName: String?
    public let figmaFrameName: String?
    public let sourceFormat: SourceFormat?
    public let nameValidateRegexp: String?
    public let nameReplaceRegexp: String?
}

// AssetConfiguration — generic single/multiple (replaces 12 enums)
public enum AssetConfiguration<Entry: Decodable & Sendable>: Decodable, Sendable {
    case single(Entry)
    case multiple([Entry])

    public var entries: [Entry] {
        switch self {
        case .single(let entry): [entry]
        case .multiple(let entries): entries
        }
    }
}
```

**Benefits:**

| Metric            | Before        | After                             |
| ----------------- | ------------- | --------------------------------- |
| Params.swift      | 1141 lines    | ~200 lines (core) + 4×100 plugins |
| Code duplication  | ~63%          | ~10%                              |
| Add new platform  | Edit 5+ files | Create 1 module                   |
| Build parallelism | Limited       | Full (plugins independent)        |
| Testing isolation | Difficult     | Plugin tests run independently    |

### 6. Data Flow with Plugins

```
exfig.pkl
    │
    ▼ PKLEvaluator (pkl eval --format json)
    │
    ▼ JSON string
    │
    ▼ PluginRegistry.decode(json, for: platform)
    │
    ├──▶ iOSPlugin.decode(json["ios"])
    │        → iOSColorsConfiguration
    │        → iOSIconsConfiguration
    │        → ...
    │
    ├──▶ AndroidPlugin.decode(json["android"])
    │        → AndroidColorsConfiguration
    │        → ...
    │
    └──▶ ... (Flutter, Web)
    │
    ▼ ExportCommand.run()
    │
    ▼ for plugin in enabledPlugins {
    │     for exporter in plugin.exporters() {
    │         let data = try await exporter.load(config, client, ui)
    │         let output = try await exporter.process(data, config)
    │         try await exporter.export(output, config, options)
    │     }
    │ }
```

## Risks / Trade-offs

| Risk                        | Mitigation                                     |
| --------------------------- | ---------------------------------------------- |
| PKL not installed           | Clear error message with `mise use pkl`        |
| Slower startup (subprocess) | PKL eval is fast (~50ms for typical configs)   |
| Users unfamiliar with PKL   | Comprehensive docs + migration guide           |
| Schema version mismatch     | Explicit version in `amends` URL               |
| Regressions during refactor | Tests first, then code; feature flag if needed |
| Increased build targets     | Independent modules → parallel builds          |
| API breaking changes        | v2.0 major version signals breaking changes    |

## Migration Plan

### Phase 1: PKL Infrastructure

1. Create PKL schemas matching current `Params.swift` structure
2. Implement `PKLLocator` and `PKLEvaluator`
3. Update `ExFigOptions` to use PKL
4. Update `ConfigDiscovery` for `.pkl` files
5. Remove Yams from `Package.swift`

### Phase 2: Core Protocols

6. Create `PlatformPlugin` protocol in ExFigCore
7. Create `AssetExporter` protocol in ExFigCore
8. Create `AssetType` enum and `ExportResult` type

### Phase 3: Config Module

9. Create `ExFigConfig` target in Package.swift
10. Move PKL infrastructure to ExFigConfig
11. Create `SourceConfig` with shared Figma fields
12. Create `AssetConfiguration<Entry>` generic type

### Phase 4: Platform Plugins

13. Create `ExFig-iOS` plugin module (reference implementation)
14. Create `ExFig-Android` plugin module
15. Create `ExFig-Flutter` plugin module
16. Create `ExFig-Web` plugin module

### Phase 5: CLI Refactoring

17. Create `PluginRegistry` for plugin registration
18. Rename ExFig → ExFigCLI
19. Refactor export commands to use PluginRegistry
20. Delete old `Params.swift` and export files

### Phase 6: Documentation and CI

21. Update all documentation
22. Publish schemas to GitHub releases
23. Release ExFig 2.0

**Rollback:** Not applicable (major version with breaking changes).

## Open Questions

None — all decisions made.
