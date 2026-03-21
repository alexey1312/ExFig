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

### 3. ColorsSourceInput uses ColorsSourceConfig protocol for source-specific fields

**Decision:** `ColorsSourceInput` splits into shared fields + source-specific `ColorsSourceConfig` protocol. Icons/Images/Typography SourceInputs remain flat (only Figma fields, no split needed yet).

```swift
public protocol ColorsSourceConfig: Sendable {}

public struct FigmaColorsConfig: ColorsSourceConfig {
    let tokensFileId: String
    let tokensCollectionName: String
    let lightModeName: String
    let darkModeName: String?
    let lightHCModeName: String?
    let darkHCModeName: String?
    let primitivesModeName: String?
}

public struct TokensFileColorsConfig: ColorsSourceConfig {
    let filePath: String
    let groupFilter: String?
}

public struct ColorsSourceInput {
    let sourceKind: DesignSourceKind
    let sourceConfig: any ColorsSourceConfig
    let nameValidateRegexp: String?
    let nameReplaceRegexp: String?
}
```

**Alternative A:** Keep flat `ColorsSourceInput` with all source fields as optionals (original proposal).

**Alternative B:** Apply SourceConfig to all 4 SourceInput types.

**Rationale:** `ColorsSourceInput` already has mixed concerns — 6 Figma fields + 2 tokens-file fields. Adding Penpot/Sketch/TokensStudio would grow it to 15+ fields with most being `nil`. The SourceConfig protocol solves this now, at zero extra cost since we're already refactoring. Icons/Images/Typography only have Figma fields — splitting them now would be premature. They get the same treatment when their second source arrives.

**Migration note:** Existing call sites that construct `ColorsSourceInput` need updating. The entry bridge methods in `Sources/ExFig-*/Config/*Entry.swift` create `FigmaColorsConfig` or `TokensFileColorsConfig` based on the entry. Source implementations cast `sourceConfig` to their expected type.

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

### 7. Source factory via SourceFactory enum

**Decision:** A dedicated `SourceFactory` enum in `Sources/ExFigCLI/Source/SourceFactory.swift` creates concrete sources. Subcommands call the factory instead of inline `if/else`.

```swift
enum SourceFactory {
    static func createColorsSource(
        for input: ColorsSourceInput,
        client: Client,
        ui: TerminalUI,
        filter: String?
    ) -> any ColorsSource {
        switch input.sourceKind {
        case .figma:
            FigmaColorsSource(client: client, ui: ui, filter: filter)
        case .tokensFile:
            TokensFileColorsSource(ui: ui)
        case .penpot, .tokensStudio, .sketchFile:
            fatalError("Unsupported source kind: \(input.sourceKind)")
        }
    }
    // ... createComponentsSource, createTypographySource
}
```

**Alternative:** Inline `if/else` in each subcommand.

**Rationale:** With 5 source kinds, inline dispatch becomes a switch in every subcommand. A centralized factory avoids duplication and makes adding new sources a single-point change. The subcommand still owns dependency creation (client, ui) — it just delegates dispatch.

### 8. sourceKind resolution priority

**Decision:** Explicit `sourceKind` in PKL config overrides auto-detection. Resolution order:

1. `sourceKind` explicitly set in PKL config → use as-is
2. `sourceKind` is `null` + `tokensFile` is set → `.tokensFile` (VariablesSource only)
3. `sourceKind` is `null` + no `tokensFile` → `.figma`

**Alternative:** Always require explicit `sourceKind`.

**Rationale:** Backward compatibility demands auto-detection for existing configs (no `sourceKind` field). Explicit `sourceKind` takes priority to avoid ambiguity when both `sourceKind = "figma"` and `tokensFile` are set (user wants Figma, tokensFile is leftover).

### 9. Granular cache retains direct Client access

**Decision:** `IconsExportContextImpl` and `ImagesExportContextImpl` accept BOTH `componentsSource: any ComponentsSource` AND `client: Client`.

