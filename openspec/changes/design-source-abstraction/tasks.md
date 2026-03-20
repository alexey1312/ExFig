## 1. Core Protocols & Types (ExFigCore)

- [ ] 1.1 Create `DesignSourceKind` enum in `Sources/ExFigCore/Protocol/DesignSource.swift` (figma, penpot, tokensFile, tokensStudio, sketchFile)
- [ ] 1.2 Define `ColorsSource` protocol in the same file (no `sourceKind` property)
- [ ] 1.3 Define `ComponentsSource` protocol (loadIcons + loadImages, no `sourceKind` property)
- [ ] 1.4 Define `TypographySource` protocol (no `sourceKind` property)
- [ ] 1.5 Define `ColorsSourceConfig` protocol in the same file
- [ ] 1.6 Create `FigmaColorsConfig` struct conforming to `ColorsSourceConfig` — fields extracted from `ColorsSourceInput`: `tokensFileId`, `tokensCollectionName`, `lightModeName`, `darkModeName`, `lightHCModeName`, `darkHCModeName`, `primitivesModeName`
- [ ] 1.7 Create `TokensFileColorsConfig` struct conforming to `ColorsSourceConfig` — fields: `filePath`, `groupFilter`
- [ ] 1.8 Refactor `ColorsSourceInput` — replace Figma/tokens-file fields with `sourceKind: DesignSourceKind` + `sourceConfig: any ColorsSourceConfig`. Keep shared fields: `nameValidateRegexp`, `nameReplaceRegexp`. Remove `isLocalTokensFile` computed property
- [ ] 1.9 Add `sourceKind: DesignSourceKind` field (default `.figma`) to `IconsSourceInput`
- [ ] 1.10 Add `sourceKind: DesignSourceKind` field (default `.figma`) to `ImagesSourceInput`
- [ ] 1.11 Add `sourceKind: DesignSourceKind` field (default `.figma`) to `TypographySourceInput`
- [ ] 1.12 Update all `ColorsSourceInput` construction sites — create `FigmaColorsConfig`/`TokensFileColorsConfig` and pass as `sourceConfig`
- [ ] 1.13 Verify ExFigCore compiles without FigmaAPI import (`./bin/mise run build`)

## 2. Figma Source Implementations (ExFigCLI)

- [ ] 2.1 Create `Sources/ExFigCLI/Source/FigmaColorsSource.swift` — extract `loadColorsFromFigma()` from `ColorsExportContextImpl`
- [ ] 2.2 Create `Sources/ExFigCLI/Source/TokensFileColorsSource.swift` — extract `loadColorsFromTokensFile()` from `ColorsExportContextImpl` (including darkModeName warning logic)
- [ ] 2.3 Create `Sources/ExFigCLI/Source/FigmaComponentsSource.swift` — wrap `IconsLoader`/`ImagesLoader` via `ImageLoaderBase`
- [ ] 2.4 Create `Sources/ExFigCLI/Source/FigmaTypographySource.swift` — wrap `TextStylesLoader`
- [ ] 2.5 Create `Sources/ExFigCLI/Source/SourceFactory.swift` — centralized factory for creating source instances by `DesignSourceKind`
- [ ] 2.6 Verify all source implementations compile (`./bin/mise run build`)

## 3. Context Refactoring (ExFigCLI)

- [ ] 3.1 Refactor `ColorsExportContextImpl` — accept `colorsSource: any ColorsSource`, delegate `loadColors()`. Remove inline tokens-file/Figma dispatch and darkModeName warning
- [ ] 3.2 Refactor `IconsExportContextImpl` — accept `componentsSource: any ComponentsSource` alongside existing `client`. Basic `loadIcons()` delegates to `componentsSource`. `loadIconsWithGranularCache()` retains direct `client` usage
- [ ] 3.3 Refactor `ImagesExportContextImpl` — same pattern as Icons (componentsSource + client coexist)
- [ ] 3.4 Refactor `TypographyExportContextImpl` — accept `typographySource: any TypographySource`, delegate `loadTypography()`
- [ ] 3.5 Verify all context implementations compile (`./bin/mise run build`)

## 4. Source Factories in Subcommands

