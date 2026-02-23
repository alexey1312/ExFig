# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Module Role

FlutterExport is the rendering layer for Flutter. It takes processed domain models (`Color`, `ImagePack` from ExFigCore) and generates Dart source files + asset file descriptors using Jinja2 templates. It does NOT fetch from Figma, parse config, or orchestrate the pipeline — that's `ExFig-Flutter`.

## Dependencies

- `ExFigCore` — domain models (`Color`, `ImagePack`, `AssetPair`, `FileContents`, `NameStyle`, `Scale`)
- `JinjaSupport` — Jinja2 template rendering via `JinjaTemplateRenderer`

## Architecture

```
FlutterExporter.swift          Base class — Jinja template loading, FileContents factory
FlutterColorExporter.swift     Colors -> Dart class (2 modes: legacy 2-class vs unified 4-mode)
FlutterIconsExporter.swift     Icons -> SVG assets + Dart constants file
FlutterImagesExporter.swift    Images -> multi-scale assets + Dart constants file
Model/FlutterOutput.swift      Configuration struct (output dirs, class names, templates path)
Resources/*.jinja              Jinja2 templates for Dart code generation
```

### Inheritance

All three exporters extend `FlutterExporter` (class, not protocol) which provides:

- `loadTemplate()`/`renderTemplate()` — Jinja template loading with custom or bundled templates
- `makeFileContents(for:directory:file:)` — wraps string output into `FileContents`

### Template Resolution

Custom templates path (`FlutterOutput.templatesPath`) overrides bundled `Resources/` templates. Bundled templates are loaded via `Bundle.module`.

## Key Design Decisions

### Color Export: Two Modes

The color exporter auto-selects based on whether ANY `AssetPair` has high-contrast colors:

| Mode    | Trigger                     | Output                                           |
| ------- | --------------------------- | ------------------------------------------------ |
| Legacy  | No HC colors in any pair    | `AppColors` + `AppColorsDark` (2 classes)        |
| Unified | Any pair has lightHC/darkHC | Single `AppColors` with 4 Color fields per entry |

Fallback logic in unified mode: `darkHC ?? dark ?? light`, `lightHC ?? light`.

### Color Format

Flutter uses `0xAARRGGBB` hex format (not `#RRGGBB`). The `Color.flutterHex` computed property handles conversion.

### Destination URL Contract

FlutterExport uses `URL(string:)` (NOT `URL(fileURLWithPath:)`) for file URLs. This preserves subdirectory paths like `"icons/actions.dart"` — `FileWriter` creates intermediate directories from `destination.url.deletingLastPathComponent()`.

### Icons/Images: Dual Return

`export()` returns `(dartFile: FileContents, assetFiles: [FileContents])` tuple — the Dart constants file is separate from the SVG/PNG asset files. The caller (`ExFig-Flutter`) handles writing both.

### Image Scale Directories

Flutter convention: 1x at root, 2x at `2.0x/`, 3x at `3.0x/`. Implemented in `FlutterImagesExporter.makeImageFile()`.

### Name Styling

Icons and images exporters apply `NameStyle` to asset filenames and Dart paths. Dart constant names always use `lowerCamelCase` regardless of `nameStyle` setting. Default `nameStyle` is `.snakeCase`. Dark suffix comes from `nameStyle.darkSuffix` (e.g., `_dark`).

### Granular Cache Support

Icons and images exporters accept optional `allIconNames`/`allImageNames` parameter — when provided, the Dart file lists all names even if only a subset of assets is being re-exported. Dark mode variants are not tracked in this mode.

## Testing

```bash
./bin/mise run test:filter FlutterExportTests
```

Tests verify generated Dart code against reference strings using `expectNoDifference` (custom-dump). Template whitespace matters — tests use explicit `joined(separator: "\n")` for reference code.

## Modification Checklist

**Adding a field to FlutterOutput:** Update init + all construction sites in `ExFig-Flutter/Export/` and `FlutterExportTests/`.

**Changing template output:** Edit `Resources/*.jinja`, then update reference strings in ALL affected tests. Template whitespace (blank lines, trailing newlines) is asserted exactly.

**Adding a new exporter:** Subclass `FlutterExporter`, add Jinja template in `Resources/`, create test file in `Tests/FlutterExportTests/`.