- Basic `loadIcons()`/`loadImages()` → delegate to `componentsSource`
- `loadIconsWithGranularCache()`/`loadImagesWithGranularCache()` → use `client` directly (unchanged)

**Alternative:** Add granular cache methods to `ComponentsSource` protocol.

**Rationale:** Granular cache is Figma-specific (FNV-1a node hashes via `NodesEndpoint`). Adding it to the protocol pollutes the abstraction for non-Figma sources that will never support it. Keeping `client` alongside `componentsSource` is a pragmatic interim — the context impl can check `componentsSource is FigmaComponentsSource` for cache-specific paths if needed. Full migration of granular cache to source protocol is future work.

### 10. Protocols do not expose sourceKind

**Decision:** Source protocols (`ColorsSource`, `ComponentsSource`, `TypographySource`) do NOT include `var sourceKind: DesignSourceKind`. Only the `DesignSourceKind` enum and `*SourceInput.sourceKind` field exist for dispatch.

**Alternative:** Include `sourceKind` in protocols for runtime introspection.

**Rationale:** Consumers of source protocols (context impls, exporters) never need to know which source kind is active — they just call `loadColors()`. Including `sourceKind` in the protocol invites branching by source kind in exporters, breaking the abstraction. Dispatch happens in `SourceFactory` before the protocol is used. If runtime introspection is ever needed, concrete types can expose it independently.

## Risks / Trade-offs

| Risk                                                                                         | Impact                                                 | Mitigation                                                                                                                                 |
| -------------------------------------------------------------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `ImageLoaderBase` wrapper may not cover all code paths (granular cache, download commands)   | Incomplete abstraction for icons/images                | Phase A: cover main export path. Phase B: download commands. Tests reveal missed paths                                                     |
| `DesignSourceKind` in SourceInput — exporters could theoretically read it                    | Exporters might branch on sourceKind                   | Source protocols don't expose sourceKind (Decision #10). SourceInput.sourceKind is consumed by SourceFactory only. Enforce via code review |
| Download commands have a parallel code path (`DownloadImageLoader`, `DownloadExportHelpers`) | Duplication: export path abstracted, download path not | Update download path after main refactoring using the same source protocols                                                                |
| Batch mode `ConfigExecutionContext` needs to carry the source                                | Changes to batch infrastructure                        | Source is created per-config in `BatchConfigRunner`, passed via `ConfigExecutionContext`                                                   |
| `ColorsSourceConfig` cast at runtime (`as! FigmaColorsConfig`)                               | Runtime error if wrong config type passed              | SourceFactory ensures correct pairing. Cast failure throws descriptive error, not crash                                                    |
| Icons/Images/Typography SourceInputs still flat                                              | Need same refactoring when second source arrives       | Deliberate — only refactor when the problem exists. ColorsSourceConfig is the proven pattern                                               |

## Resolved Questions

1. **Should `ComponentsSource` cover download commands immediately?**
   → **No.** Download path (`DownloadIcons`, `DownloadImages`) uses `DownloadImageLoader` — a separate code path with its own caching logic. Abstracting it in this change would double the blast radius. **Deferred to a follow-up change.** This change covers: export path + `DownloadColors`/`DownloadAll.exportColors()` only.

2. **Granular cache + non-Figma sources?**
   → **Keep as internal detail of `FigmaComponentsSource`.** Non-Figma sources won't support granular cache initially. If needed later, define a separate `CacheableComponentsSource` protocol. See Decision #9.

## Future Considerations

- **NumbersSource:** `NumberVariablesLoader` loads dimension/number tokens from Figma Variables. It's not covered by any of the 3 protocols. Currently used only in `download tokens`. When number tokens become a regular export type, add a `NumbersSource` protocol. Not needed now (YAGNI).
- **Mixed sources per config:** A single PKL config mixing colors from Figma + icons from Penpot. Currently not supported — each entry has its own `sourceKind`. Infrastructure supports it but no testing or documentation.