- [ ] 4.1 Update `Sources/ExFigCLI/Subcommands/Export/PluginColorsExport.swift` — use `SourceFactory.createColorsSource()`, pass to `ColorsExportContextImpl`
- [ ] 4.2 Update `Sources/ExFigCLI/Subcommands/Export/PluginIconsExport.swift` — use `SourceFactory.createComponentsSource()`, pass to `IconsExportContextImpl`
- [ ] 4.3 Update `Sources/ExFigCLI/Subcommands/Export/PluginImagesExport.swift` — use `SourceFactory.createComponentsSource()`, pass to `ImagesExportContextImpl`
- [ ] 4.4 Update `Sources/ExFigCLI/Subcommands/Export/PluginTypographyExport.swift` — use `SourceFactory.createTypographySource()`, pass to `TypographyExportContextImpl`
- [ ] 4.5 Update platform export orchestrators (`iOSColorsExport`, `AndroidColorsExport`, `FlutterColorsExport`, `WebColorsExport`, `iOSImagesExport`, `AndroidImagesExport`, `FlutterImagesExport`, `WebImagesExport`) to pass source through if they construct contexts
- [ ] 4.6 Add `ExFigError.unsupportedSourceKind(DesignSourceKind)` for penpot, tokensStudio, sketchFile

## 5. Batch & Download Commands

- [ ] 5.1 Update `BatchConfigRunner` — source instances created per-config via `SourceFactory`
- [ ] 5.2 Update `DownloadColors` — use `SourceFactory.createColorsSource()` dispatch
- [ ] 5.3 Update `DownloadAll.exportColors()` — use source dispatch
- [ ] ~~5.4 Update `DownloadIcons` / `DownloadImages`~~ **DEFERRED** — uses `DownloadImageLoader` (separate code path from export loaders). Follow-up change.
- [ ] ~~5.5 Update `DownloadAll.exportIcons()` / `DownloadAll.exportImages()`~~ **DEFERRED** — same reason as 5.4
- [ ] 5.6 Update MCP tool handlers in `Sources/ExFigCLI/MCP/MCPToolHandlers.swift` — `exfig_download` tool uses loaders directly. **DEFERRED** to follow-up (MCP handlers invoke subprocess for export, which inherits dispatch automatically; only direct loader calls in `exfig_download` need updating)

## 6. PKL Schema Changes

- [ ] 6.1 Add `SourceKind` typealias to `Common.pkl`
- [ ] 6.2 Add optional `sourceKind: SourceKind?` to `FrameSource` in `Common.pkl`
- [ ] 6.3 Add optional `sourceKind: SourceKind?` to `VariablesSource` in `Common.pkl`
- [ ] 6.4 Run `./bin/mise run codegen:pkl` to regenerate Swift types
- [ ] 6.5 Add `DesignSourceKind` bridging in platform entry files (`Sources/ExFig-*/Config/*Entry.swift`)
- [ ] 6.6 Update `colorsSourceInput()` in entry bridge methods — construct `FigmaColorsConfig`/`TokensFileColorsConfig` based on entry fields, wrap in `ColorsSourceInput(sourceKind:sourceConfig:)` with resolution priority: explicit > auto-detect > default `.figma`
- [ ] 6.7 Update `iconsSourceInput()`, `imagesSourceInput()` in entry bridge methods — pass `sourceKind`

## 7. Tests

- [ ] 7.1 Unit tests for `TokensFileColorsSource` — verify identical output to old `ColorsExportContextImpl.loadColorsFromTokensFile()`, including darkModeName warning
- [ ] 7.2 Unit tests for `DesignSourceKind` — allCases, rawValue round-trip
- [ ] 7.3 Unit tests for `SourceFactory` — dispatch logic, unsupported source error
- [ ] 7.4 Unit tests for `ColorsSourceConfig` — verify `FigmaColorsConfig` and `TokensFileColorsConfig` round-trip, cast logic
- [ ] 7.5 Verify `ColorsSourceInput` construction with both config types
- [ ] 7.5 Verify sourceKind resolution priority (explicit > auto-detect > default)
- [ ] 7.6 Update existing `ColorsExportContextImpl` tests if any reference internal methods
- [ ] 7.7 Run full test suite (`./bin/mise run test`) — all existing tests must pass unchanged
- [ ] 7.8 **Note:** `FigmaColorsSource`/`FigmaComponentsSource`/`FigmaTypographySource` require live Figma API — test as integration tests (skipped without `FIGMA_PERSONAL_TOKEN`)

## 8. Verification

- [ ] 8.1 `./bin/mise run build` — clean compile
- [ ] 8.2 `./bin/mise run test` — all tests pass
- [ ] 8.3 `./bin/mise run lint` — no new warnings
- [ ] 8.4 `./bin/mise run format-check` — formatting clean
- [ ] 8.5 E2E: `exfig colors -i exfig.pkl` — identical output to pre-refactoring
- [ ] 8.6 E2E: `exfig batch exfig.pkl` — identical output to pre-refactoring
