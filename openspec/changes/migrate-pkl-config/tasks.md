# ExFig v2.0 Tasks

## Legend

| Symbol | Meaning                                                        |
| ------ | -------------------------------------------------------------- |
| 🔀     | **PARALLEL** — tasks can run concurrently via subagents        |
| ⏳     | **SEQUENTIAL** — must complete before next phase               |
| 🧪     | **TDD** — write tests first, then implementation               |
| 📦     | **SUBAGENT** — isolated unit of work for delegation            |
| ⚠️      | **MIGRATION** — refactor existing code, preserve test coverage |

## Dependency Graph

```
Phase 1 (PKL Schemas)
    ↓
Phase 2 (PKL Infrastructure) ──┬── Phase 3 (Core Protocols)
    ↓                          ↓
Phase 4 (ExFig Integration) ←─ Phase 5 (ExFigConfig Module)
    ↓                          ↓
Phase 6 (Dependency Cleanup)   Phase 7 (Platform Plugins) 🔀 [4 parallel]
    ↓                          ↓
Phase 8 (Test Updates)         Phase 9 (CLI Refactoring)
    ↓                          ↓
Phase 10 (Documentation) ──────┴── Phase 11 (CI/CD)
    ↓
Phase 12 (Final Verification)
```

---

## Phase 1: PKL Schemas ⏳

> **No parallelism** — schemas depend on each other (imports)

- [x] 1.1 Create `Resources/Schemas/PklProject` manifest
- [x] 1.2 Create `ExFig.pkl` main abstract schema
- [x] 1.3 Create `Figma.pkl` with timeout, fileIds
- [x] 1.4 Create `Common.pkl` with cache, variablesColors, icons, images, typography
- [x] 1.5 Create `iOS.pkl` with colors, icons, images, typography configurations
- [x] 1.6 Create `Android.pkl` with colors, icons, images, typography configurations
- [x] 1.7 Create `Flutter.pkl` with colors, icons, images configurations
- [x] 1.8 Create `Web.pkl` with colors, icons, images configurations
- [x] 1.9 Validate schemas compile: `pkl eval ExFig.pkl`

**Completion criteria:** `pkl eval Resources/Schemas/ExFig.pkl` succeeds

---

## Phase 2: PKL Infrastructure 🧪 📦

> **SUBAGENT:** Single agent, TDD approach
> **Depends on:** Phase 1

### 2.1 Tests First

- [x] 2.1.1 Create `Tests/ExFigTests/PKL/PKLLocatorTests.swift`
  - Test: finds pkl via mise installs, Homebrew, or PATH
  - Test: found pkl is executable
  - Test: throws NotFound when missing
- [x] 2.1.2 Create `Tests/ExFigTests/PKL/PKLEvaluatorTests.swift`
  - Test: evaluates valid PKL to JSON
  - Test: throws EvaluationFailed on syntax error
  - Test: includes line/column in error message

### 2.2 Implementation

- [x] 2.2.1 Create `PKL/PKLError.swift` with NotFound, EvaluationFailed cases
- [x] 2.2.2 Create `PKL/PKLLocator.swift` with mise installs, Homebrew, and PATH detection
- [x] 2.2.3 Create `PKL/PKLEvaluator.swift` with subprocess wrapper
- [x] 2.2.4 `pkl` already in `mise.toml` tools section
- [x] 2.2.5 Run tests: `swift test --filter PKL` — 9 tests pass

**Completion criteria:** All PKL tests pass

---

## Phase 3: Core Protocols 🧪 📦

> **SUBAGENT:** Single agent, TDD approach
> **Parallel with:** Phase 2 (no dependencies)

### 3.1 Tests First

- [x] 3.1.1 Create `Tests/ExFigCoreTests/Protocol/PlatformPluginTests.swift`
  - Test: plugin provides identifier
  - Test: plugin provides configKeys
  - Test: plugin returns exporters
- [x] 3.1.2 Create `Tests/ExFigCoreTests/Protocol/AssetExporterTests.swift`
  - Test: mock exporter load/process/export cycle
  - Test: exporter provides assetType

