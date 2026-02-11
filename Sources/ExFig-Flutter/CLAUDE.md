# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Module Role

ExFig-Flutter is the Flutter platform plugin. It wires PKL configuration to the export pipeline: Figma fetch -> processing -> Dart code generation -> file write. It does NOT render Dart code — that's `FlutterExport` (Stencil templates). It does NOT define domain models — that's `ExFigCore`.

No typography exporter exists (only colors, icons, images).

## Dependencies

- `ExFigCore` — domain models (`Color`, `ImagePack`, `NameStyle`), protocols (`ColorsExporter`, `IconsExporter`, `ImagesExporter`), `parallelMapEntries()`
- `ExFigConfig` — PKL-generated types (`Flutter.ColorsEntry`, `Flutter.IconsEntry`, `Flutter.ImagesEntry`)
- `FlutterExport` — Dart code generation via Stencil templates (`FlutterColorExporter`, `FlutterIconsExporter`, `FlutterImagesExporter`)

## Architecture

```
Config/              Entry types — typealiases + convenience extensions bridging PKL → ExFigCore
Export/              Exporter structs — orchestrate load → process → export → write pipeline
FlutterPlugin.swift  PlatformPlugin registration (identifier: "flutter", 3 exporters)
```

### Entry Bridging Pattern

Each entry file provides:

1. `public typealias FlutterXxxEntry = Flutter.XxxEntry` — backward compat
2. Convenience extensions: `effectiveNameStyle`, `effectiveScales`, `resolvedTemplatesPath(fallback:)`
3. SourceInput factories: `iconsSourceInput()`, `imagesSourceInput()`, `svgSourceInput()` — bridge PKL fields to ExFigCore input types

### Exporter Pattern

All three exporters follow the same structure:

```swift
public func exportXxx(entries:, platformConfig:, context:) async throws -> XxxExportResult {
    let counts = try await parallelMapEntries(entries) { entry in
        try await exportSingleEntry(entry:, platformConfig:, context:)
    }
    // success message only if !context.isBatchMode
}
```

## Flutter-Specific Conventions

| Convention           | Value                                                                 |
| -------------------- | --------------------------------------------------------------------- |
| Default nameStyle    | `snake_case` (icons, images)                                          |
| Colors nameStyle     | Always `camelCase` (hardcoded in exporter, not entry-configurable)    |
| Default scales       | `[1.0, 2.0, 3.0]`                                                     |
| Default image format | `.png`                                                                |
| Dark mode suffix     | `_dark` (e.g., `icon_dark.svg`)                                       |
| Destination URLs     | `URL(string:)` — preserves subdirectories like `"icons/actions.dart"` |

## Images Exporter: 5 Format Pipelines

| Source -> Output | Pipeline                                           |
| ---------------- | -------------------------------------------------- |
| SVG -> SVG       | download SVGs -> write directly (1x only)          |
| SVG -> PNG       | download SVGs -> rasterize at scales -> write      |
| SVG -> WebP      | download SVGs -> rasterize at scales -> write      |
| PNG -> PNG       | download PNGs at scales -> write via FlutterExport |
| PNG -> SVG       | **error** — `incompatibleFormat` thrown            |

SVG source always forces `scales: [1.0]` and `sourceFormat: .svg` via `svgSourceInput()`.

### Flutter Scale Directory Structure

```
output/
  image.png          # 1x (root)
  2.0x/image.png     # 2x
  3.0x/image.png     # 3x
```

`FlutterImagesHelpers.mapToFlutterScaleDirectories()` handles this mapping.

## Modification Checklist

**Adding a field to an entry:**

1. PKL schema: `Sources/ExFigCLI/Resources/Schemas/Flutter.pkl`
2. Regenerate: `./bin/mise run codegen:pkl`
3. Convenience extension in `Config/Flutter*Entry.swift`
4. Wire into bridge method (`iconsSourceInput()` / `imagesSourceInput()` / `svgSourceInput()`)
5. Update exporter in `Export/Flutter*Exporter.swift`
6. Update `EnumBridgingTests` — watch for TWO indentation levels (12-space and 16-space)

**Adding a filter level:** Update ALL predicate sites — see root CLAUDE.md "Adding a New Filter Level".

## Testing

```bash
./bin/mise run test:filter ExFig_FlutterTests      # This module's tests
./bin/mise run test:filter FlutterExportTests       # Rendering layer tests
```

Note: SPM converts hyphens to underscores — use `ExFig_FlutterTests`, not `ExFig-FlutterTests`.
