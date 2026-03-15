## Context

ExFig loads design data through 4 loaders in ExFigCLI, each calling FigmaAPI directly:

- `ColorsVariablesLoader` → `VariablesEndpoint` → `Color[]`
- `IconsLoader` (extends `ImageLoaderBase`) → `ComponentsEndpoint` + `ImageEndpoint` → `ImagePack[]`
- `ImagesLoader` (extends `ImageLoaderBase`) → same endpoints → `ImagePack[]`
- `TextStylesLoader` → `StylesEndpoint` + `NodesEndpoint` → `TextStyle[]`

Exception: `ColorsExportContextImpl` already has dual-source dispatch — when `tokensFilePath` is set, it loads from a local `.tokens.json` instead of the Figma API. This is the precedent for the abstraction.

**Module boundaries:** ExFigCore does NOT import FigmaAPI. Loaders live in ExFigCLI and translate FigmaAPI types (`Component`, `Variables`) into ExFigCore models (`ImagePack`, `Color`). Platform exporters see only ExFigCore types through `ExportContext` protocols.

**Constraint:** `ImageLoaderBase` (~500 lines) contains interleaved logic: component fetching, image URL fetching, RTL pairs, granular cache (FNV-1a hashes per node). Full refactoring is risky.

## Goals / Non-Goals

**Goals:**

- Abstract data loading behind per-asset-type source protocols
- Wrap current Figma logic in `Figma*Source` implementations without changing behavior
- Extract `TokensFileSource` loading logic into `TokensFileColorsSource`
- Add `DesignSourceKind` to `*SourceInput` types (default `.figma`) for dispatch
- Add `sourceKind` to PKL schemas for configuration
- Lay the foundation for Penpot/Sketch/TokensStudio (Phase 3, items #8-#9)

**Non-Goals:**

- Implementing Penpot, Sketch, or Tokens Studio sources (separate changes)
- Rewriting `ImageLoaderBase` — wrap only
- Changing `ExportContext` protocols (they're already source-agnostic for exporters)
- Refactoring granular cache
- Supporting mixed sources in a single PKL config (future work)

## Decisions

### 1. Per-asset-type protocols instead of a single `DesignSource`

**Decision:** Three separate protocols: `ColorsSource`, `ComponentsSource`, `TypographySource`.

**Alternative:** A single `DesignSource` protocol with methods for all asset types.

**Rationale:** Different sources support different asset types. Tokens Studio provides colors and typography but not icons. Sketch has no live API. A monolithic protocol would require `fatalError()` stubs for unsupported methods. Per-asset protocols let each source implement only its capabilities.

### 2. Protocols live in ExFigCore

**Decision:** `ColorsSource`, `ComponentsSource`, `TypographySource` go in `Sources/ExFigCore/Protocol/`.

**Alternative:** Place protocols in ExFigCLI alongside implementations.

**Rationale:** ExFigCore already contains `*SourceInput`, `*LoadOutput`, and `ExportContext` protocols. Source protocols are a logical extension of this layer. This lets future modules (PenpotAPI) depend on ExFigCore without importing ExFigCLI.

### 3. Source signatures mirror ExportContext.load*()

**Decision:** `ColorsSource.loadColors(from: ColorsSourceInput) → ColorsLoadOutput` — same signature as `ColorsExportContext.loadColors()`.

**Alternative:** New per-source SourceInput types (FigmaColorsInput, PenpotColorsInput).

**Rationale:** Minimal blast radius. `ColorsSourceInput` is used in 20+ locations. Figma-specific fields (`tokensFileId`, `modeName`) are simply ignored by non-Figma sources. New sources read `tokensFilePath` or add their own optional fields. If SourceInput becomes too bloated at 4+ sources, it can be refactored into a source-specific config struct later.

### 4. ImageLoaderBase — wrap, don't rewrite

**Decision:** `FigmaComponentsSource` creates `IconsLoader`/`ImagesLoader` internally and delegates to them. `ImageLoaderBase` remains unchanged.

**Alternative:** Refactor `ImageLoaderBase` by extracting an abstract protocol for component fetching.

**Rationale:** `ImageLoaderBase` contains tightly interleaved logic:

1. Component fetching + filtering (platform, RTL, page)
2. Image URL fetching + batching
3. Granular cache (node hashes, diff, skip logic)
4. RTL pair building
5. Code Connect metadata

Refactoring with abstraction extraction risks breaking granular cache and batch mode. Wrapping is a safe first step. Internal refactoring can be done iteratively later.

### 5. DesignSourceKind enum with default in SourceInput

**Decision:** `DesignSourceKind` enum + `sourceKind: DesignSourceKind` field (default `.figma`) in each `*SourceInput`.

**Alternative A:** Determine source by field presence/absence (like the current `isLocalTokensFile`).

**Alternative B:** Source kind at the PKL config level (global), not per-entry.

**Rationale:** An explicit discriminator is safer than implicit detection by fields — fewer edge cases. Per-entry enables future source mixing (colors from Figma, icons from Penpot). Default `.figma` ensures full backward compatibility.

### 6. Context impls delegate to source, don't inherit

**Decision:** `ColorsExportContextImpl` holds `colorsSource: any ColorsSource` and delegates `loadColors()`.

**Alternative:** Inheritance (`FigmaColorsExportContext`, `TokensFileColorsExportContext`).

**Rationale:** Composition over inheritance. Context impl contains UI/FileWriter/batch logic that's identical across all sources. Only data loading differs — that's what we inject.

### 7. Source factory in subcommands

**Decision:** Subcommand `run()` (or a helper) creates the concrete source from config and passes it to the context impl.

```swift
let colorsSource: any ColorsSource = if source.isLocalTokensFile {
    TokensFileColorsSource(ui: ui)
} else {
    FigmaColorsSource(client: client, ui: ui, filter: filter)
}
let context = ColorsExportContextImpl(colorsSource: colorsSource, ui: ui, ...)
```

**Rationale:** The subcommand is the only place where ALL dependencies are known (client, ui, config, filter). A factory here is natural.

## Risks / Trade-offs

| Risk                                                                                         | Impact                                                 | Mitigation                                                                                        |
| -------------------------------------------------------------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------------------------------------------- |
| `ImageLoaderBase` wrapper may not cover all code paths (granular cache, download commands)   | Incomplete abstraction for icons/images                | Phase A: cover main export path. Phase B: download commands. Tests reveal missed paths            |
| `DesignSourceKind` in SourceInput — leaky abstraction for exporters                          | Exporters might branch on sourceKind                   | sourceKind is used ONLY in context impls / factories, never in exporters. Enforce via code review |
| Download commands have a parallel code path (`DownloadImageLoader`, `DownloadExportHelpers`) | Duplication: export path abstracted, download path not | Update download path after main refactoring using the same source protocols                       |
| Batch mode `ConfigExecutionContext` needs to carry the source                                | Changes to batch infrastructure                        | Source is created per-config in `BatchConfigRunner`, passed via `ConfigExecutionContext`          |
| ColorsSourceInput grows with fields from different sources                                   | Tech debt when adding 3+ sources                       | Acceptable for 2-3 sources. At 4+ — refactor into source-specific config struct                   |

## Open Questions

1. **Should `ComponentsSource` cover download commands immediately?** The download path (`DownloadIcons`, `DownloadImages`) uses `DownloadImageLoader` — a separate code path from export. This could be deferred to a follow-up iteration.

2. **Granular cache + non-Figma sources:** Granular cache relies on Figma node hashes (FNV-1a). Penpot/Sketch would need their own hash computation mechanism. Keep as an internal detail of `FigmaComponentsSource` or abstract?
