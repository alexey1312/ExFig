# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Module Overview

ExFig-iOS is the iOS **platform plugin** — it orchestrates the full export pipeline: Figma fetch → processing → file generation → disk write. It delegates rendering to `XcodeExport` (pure transformation layer: xcassets, Swift extensions, Stencil templates) and I/O to `ExFigCore` context protocols.

This is **NOT** the rendering layer. `XcodeExport` handles `.xcassets` generation, `Contents.json`, and Swift code output. This module wires config, loads data, and writes output.

## Build & Test

```bash
./bin/mise run test:filter ExFig_iOSTests      # Plugin integration tests
./bin/mise run test:filter XcodeExportTests     # Rendering layer unit tests
./bin/mise run build                            # Full project build
```

## Architecture

### Plugin Registration

`iOSPlugin` conforms to `PlatformPlugin`, registers four exporters:

| Exporter                | Protocol             | Entry Type        | Output                                         |
| ----------------------- | -------------------- | ----------------- | ---------------------------------------------- |
| `iOSColorsExporter`     | `ColorsExporter`     | `iOS.ColorsEntry` | xcassets color sets + UIColor/SwiftUI Color.kt |
| `iOSIconsExporter`      | `IconsExporter`      | `iOS.IconsEntry`  | xcassets imagesets (PDF/SVG) + Swift ext       |
| `iOSImagesExporter`     | `ImagesExporter`     | `iOS.ImagesEntry` | xcassets imagesets (PNG/HEIC) + Swift ext      |
| `iOSTypographyExporter` | `TypographyExporter` | `iOS.Typography`  | UIFont + SwiftUI Font extensions               |

All multi-entry exporters use `parallelMapEntries()` for concurrent processing. Typography is single-entry.

### Two-Layer Pattern

```
Config/  → PKL-generated type bridges (entry convenience properties, URL resolution, enum bridging)
Export/  → Exporter implementations (pipeline orchestration: load → process → export → write)
```

Config types are typealiased from `ExFigConfig` generated code (e.g., `iOSColorsEntry = iOS.ColorsEntry`). Convenience extensions provide `resolved*()` methods and core enum bridging (`coreNameStyle`, `coreVectorFormat`, `coreRenderMode`).

### Entry-Level Override Resolution

Each entry can override platform-wide paths. The pattern is consistent:

```swift
entry.resolvedXcassetsPath(fallback: platformConfig.xcassetsPath)  // .xcassets directory
entry.resolvedTemplatesPath(fallback: platformConfig.templatesPath) // Stencil templates
```

### iOSPlatformConfig

Platform-level config (`iOSPlatformConfig`) holds shared settings: `xcodeprojPath`, `target`, `xcassetsPath`, `xcassetsInMainBundle`, `xcassetsInSwiftPackage`, `resourceBundleNames`, `addObjcAttribute`, `templatesPath`. This struct is NOT PKL-generated — it's manually maintained.

### Images: Format Matrix

`iOSImagesExporter` branches by source→output format combination:

| Source | Output | Pipeline                                                    |
| ------ | ------ | ----------------------------------------------------------- |
| PNG    | PNG    | Download → density-qualified @1x/@2x/@3x imagesets          |
| PNG    | HEIC   | Download → convertFormat(to: .heic) → imagesets             |
| SVG    | PNG    | Download SVG → rasterizeSVGs → density-qualified imagesets  |
| SVG    | HEIC   | Download SVG → rasterizeSVGs(to: .heic) → density-qualified |

SVG source images always use `scales: [1.0]` and `sourceFormat: .svg` — constructed inline via `entry.svgSourceInput()`, NOT via `entry.imagesSourceInput()`.

SVG→raster pipeline generates `Contents.json` manually via `iOSImagesExporterHelpers.makeImagesetContentsJson()` (not delegated to `XcodeExport`).

### Icons: Granular Cache

`iOSIconsExporter` and `iOSImagesExporter` both support granular cache via `IconsExportContextWithGranularCache` / `ImagesExportContextWithGranularCache` protocol conformance check at runtime (`context as?`). When enabled:

- Only changed assets are exported (based on content hash)
- `allIconNames`/`allImageNames` are still computed for template generation (so Swift extensions include ALL names)
- Old assets are NOT cleaned up (incremental write)
- `IconsExportResult` / `ImagesExportResult` carry `computedHashes` and `allAssetMetadata`

### Dark Mode

All asset types support dark variants via `AssetPair<T>`. Pattern:

- Colors: light+dark in single colorset via `XcodeColorExporter`
- Icons: dark variant filenames suffixed with `D` (e.g., `iconD.pdf`)
- Images: dark variants in imageset with `appearances: [luminosity: dark]`

### Output Cleanup

Exporters remove old output dirs (`FileManager.removeItem`) before writing when:

- `context.filter == nil` (full export, not filtered)
- `useGranularCache == false`

Filtered/cached exports preserve existing files (append mode).

## Key Conventions

- **URL bridging:** All PKL `String?` paths → `URL` via `URL(fileURLWithPath:)` (file URLs, not `URL(string:)`)
- **Default scales:** `[1.0, 2.0, 3.0]` for iOS images (vs Android's `[1.0, 1.5, 2.0, 3.0, 4.0]`)
- **Default frame names:** `"Icons"` for icons, `"Images"` for images (used when `figmaFrameName` is nil)
- **Enum bridging:** Uses `rawValue` roundtrip — PKL enum → generated Swift enum → ExFigCore enum
- **SwiftLint:** `type_name` disabled at file level (lowercase `iOS` prefix is intentional convention)
- **Error types:** Each exporter defines its own `LocalizedError` enum with `errorDescription` + `recoverySuggestion`

## Modification Checklist

When adding a field to an entry type:

1. Add PKL field in `Sources/ExFigCLI/Resources/Schemas/iOS.pkl`
2. Regenerate: `./bin/mise run codegen:pkl`
3. Add convenience extension in `Config/iOS*Entry.swift`
4. Wire into `SourceInput` bridge method (`iconsSourceInput()` / `imagesSourceInput()`)
5. Update exporter usage in `Export/iOS*Exporter.swift`
6. Update `EnumBridgingTests` in `Tests/ExFigTests/` (check BOTH indentation levels)

When adding a new `resolvedX()` override:

1. Add optional field to PKL entry schema
2. Add `resolvedX(fallback:)` method to entry extension
3. Use in exporter: `entry.resolvedX(fallback: platformConfig.x)`

When modifying `XcodeImagesOutput` / `XcodeColorsOutput` construction:

- Update ALL sites in this module's `Export/` files — colors output, icons output, images output (2 places: PNG and SVG paths), typography output
- `iOSImagesEntry.makeXcodeImagesOutput()` helper centralizes images output construction — update it there
