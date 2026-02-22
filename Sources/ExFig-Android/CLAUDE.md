# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Module Overview

ExFig-Android is the Android **platform plugin** — it orchestrates the full export pipeline: Figma fetch → processing → file generation → disk write. It delegates rendering to `AndroidExport` (pure transformation layer) and I/O to `ExFigCore` context protocols.

This is **NOT** the rendering layer. `AndroidExport` handles Jinja2 templates, XML/Kotlin generation. This module wires config, loads data, and writes output.

## Build & Test

```bash
./bin/mise run test:filter ExFig_AndroidTests    # Plugin integration tests
./bin/mise run test:filter AndroidExportTests     # Rendering layer unit tests
./bin/mise run build                              # Full project build
```

## Architecture

### Plugin Registration

`AndroidPlugin` conforms to `PlatformPlugin`, registers four exporters:

| Exporter                    | Protocol             | Entry Type            | Output                                     |
| --------------------------- | -------------------- | --------------------- | ------------------------------------------ |
| `AndroidColorsExporter`     | `ColorsExporter`     | `Android.ColorsEntry` | XML colors + Compose Colors.kt             |
| `AndroidIconsExporter`      | `IconsExporter`      | `Android.IconsEntry`  | VectorDrawable XML or ImageVector Kotlin   |
| `AndroidImagesExporter`     | `ImagesExporter`     | `Android.ImagesEntry` | Density-qualified drawables (PNG/WebP/XML) |
| `AndroidTypographyExporter` | `TypographyExporter` | `Android.Typography`  | typography.xml + Typography.kt             |

All exporters use `parallelMapEntries()` for multi-entry parallelism (except Typography which is single-entry).

### Two-Layer Pattern

```
Config/  → PKL-generated type bridges (entry convenience properties, URL resolution, enum bridging)
Export/  → Exporter implementations (pipeline orchestration: load → process → export → write)
```

Config types are typealiased from `ExFigConfig` generated code (e.g., `AndroidColorsEntry = Android.ColorsEntry`). Convenience extensions provide `resolved*()` methods for entry-level override resolution against platform config fallbacks.

### Entry-Level Override Resolution

Each entry can override platform-wide paths. The pattern is consistent across all entry types:

```swift
entry.resolvedMainRes(fallback: platformConfig.mainRes)      // res/ directory
entry.resolvedTemplatesPath(fallback: platformConfig.templatesPath)  // Jinja2 templates
entry.resolvedMainSrc(fallback: platformConfig.mainSrc)      // Kotlin src/ (colors only)
```

### Icons: Two Export Modes

`AndroidIconsExporter` branches on `composeFormat`:

- **`.resourceReference`** (default) → SVG → VectorDrawable XML in `drawable/` + optional Compose Icons.kt extension
- **`.imageVector`** → SVG → Kotlin ImageVector code in `src/` (requires `composePackageName` + `mainSrc`)

Both modes use temp directories for SVG download, then convert and write to final output.

Both modes optionally generate Figma Code Connect (`.figma.kt`) when `codeConnectKotlin` is set. Requires `composePackageName` + `resourcePackage`.

### Images: Format Matrix

`AndroidImagesExporter` handles 5 source→output combinations:

| Source | Output | Pipeline                                          |
| ------ | ------ | ------------------------------------------------- |
| SVG    | SVG    | Download → NativeVectorDrawableConverter → XML    |
| SVG    | WebP   | Download → rasterizeSVGs → density-qualified WebP |
| SVG    | PNG    | Download → rasterizeSVGs → density-qualified PNG  |
| PNG    | WebP   | Download → convertFormat → density-qualified WebP |
| PNG    | PNG    | Download → density-qualified PNG                  |

PNG→SVG is unsupported and throws `incompatibleFormat`.

All 5 pipelines optionally generate Figma Code Connect (`.figma.kt`) when `codeConnectKotlin` is set. Uses `resourcePackage` as both package name and R class package.

SVG images always use `scales: [1.0]` and `sourceFormat: .svg` — the `ImagesSourceInput` is constructed inline in `loadAndProcessSVG()`, NOT via `entry.imagesSourceInput()`.

### Density Folder Mapping

Output uses `Drawable.scaleToDrawableName()` from `AndroidExport`:
`1.0→mdpi`, `1.5→hdpi`, `2.0→xhdpi`, `3.0→xxhdpi`, `4.0→xxxhdpi`.
Default scales: `[1.0, 1.5, 2.0, 3.0, 4.0]`. Single-scale uses `drawable`/`drawable-night`.

### Dark Mode

All asset types support dark variants via `AssetPair`. Output directory pattern:

- Icons: `drawable/` + `drawable-night/`
- Images: density-qualified with `-night-` qualifier (e.g., `drawable-night-xhdpi`)
- Colors: `values/colors.xml` + `values-night/colors.xml`

## Key Conventions

- **Naming default:** Android uses `snake_case` (`.snakeCase`) for all asset names
- **SVG fallback for images:** When `format == .svg` on ImagesEntry, `coreOutputFormat` returns `.png` — a warning is logged at the call site in `ExFigCLI/Subcommands/Export/AndroidImagesExport.swift`
- **Output cleanup:** Exporters remove old output dirs before writing when `context.filter == nil` (full export). Filtered exports preserve existing files.
- **Temp directory lifecycle:** SVG workflows create temp dirs with `UUID().uuidString`, write downloads there, convert, then clean up after writing final output.

## Modification Checklist

When adding a field to an entry type:

1. Add PKL field in `Sources/ExFigCLI/Resources/Schemas/Android.pkl`
2. Regenerate: `./bin/mise run codegen:pkl`
3. Add convenience extension in `Config/Android*Entry.swift`
4. Wire into `SourceInput` bridge method (`iconsSourceInput()` / `imagesSourceInput()`)
5. Update exporter usage in `Export/Android*Exporter.swift`
6. Update `EnumBridgingTests` in `Tests/ExFigTests/` (check BOTH indentation levels)

When adding a new `resolvedX()` override:

1. Add optional field to PKL entry schema
2. Add `resolvedX(fallback:)` method to entry extension
3. Use in exporter: `entry.resolvedX(fallback: platformConfig.x)`

When modifying `AndroidOutput` construction:

- Update ALL sites in this module's `Export/` files — colors, icons (2 places: VD + Compose extension), images, typography
