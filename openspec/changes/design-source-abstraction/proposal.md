## Why

ExFig is tightly coupled to the Figma API — all loaders directly call FigmaAPI endpoints. The only exception is `TokensFileSource` for colors from `.tokens.json`. This blocks support for alternative design tools (Penpot, Sketch, Tokens Studio multi-file sets). The open-source design tool market is growing (Penpot), and the W3C DTCG standard makes data sources interchangeable — now is the right time to abstract.

## What Changes

- New per-asset-type source protocols in ExFigCore: `ColorsSource`, `ComponentsSource`, `TypographySource`
- `DesignSourceKind` enum (figma, penpot, tokensFile, tokensStudio, sketchFile) added to `*SourceInput` types
- `FigmaColorsSource`, `FigmaComponentsSource`, `FigmaTypographySource` — wrappers around current Figma logic
- `TokensFileColorsSource` — extracted from `ColorsExportContextImpl`
- Refactored `*ExportContextImpl` — source injection instead of direct `Client`
- PKL: `sourceKind` field in `Common.pkl` (`FrameSource`, `VariablesSource`)
- Source factories in subcommands and batch runner

**Unchanged:** ExportContext protocols, platform exporters, processors, FileContents, batch TaskLocal pattern, granular cache (stays inside `FigmaComponentsSource`).

## Capabilities

### New Capabilities

- `design-source-protocol`: Per-asset-type source protocols (`ColorsSource`, `ComponentsSource`, `TypographySource`) and `DesignSourceKind` enum to abstract the data source from the export pipeline
- `source-dispatch`: Factory logic for selecting the source implementation based on `sourceKind` in subcommands, batch runner, and download commands

### Modified Capabilities

- `tokens-file-source`: Extract loading logic from `ColorsExportContextImpl` into a standalone `TokensFileColorsSource` implementing the `ColorsSource` protocol
- `configuration`: Add `sourceKind` field to PKL schemas (`Common.pkl`: `FrameSource`, `VariablesSource`)

## Impact

- **ExFigCore** — 2 new files (protocols + enum), changes to 4 `*SourceInput` types (new field with default)
- **ExFigCLI** — 5 new source files, refactoring 4 context implementations, changes to ~10 subcommand/export files
- **PKL schemas** — `Common.pkl` (new typealias + fields), possibly `ExFig.pkl`
- **Tests** — new unit tests for source types, existing tests remain unaffected (default `.figma`)
- **API compatibility** — full backward compatibility, `sourceKind` defaults to figma/null
- **Dependencies** — none added
