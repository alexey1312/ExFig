## Why

ExFig is tightly coupled to the Figma API — all loaders directly call FigmaAPI endpoints. The only exception is `TokensFileSource` for colors from `.tokens.json`. This blocks support for alternative design tools (Penpot, Sketch, Tokens Studio multi-file sets). The open-source design tool market is growing (Penpot), and the W3C DTCG standard makes data sources interchangeable — now is the right time to abstract.

## What Changes

- New per-asset-type source protocols in ExFigCore: `ColorsSource`, `ComponentsSource`, `TypographySource` (no `sourceKind` in protocols — clean contract)
- `DesignSourceKind` enum (figma, penpot, tokensFile, tokensStudio, sketchFile) added to `*SourceInput` types
- `FigmaColorsSource`, `FigmaComponentsSource`, `FigmaTypographySource` — wrappers around current Figma logic
- `TokensFileColorsSource` — extracted from `ColorsExportContextImpl` (including warning logic)
- `SourceFactory` — centralized factory for creating source instances by `DesignSourceKind`
- Refactored `*ExportContextImpl` — source injection instead of direct `Client` (Icons/Images context retains `client` for granular cache path)
- PKL: `sourceKind` field in `Common.pkl` (`FrameSource`, `VariablesSource`)

**Unchanged:** ExportContext protocols, platform exporters, processors, FileContents, batch TaskLocal pattern, granular cache (stays inside `FigmaComponentsSource`).

**Deferred (follow-up change):** Download icons/images path (`DownloadImageLoader`), MCP `exfig_download` tool handler.

## Capabilities

### New Capabilities

- `design-source-protocol`: Per-asset-type source protocols (`ColorsSource`, `ComponentsSource`, `TypographySource`) and `DesignSourceKind` enum to abstract the data source from the export pipeline. Protocols are clean (no `sourceKind` property) — dispatch is handled by `SourceFactory`
- `source-dispatch`: Centralized `SourceFactory` for selecting the source implementation based on `sourceKind`. Used by Plugin*Export files, batch runner, and download colors command

### Modified Capabilities

- `tokens-file-source`: Extract loading logic (including darkModeName warning) from `ColorsExportContextImpl` into a standalone `TokensFileColorsSource` implementing the `ColorsSource` protocol
- `configuration`: Add `sourceKind` field to PKL schemas (`Common.pkl`: `FrameSource`, `VariablesSource`) with resolution priority: explicit > auto-detect > default `.figma`

## Impact

- **ExFigCore** — 1 new file (protocols + enum + `ColorsSourceConfig` + `FigmaColorsConfig` + `TokensFileColorsConfig`), refactored `ColorsSourceInput` (sourceConfig pattern), `sourceKind` field added to 3 other SourceInput types
- **ExFigCLI** — 6 new source files (4 sources + factory + tokens-file extraction), refactoring 4 context implementations, changes to ~10 subcommand/export files
- **PKL schemas** — `Common.pkl` (new typealias + fields)
- **Tests** — new unit tests for TokensFileColorsSource, DesignSourceKind, SourceFactory. Figma source tests are integration-only (require API token). Existing tests remain unaffected (default `.figma`)
- **API compatibility** — full backward compatibility, `sourceKind` defaults to figma/null
- **Dependencies** — none added
- **Deferred** — download icons/images path, MCP `exfig_download` handler (follow-up change)