### 3.2 Implementation

- [x] 3.2.1 Create `Sources/ExFigCore/Protocol/AssetType.swift` (enum: colors, icons, images, typography)
- [x] 3.2.2 Create `Sources/ExFigCore/Protocol/ExportResult.swift`
- [x] 3.2.3 Create `Sources/ExFigCore/Protocol/AssetExporter.swift`
- [x] 3.2.4 Create `Sources/ExFigCore/Protocol/PlatformPlugin.swift`
- [x] 3.2.5 Run tests: `swift test --filter ExFigCoreTests` — 161 tests pass

**Completion criteria:** Protocol tests pass with mock implementations ✅

---

## Phase 4: ExFig Integration ⚠️ 📦

> **SUBAGENT:** Single agent, migration with existing test preservation
> **Depends on:** Phase 2

### 4.1 Preserve Existing Tests

- [x] 4.1.1 Run existing tests, note which use YAML: `swift test 2>&1 | grep -i yaml`
- [x] 4.1.2 Create `Tests/ExFigTests/Fixtures/exfig.pkl` equivalent to existing YAML fixture
- [x] 4.1.3 Create `Tests/ExFigTests/Fixtures/base.pkl` for inheritance tests

### 4.2 Migration (keep tests green)

- [x] 4.2.1 Update `ExFigOptions.swift` to use `PKLEvaluator`
- [x] 4.2.2 Change default config filename to `exfig.pkl`
- [x] 4.2.3 Remove YAML file detection logic
- [x] 4.2.4 Update `ConfigDiscovery.swift` to find `.pkl` files
- [x] 4.2.5 Remove Yams validation logic from `ConfigDiscovery`
- [x] 4.2.6 Update error messages to reference PKL
- [x] 4.2.7 Run full test suite: `mise run test` — 1920 tests pass

**Completion criteria:** All existing tests pass with PKL configs ✅

---

## Phase 5: ExFigConfig Module 🧪 📦

> **SUBAGENT:** Single agent, TDD approach
> **Depends on:** Phase 2, Phase 3

### 5.1 Tests First

- [x] 5.1.1 Create `Tests/ExFigConfigTests/SourceConfigTests.swift`
  - Test: decodes all Figma Variables fields
  - Test: decodes Figma Frame fields
  - Test: handles optional fields
- [x] 5.1.2 Create `Tests/ExFigConfigTests/AssetConfigurationTests.swift`
  - Test: decodes single object as `.single`
  - Test: decodes array as `.multiple`
  - Test: `.entries` returns correct array for both cases
- [x] 5.1.3 Create `Tests/ExFigConfigTests/NameProcessingConfigTests.swift`
  - Test: validates name against regexp
  - Test: applies replacement regexp

### 5.2 Implementation

- [x] 5.2.1 Create `ExFigConfig` target in `Package.swift`
- [x] 5.2.2 Move `PKLLocator`, `PKLEvaluator`, `PKLError` to `Sources/ExFigConfig/PKL/`
- [x] 5.2.3 Create `Sources/ExFigConfig/SourceConfig.swift`
- [x] 5.2.4 Create `Sources/ExFigConfig/AssetConfiguration.swift`
- [x] 5.2.5 Create `Sources/ExFigConfig/NameProcessingConfig.swift`
- [x] 5.2.6 Run tests: `swift test --filter ExFigConfigTests` — 22 tests pass

**Completion criteria:** ExFigConfig module compiles and tests pass ✅

---

## Phase 6: Dependency Cleanup ⏳

> **SEQUENTIAL** — must complete before Phase 8
> **Depends on:** Phase 4

- [x] 6.1 Remove `Yams` from `Package.swift` dependencies
- [x] 6.2 Remove `import Yams` from `ExFigOptions.swift` (already removed in Phase 4)
- [x] 6.3 Remove `import Yams` from `ConfigDiscovery.swift` (already removed in Phase 4)
- [x] 6.4 Search and remove any remaining Yams references: `grep -r "Yams" Sources/` — none found
- [x] 6.5 Verify build: `swift build` — 1920 tests pass

