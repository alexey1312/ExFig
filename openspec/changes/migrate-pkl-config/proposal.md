# Change: ExFig v2.0 — PKL Configuration + Plugin Architecture

## Why

Current architecture has two major problems:

1. **Configuration**: YAML lacks native support for configuration inheritance and composition. Teams maintain
   multiple config files with duplicated settings, and there's no way to share base configurations across projects.

2. **Code structure**: ExFig is a monolith with 1141-line `Params.swift` containing ~63% duplicated code across
   platforms. Export commands duplicate 70% of their logic. Adding a new platform requires editing 5+ files.

PKL (Programmable, Scalable, Safe) provides native `amends`/`extends` for config inheritance, built-in type validation,
and support for remote schema imports — solving configuration problems at the language level.

Plugin architecture isolates each platform into an independent module with unified `PlatformPlugin` and `AssetExporter`
protocols — making the codebase maintainable and extensible.

## What Changes

### PKL Configuration

- **BREAKING**: Remove YAML configuration support completely (no backward compatibility)
- **BREAKING**: Remove Yams dependency from Package.swift
- Add PKL configuration schema files (`ExFig.pkl`, `iOS.pkl`, `Android.pkl`, etc.)
- Add PKL evaluator infrastructure (`PKLLocator`, `PKLEvaluator`)
- Update `ExFigOptions` to use PKL instead of YAML
- Update `ConfigDiscovery` to find `.pkl` files instead of `.yaml`
- Add `pkl` to mise.toml for tooling
- Create comprehensive PKL documentation and migration guide

### Plugin Architecture

- **BREAKING**: Restructure ExFig module into plugin-based architecture
- Create `ExFigConfig` module for PKL evaluation and shared config types
- Create `ExFig-iOS`, `ExFig-Android`, `ExFig-Flutter`, `ExFig-Web` plugin modules
- Introduce core protocols in ExFigCore:
  - `PlatformPlugin` — platform registration and exporter discovery
  - `AssetExporter` — base protocol for all asset exporters
  - `ColorsExporter` + `ColorsExportContext` — colors export with load/process/export cycle
  - `IconsExporter` + `IconsExportContext` — icons export (SVG/PDF download, vector conversion)
  - `ImagesExporter` + `ImagesExportContext` — images export (PNG/HEIC rendering, scaling)
  - `TypographyExporter` + `TypographyExportContext` — typography export (font styles)
  - `PluginRegistry` — plugin coordination and routing
- Migrate platform-specific code from ExFig to respective plugins
- Remove monolithic `Params.swift` (1141 lines → ~200 core + 4×100 plugins)
- Rename ExFig executable target to ExFigCLI

## Impact

- Affected specs: `configuration` (enhanced), `plugin-architecture` (new spec)
- Affected code:
  - `Package.swift` — add 5 new targets, rename ExFig → ExFigCLI, remove Yams
  - `Sources/ExFig/Input/Params.swift` — DELETE (replaced by plugin configs)
  - `Sources/ExFig/Input/ExFigOptions.swift` — refactor to use PKL
  - `Sources/ExFig/Batch/ConfigDiscovery.swift` — `.pkl` file discovery
  - `Sources/ExFig/Context/` — NEW: ColorsExportContextImpl, IconsExportContextImpl, ImagesExportContextImpl
  - `Sources/ExFigCore/Protocol/` — NEW: PlatformPlugin, AssetExporter, AssetType, ExportContext
  - `Sources/ExFigCore/Protocol/` — NEW: ColorsExporter, IconsExporter, ImagesExporter, TypographyExporter
  - `Sources/ExFigCore/Plugin/` — NEW: PluginRegistry
  - `Sources/ExFigConfig/` — NEW module for PKL and shared config
  - `Sources/ExFig-iOS/` — NEW plugin module (iOSColorsExporter, iOSIconsExporter, iOSImagesExporter)
  - `Sources/ExFig-Android/` — NEW plugin module (AndroidColorsExporter, AndroidIconsExporter, etc.)
  - `Sources/ExFig-Flutter/` — NEW plugin module (FlutterColorsExporter, FlutterIconsExporter, etc.)
  - `Sources/ExFig-Web/` — NEW plugin module (WebColorsExporter, WebIconsExporter, etc.)
  - `mise.toml` — add pkl tool
  - `CLAUDE.md` — update configuration examples and architecture docs

## Risks

- PKL CLI must be installed separately via `mise use pkl`
- Users must manually rewrite configs (no auto-migration tool)
- PKL has smaller community than YAML
- Regressions during large-scale refactoring to plugins
- Increased build complexity with more targets
- This is a major breaking change (v2.0)

## Mitigations

- Clear migration guide with YAML-to-PKL syntax mapping
- Typed schemas catch configuration errors at evaluation time
- PKL's `amends` enables gradual adoption with shared base configs
- Comprehensive test coverage before refactoring; feature flag for gradual rollout
- Plugin modules are independent → parallel builds offset complexity
- Major version bump clearly signals breaking changes
