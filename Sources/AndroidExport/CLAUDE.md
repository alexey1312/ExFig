# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Module Overview

AndroidExport is a pure rendering/transformation layer: it takes ExFigCore domain models (Color, TextStyle, ImagePack) and produces Android-specific output files (XML resources + Jetpack Compose Kotlin). It has NO dependency on FigmaAPI and performs NO file I/O beyond template loading.

Orchestration (Figma fetching, processing, file writing) lives in `ExFig-Android` plugin, NOT here.

## Build & Test

```bash
./bin/mise run test:filter AndroidExportTests    # Unit tests for this module
./bin/mise run test:filter ExFig_AndroidTests     # Integration tests (plugin layer)
./bin/mise run build                              # Full project build
```

## Architecture

### Dual Output System

Exporters produce XML resources, Kotlin Compose code, or both:

| Exporter                       | XML Output                                      | Compose Output                   |
| ------------------------------ | ----------------------------------------------- | -------------------------------- |
| AndroidColorExporter           | `values/colors.xml` + `values-night/colors.xml` | `Colors.kt`                      |
| AndroidTypographyExporter      | `typography.xml`                                | `Typography.kt`                  |
| AndroidComposeIconExporter     | (none)                                          | `Icons.kt`                       |
| AndroidCodeConnectExporter     | (none)                                          | `*.figma.kt` (Code Connect)      |
| AndroidImageVectorExporter     | (none)                                          | `IconName.kt` (ImageVector code) |
| AndroidThemeAttributesExporter | `attrs.xml` + `styles.xml` content              | (none)                           |

XML generation can be disabled per-entry via `AndroidOutput.xmlDisabled`.

### Class Hierarchy

`AndroidExporter` is the base class providing Stencil template loading and `FileContents` creation. `AndroidColorExporter`, `AndroidTypographyExporter`, `AndroidComposeIconExporter`, and `AndroidCodeConnectExporter` inherit from it.

`AndroidImageVectorExporter` and `AndroidThemeAttributesExporter` are standalone (`Sendable`) — they don't use Stencil templates.

### Template System

Seven Stencil templates in `Resources/`: `colors.xml.stencil`, `Colors.kt.stencil`, `typography.xml.stencil`, `Typography.kt.stencil`, `Icons.kt.stencil`, `CodeConnect.figma.kt.stencil`, `header.stencil`.

Template loading priority: custom `templatesPath` (from PKL config) > `Bundle.module` resources. StencilSwiftKit extensions are registered for all environments.

### Key Data Flow

```
ExFigCore models → AndroidOutput (config) → Exporter → Stencil render → [FileContents]
```

`FileContents` is the universal output type — the plugin layer handles writing them to disk.

## Critical Patterns

### Color Format Conversions

Two hex formats coexist:

- XML: `#AARRGGBB` or `#RRGGBB` (alpha prefix) — `Color.hex`
- Kotlin: `0xAARRGGBB` literal — `Color.kotlinHex`

Both formats use ARGB channel order (Android convention), not RGBA.

### AndroidOutput Configuration

`AndroidOutput` bridges PKL config to exporter parameters. Key fields:

- `xmlOutputDirectory` — Android `res/` folder (always required)
- `composeOutputDirectory` — computed from `mainSrc` + `packageName` path segments
- `xmlResourcePackage` — R class package for `colorResource(id = R.color.*)` imports
- `xmlDisabled` — skip XML generation entirely (Compose-only projects)

### ThemeAttributes Collision Detection

`AndroidThemeAttributesExporter` uses `OrderedDictionary` to track when multiple XML color names (`text_primary`, `extensions_text_primary`) map to the same theme attribute (`colorTextPrimary`) after prefix stripping. Collisions are returned (not thrown) for the CLI to display as warnings.

The `ThemeAttributeNameTransformer` supports 6 case styles and prefix stripping — test all styles when modifying transformation logic.

### ImageVector PathData Validation

Android has a hard 32,767 byte limit for pathData in compiled VectorDrawable resources. `AndroidImageVectorExporter` validates this and throws `ImageVectorExportError.pathDataExceedsCriticalLimit`. The `strictPathValidation` config flag controls whether this is a warning or a hard error.

### Drawable Density Qualifiers

`Drawable.scaleToDrawableName()` maps numeric scales to Android density folders:
`1.0→mdpi`, `1.5→hdpi`, `2.0→xhdpi`, `3.0→xxhdpi`, `4.0→xxxhdpi`.
Single-scale assets use `drawable` / `drawable-night` (no qualifier).

## What Makes This Module Different from Other Export Modules

1. **Dual format** (XML + Compose) — other platforms have single output format
2. **ImageVector code generation** — programmatic SVG→Kotlin, unique to Android (iOS uses PDF, Flutter uses SVG assets)
3. **Theme attributes** with collision detection and `OrderedDictionary` — no equivalent in other platforms
4. **5 density buckets** vs iOS's 3 scale factors
5. **Resource package separation** (`packageName` vs `xmlResourcePackage`) for multi-module Android projects

## Modification Checklist

When adding a new exporter:

1. Inherit from `AndroidExporter` (if using Stencil) or make standalone `Sendable` struct
2. Add Stencil template to `Resources/` (if needed)
3. Wire up in `ExFig-Android/Export/` plugin exporter
4. Add PKL entry fields in `Sources/ExFigCLI/Resources/Schemas/Android.pkl`
5. Regenerate: `./bin/mise run codegen:pkl`
6. Add bridge extensions in `ExFig-Android/Config/`

When modifying `AndroidOutput`:

- Update all construction sites in `ExFig-Android/Export/*.swift`
- Update `ExFig-Android/Config/` bridge helpers (`resolvedMainRes`, `resolvedMainSrc`)

When modifying Stencil templates:

- Template context variables must match the dictionary keys passed in the exporter's `render()` call
- Update corresponding tests in `Tests/AndroidExportTests/`