**Completion criteria:** Project builds without Yams dependency ✅

---

## Phase 7: Platform Plugins 🔀 🧪

> **4 PARALLEL SUBAGENTS** — each plugin is independent
> **Depends on:** Phase 3, Phase 5

### 7.1 iOS Plugin 📦 ✅

> **SUBAGENT:** ios-plugin-agent

#### Tests First

- [x] 7.1.1 Create `Tests/ExFig-iOSTests/iOSPluginTests.swift`
  - Test: identifier is "ios"
  - Test: configKeys contains expected keys
  - Test: exporters() returns 4 exporters
- [x] 7.1.2 Create `Tests/ExFig-iOSTests/iOSColorsExporterTests.swift`
  - Test: assetType is .colors
  - Test: exporter is Sendable

#### Implementation

- [x] 7.1.3 Create `ExFig-iOS` target in `Package.swift`
- [x] 7.1.4 Create `Sources/ExFig-iOS/iOSPlugin.swift`
- [x] 7.1.5 Create `Sources/ExFig-iOS/Config/iOSColorsEntry.swift`
- [x] 7.1.6 Create `Sources/ExFig-iOS/Export/iOSColorsExporter.swift` (skeleton)
- [x] 7.1.7 Migrate code from `Sources/ExFig/Subcommands/Export/iOSColorsExport.swift`
  - Created `ColorsExporter` protocol in ExFigCore
  - Created `ColorsExportContext` protocol for dependency injection
  - Created `ColorsExportContextImpl` bridging plugins to ExFig services
  - Implemented full `iOSColorsExporter.exportColors()` with load/process/export cycle
  - Added `iOSPlatformConfig` for iOS-wide settings
- [x] 7.1.8 Created stub exporters for Icons, Images, Typography
- [x] 7.1.9 Run: `swift test --filter ExFig-iOSTests` — 14 tests pass

### 7.2 Android Plugin 📦 ✅

> **SUBAGENT:** android-plugin-agent

#### Tests First

- [x] 7.2.1 Create `Tests/ExFig-AndroidTests/AndroidPluginTests.swift`
- [x] 7.2.2 Create `Tests/ExFig-AndroidTests/AndroidColorsExporterTests.swift`

#### Implementation

- [x] 7.2.3 Create `ExFig-Android` target in `Package.swift`
- [x] 7.2.4 Create `Sources/ExFig-Android/AndroidPlugin.swift`
- [x] 7.2.5 Create `Sources/ExFig-Android/Config/AndroidColorsEntry.swift`
- [x] 7.2.6 Create `Sources/ExFig-Android/Export/AndroidColorsExporter.swift` (skeleton)
- [x] 7.2.7 Migrate code from `Sources/ExFig/Subcommands/Export/AndroidColorsExport.swift`
  - Implemented full `AndroidColorsExporter.exportColors()` with XML and Kotlin generation
  - Added `AndroidPlatformConfig` for Android-wide settings
- [x] 7.2.8 Created stub exporters for Icons, Images, Typography
- [x] 7.2.9 Run: `swift test --filter ExFig-AndroidTests` — 14 tests pass

### 7.3 Flutter Plugin 📦 ✅

> **SUBAGENT:** flutter-plugin-agent

#### Tests First

- [x] 7.3.1 Create `Tests/ExFig-FlutterTests/FlutterPluginTests.swift`
- [x] 7.3.2 Create `Tests/ExFig-FlutterTests/FlutterColorsExporterTests.swift`

#### Implementation

- [x] 7.3.3 Create `ExFig-Flutter` target in `Package.swift`
- [x] 7.3.4 Create `Sources/ExFig-Flutter/FlutterPlugin.swift`
- [x] 7.3.5 Create `Sources/ExFig-Flutter/Config/FlutterColorsEntry.swift`
- [x] 7.3.6 Create `Sources/ExFig-Flutter/Export/FlutterColorsExporter.swift` (skeleton)
- [x] 7.3.7 Migrate code from `Sources/ExFig/Subcommands/Export/FlutterColorsExport.swift`
  - Implemented full `FlutterColorsExporter.exportColors()` with Dart class generation
  - Added `FlutterPlatformConfig` for Flutter-wide settings
- [x] 7.3.8 Created stub exporters for Icons, Images (no typography for Flutter)
- [x] 7.3.9 Run: `swift test --filter ExFig-FlutterTests` — 13 tests pass

### 7.4 Web Plugin 📦 ✅

> **SUBAGENT:** web-plugin-agent

#### Tests First

- [x] 7.4.1 Create `Tests/ExFig-WebTests/WebPluginTests.swift`
- [x] 7.4.2 Create `Tests/ExFig-WebTests/WebColorsExporterTests.swift`

#### Implementation

- [x] 7.4.3 Create `ExFig-Web` target in `Package.swift`
- [x] 7.4.4 Create `Sources/ExFig-Web/WebPlugin.swift`
- [x] 7.4.5 Create `Sources/ExFig-Web/Config/WebColorsEntry.swift`
- [x] 7.4.6 Create `Sources/ExFig-Web/Export/WebColorsExporter.swift` (skeleton)
- [x] 7.4.7 Migrate code from `Sources/ExFig/Subcommands/Export/WebColorsExport.swift`
  - Implemented full `WebColorsExporter.exportColors()` with CSS/TypeScript/JSON generation
  - Added `WebPlatformConfig` for Web-wide settings
- [x] 7.4.8 Created stub exporters for Icons, Images (no typography for Web)
- [x] 7.4.9 Run: `swift test --filter ExFig-WebTests` — 13 tests pass

**Completion criteria:** All 4 plugin test suites pass independently ✅

**Status:** Phase 7 complete. 62 plugin tests passing.

- ✅ All ColorsEntry types created for iOS, Android, Flutter, Web
- ✅ All ColorsExporter implementations with full load/process/export cycle
- ✅ All PlatformConfig types for platform-wide settings
- ✅ ColorsExporter protocol and ColorsExportContext in ExFigCore
- ✅ ColorsExportContextImpl bridges plugins to ExFig services

---

## Phase 7b: Icons & Images Exporters 🔀 🧪

> **4 PARALLEL SUBAGENTS** — mirrors Phase 7 structure
> **Depends on:** Phase 7

### 7b.1 Core Protocols ✅

- [x] 7b.1.1 Create `Sources/ExFigCore/Protocol/IconsExporter.swift`
  - `IconsExporter` protocol extending `AssetExporter`
  - Associated types: `Entry`, `PlatformConfig`
  - Method: `exportIcons(entries:platformConfig:context:) async throws -> Int`
- [x] 7b.1.2 Create `IconsExportContext` protocol in `ExportContext.swift`
  - Methods: `loadIcons(from:)`, `processIcons(_:platform:...)`, `downloadFiles(_:progressTitle:)`
  - Input types: `IconsSourceInput`, `IconsLoadOutput`, `IconsProcessResult`
  - Added `VectorFormat` enum and `ProgressReporter` protocol
- [x] 7b.1.3 Create `Sources/ExFigCore/Protocol/ImagesExporter.swift`
  - `ImagesExporter` protocol extending `AssetExporter`
  - Associated types: `Entry`, `PlatformConfig`
  - Method: `exportImages(entries:platformConfig:context:) async throws -> Int`
- [x] 7b.1.4 Create `ImagesExportContext` protocol in `ExportContext.swift`
  - Methods: `loadImages(from:)`, `processImages(_:platform:...)`, `downloadFiles(_:progressTitle:)`
  - Methods: `convertFormat(_:to:progressTitle:)`, `rasterizeSVGs(_:scales:to:progressTitle:)`
  - Input types: `ImagesSourceInput`, `ImagesLoadOutput`, `ImagesProcessResult`
  - Added `ImageSourceFormat`, `ImageOutputFormat` enums
- [x] 7b.1.5 Create `Sources/ExFig/Context/IconsExportContextImpl.swift`
  - Implements `IconsExportContext`
  - Uses `IconsLoader` for Figma data loading
  - Uses `PipelinedDownloader` for batch-optimized downloads
- [x] 7b.1.6 Create `Sources/ExFig/Context/ImagesExportContextImpl.swift`
  - Implements `ImagesExportContext`
  - Uses `ImagesLoader` for Figma data loading
  - Uses `HeicConverterFactory` and `WebpConverterFactory` for format conversion
  - Uses `SvgToPngConverter` for SVG rasterization

**Status:** Phase 7b.1 complete. All core protocols and context implementations created.

### 7b.2 iOS Icons & Images ✅

- [x] 7b.2.1 Create `Sources/ExFig-iOS/Config/iOSIconsEntry.swift`
- [x] 7b.2.2 Create `Sources/ExFig-iOS/Config/iOSImagesEntry.swift`
- [x] 7b.2.3 Implement `iOSIconsExporter.exportIcons()` (migrate from `iOSIconsExport.swift`)
- [x] 7b.2.4 Implement `iOSImagesExporter.exportImages()` (migrate from `iOSImagesExport.swift`)
- [x] 7b.2.5 Create tests in `Tests/ExFig-iOSTests/`

### 7b.3 Android Icons & Images ✅

- [x] 7b.3.1 Create `Sources/ExFig-Android/Config/AndroidIconsEntry.swift`
- [x] 7b.3.2 Create `Sources/ExFig-Android/Config/AndroidImagesEntry.swift`
- [x] 7b.3.3 Implement `AndroidIconsExporter.exportIcons()`
- [x] 7b.3.4 Implement `AndroidImagesExporter.exportImages()`
- [x] 7b.3.5 Create tests in `Tests/ExFig-AndroidTests/`

### 7b.4 Flutter Icons & Images ✅

- [x] 7b.4.1 Create `Sources/ExFig-Flutter/Config/FlutterIconsEntry.swift`
- [x] 7b.4.2 Create `Sources/ExFig-Flutter/Config/FlutterImagesEntry.swift`
- [x] 7b.4.3 Implement `FlutterIconsExporter.exportIcons()`
- [x] 7b.4.4 Implement `FlutterImagesExporter.exportImages()`
- [x] 7b.4.5 Create tests in `Tests/ExFig-FlutterTests/`

### 7b.5 Web Icons & Images ✅

- [x] 7b.5.1 Create `Sources/ExFig-Web/Config/WebIconsEntry.swift`
- [x] 7b.5.2 Create `Sources/ExFig-Web/Config/WebImagesEntry.swift`
- [x] 7b.5.3 Implement `WebIconsExporter.exportIcons()`
- [x] 7b.5.4 Implement `WebImagesExporter.exportImages()`
- [x] 7b.5.5 Create tests in `Tests/ExFig-WebTests/`

**Completion criteria:** All Icons/Images exporters implemented with tests ✅

**Status:** Phase 7b complete. All Icons & Images exporters implemented for all 4 platforms with full test coverage.

---

## Phase 8: Test Updates ⚠️ 📦

> **SUBAGENT:** Single agent, preserve coverage
> **Depends on:** Phase 6

- [x] 8.1 Update existing integration tests to use PKL configs — already done in Phase 4
- [x] 8.2 Remove YAML fixture files — no YAML fixtures exist (only PKL)
- [x] 8.3 Add test for PKL evaluation error handling — exists in PKLEvaluatorTests
- [x] 8.4 Add test for missing pkl CLI error — exists in PKLLocatorTests
- [x] 8.5 Run full test suite: `mise run test` — 1972 tests pass
- [x] 8.6 Verify test coverage >= previous: `mise run coverage` — 49.32% (maintained)

**Completion criteria:** All tests pass, coverage maintained ✅

---

## Phase 9: CLI Refactoring 🧪 ⚠️ 📦

> **SUBAGENT:** Single agent, TDD + migration
> **Depends on:** Phase 7 (all plugins)

### 9.1 Tests First

- [x] 9.1.1 Create `Tests/ExFigTests/Plugin/PluginRegistryTests.swift` — 18 tests pass
  - Test: registers all 4 plugins
  - Test: routes to correct plugin by config key
  - Test: returns empty for unknown config key
- [ ] 9.1.2 Create integration tests for export commands with plugins

### 9.2 Implementation

- [x] 9.2.1 Create `Sources/ExFig/Plugin/PluginRegistry.swift`
- [x] 9.2.2 Update `Package.swift` to add plugin dependencies to ExFig target
- [ ] 9.2.3 Rename target `ExFig` → `ExFigCLI` (deferred to Phase 9.3)
- [x] 9.2.4 Refactor `ExportColors` command to use `PluginRegistry`
  - Created `Sources/ExFig/Plugin/ParamsToPluginAdapter.swift` with adapters for all platforms
  - Created `Sources/ExFig/Subcommands/Export/PluginColorsExport.swift` with plugin-based export methods
  - Updated `ExportColors.performExportWithResult()` to use `*ViaPlugin` methods for multiple format
  - Legacy format continues to use old methods (deprecated, to be removed later)
  - Post-export tasks (syncCodeSyntax, Xcode project update) remain in CLI layer
- [ ] 9.2.5 Refactor `ExportIcons` command to use `PluginRegistry`
- [ ] 9.2.6 Refactor `ExportImages` command to use `PluginRegistry`
- [ ] 9.2.7 Update Batch processing for plugin system

### 9.3 Cleanup (after tests pass)

- [ ] 9.3.1 Rename target `ExFig` → `ExFigCLI` in `Package.swift`
- [ ] 9.3.2 Delete `Sources/ExFig/Input/Params.swift`
- [ ] 9.3.3 Delete old Export files (`iOSColorsExport.swift`, etc.)
- [ ] 9.3.4 Run: `mise run test`

**Status:** ExportColors refactored to use plugin architecture. 2076 tests passing.

**Completion criteria:** CLI works with plugin architecture, old code removed

---

## Phase 10: Documentation 🔀

> **2 PARALLEL SUBAGENTS**
> **Depends on:** Phase 9

### 10.1 User Documentation 📦

> **SUBAGENT:** docs-user-agent

- [ ] 10.1.1 Update `CLAUDE.md` Quick Reference with PKL commands
- [ ] 10.1.2 Update `CLAUDE.md` config examples to PKL syntax
- [ ] 10.1.3 Create `docs/PKL.md` — complete PKL configuration guide
- [ ] 10.1.4 Create `docs/MIGRATION.md` — YAML to PKL migration guide
- [ ] 10.1.5 Update `README.md` with PKL prerequisites

### 10.2 Architecture Documentation 📦

> **SUBAGENT:** docs-arch-agent

- [ ] 10.2.1 Create `docs/ARCHITECTURE.md` — plugin system overview
- [ ] 10.2.2 Update `openspec/project.md` to reference PKL instead of Yams
- [ ] 10.2.3 Document how to add new platform plugin

**Completion criteria:** All docs updated, examples work

---

## Phase 11: CI/CD 📦

> **SUBAGENT:** Single agent
> **Parallel with:** Phase 10

- [ ] 11.1 Update GitHub Actions to install pkl via mise
- [ ] 11.2 Create workflow for publishing PKL schemas on tag `schemas/v*`
- [ ] 11.3 Verify CI passes on macOS
- [ ] 11.4 Verify CI passes on Linux (Ubuntu 22.04)

**Completion criteria:** CI green on both platforms

---

## Phase 12: PKL Schema Updates ⏳

> **SEQUENTIAL** — schema changes affect all plugins
> **Depends on:** Phase 9

- [ ] 12.1 Update PKL schemas to use inheritance for SourceConfig
- [ ] 12.2 Add `source` section in each platform Entry type
- [ ] 12.3 Validate schemas compile: `pkl eval Resources/Schemas/ExFig.pkl`
- [ ] 12.4 Create example configs using new schema structure
- [ ] 12.5 Update all test fixtures to new schema

**Completion criteria:** Schemas reflect plugin architecture

---

## Phase 13: Final Verification ⏳

> **SEQUENTIAL** — full system validation
> **Depends on:** All previous phases

- [ ] 13.1 Build all targets: `swift build`
- [ ] 13.2 Each plugin builds independently:
  - `swift build --target ExFig-iOS`
  - `swift build --target ExFig-Android`
  - `swift build --target ExFig-Flutter`
  - `swift build --target ExFig-Web`
- [ ] 13.3 All tests pass: `mise run test`
- [ ] 13.4 CLI end-to-end: `exfig colors -i exfig.pkl --dry-run`
- [ ] 13.5 Batch mode: `exfig batch ./configs/ --parallel 2`
- [ ] 13.6 Test config inheritance with `amends`
- [ ] 13.7 Test error when pkl not installed
- [ ] 13.8 Benchmark build times (before/after)
- [ ] 13.9 Tag release: `git tag v2.0.0`

**Completion criteria:** ExFig v2.0 ready for release

---

## Subagent Execution Plan

```
                ┌─────────────────┐
                │  Phase 1: PKL   │
                │    Schemas      │
                └────────┬────────┘
                         │
          ┌──────────────┼──────────────┐
          ▼              │              ▼
┌─────────────────┐     │     ┌─────────────────┐
│  📦 Phase 2:    │     │     │  📦 Phase 3:    │
│  PKL Infra      │     │     │  Core Protocols │
│  (TDD)          │     │     │  (TDD)          │
└────────┬────────┘     │     └────────┬────────┘
         │              │              │
         ▼              │              ▼
┌─────────────────┐     │     ┌─────────────────┐
│  📦 Phase 4:    │     │     │  📦 Phase 5:    │
│  ExFig Integr.  │◄────┴────►│  ExFigConfig    │
│  (Migration)    │           │  (TDD)          │
└────────┬────────┘           └────────┬────────┘
         │                             │
         ▼                             │
┌─────────────────┐                    │
│  Phase 6:       │                    │
│  Yams Cleanup   │                    │
└────────┬────────┘                    │
         │                             │
         ▼                             ▼
┌─────────────────┐     ┌──────────────────────────────────┐
│  📦 Phase 8:    │     │  🔀 Phase 7: Platform Plugins    │
│  Test Updates   │     │  ┌────────┐ ┌────────┐          │
└────────┬────────┘     │  │📦 iOS  │ │📦 Andr │          │
         │              │  └────────┘ └────────┘          │
         │              │  ┌────────┐ ┌────────┐          │
         │              │  │📦 Flut │ │📦 Web  │          │
         │              │  └────────┘ └────────┘          │
         │              └──────────────┬───────────────────┘
         │                             │
         └──────────────┬──────────────┘
                        ▼
          ┌─────────────────────────┐
          │  📦 Phase 9:            │
          │  CLI Refactoring (TDD)  │
          └────────────┬────────────┘
                       │
          ┌────────────┼────────────┐
          ▼            │            ▼
┌─────────────────┐    │    ┌─────────────────┐
│  🔀 Phase 10:   │    │    │  📦 Phase 11:   │
│  Documentation  │    │    │  CI/CD          │
│  ┌────┐ ┌────┐  │    │    └────────┬────────┘
│  │User│ │Arch│  │    │             │
│  └────┘ └────┘  │    │             │
└────────┬────────┘    │             │
         │             │             │
         └─────────────┼─────────────┘
                       ▼
          ┌─────────────────────────┐
          │  Phase 12: Schema       │
          │  Updates                │
          └────────────┬────────────┘
                       ▼
          ┌─────────────────────────┐
          │  Phase 13: Final        │
          │  Verification           │
          └─────────────────────────┘
```

## TDD Checklist (for each component)

1. **Write failing test** — define expected behavior
2. **Run test** — confirm it fails for right reason
3. **Implement minimal code** — make test pass
4. **Refactor** — clean up while tests stay green
5. **Repeat** — next test case

## Migration Checklist (for refactoring)

1. **Run existing tests** — establish baseline
2. **Create equivalent fixtures** — PKL versions of YAML
3. **Update code incrementally** — keep tests passing
4. **Remove old code** — only after new code works
5. **Verify coverage** — maintain or improve
