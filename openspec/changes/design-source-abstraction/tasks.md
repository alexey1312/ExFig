## 1. Core Protocols & Types (ExFigCore)

- [ ] 1.1 Create `DesignSourceKind` enum in `Sources/ExFigCore/Protocol/DesignSource.swift` (figma, penpot, tokensFile, tokensStudio, sketchFile)
- [ ] 1.2 Define `ColorsSource` protocol in the same file
- [ ] 1.3 Define `ComponentsSource` protocol (loadIcons + loadImages)
- [ ] 1.4 Define `TypographySource` protocol
- [ ] 1.5 Add `sourceKind: DesignSourceKind` field (default `.figma`) to `ColorsSourceInput`
- [ ] 1.6 Add `sourceKind: DesignSourceKind` field (default `.figma`) to `IconsSourceInput`
- [ ] 1.7 Add `sourceKind: DesignSourceKind` field (default `.figma`) to `ImagesSourceInput`
- [ ] 1.8 Add `sourceKind: DesignSourceKind` field (default `.figma`) to `TypographySourceInput`
- [ ] 1.9 Verify ExFigCore compiles without FigmaAPI import (`./bin/mise run build`)

## 2. Figma Source Implementations (ExFigCLI)

- [ ] 2.1 Create `Sources/ExFigCLI/Source/FigmaColorsSource.swift` — extract `loadColorsFromFigma()` from `ColorsExportContextImpl`
- [ ] 2.2 Create `Sources/ExFigCLI/Source/TokensFileColorsSource.swift` — extract `loadColorsFromTokensFile()` from `ColorsExportContextImpl`
- [ ] 2.3 Create `Sources/ExFigCLI/Source/FigmaComponentsSource.swift` — wrap `IconsLoader`/`ImagesLoader` via `ImageLoaderBase`
- [ ] 2.4 Create `Sources/ExFigCLI/Source/FigmaTypographySource.swift` — wrap `TextStylesLoader`
- [ ] 2.5 Verify all source implementations compile (`./bin/mise run build`)

## 3. Context Refactoring (ExFigCLI)

- [ ] 3.1 Refactor `ColorsExportContextImpl` — accept `colorsSource: any ColorsSource`, delegate `loadColors()`
- [ ] 3.2 Refactor `IconsExportContextImpl` — accept `componentsSource: any ComponentsSource`, delegate `loadIcons()`
- [ ] 3.3 Refactor `ImagesExportContextImpl` — accept `componentsSource: any ComponentsSource`, delegate `loadImages()`
- [ ] 3.4 Refactor `TypographyExportContextImpl` — accept `typographySource: any TypographySource`, delegate `loadTypography()`
- [ ] 3.5 Verify all context implementations compile (`./bin/mise run build`)

## 4. Source Factories in Subcommands

- [ ] 4.1 Update `ExportColors` subcommand — create `FigmaColorsSource` or `TokensFileColorsSource` based on config, pass to context
- [ ] 4.2 Update `ExportIcons` subcommand — create `FigmaComponentsSource`, pass to context
- [ ] 4.3 Update `ExportImages` subcommand — create `FigmaComponentsSource`, pass to context
- [ ] 4.4 Update `ExportTypography` subcommand — create `FigmaTypographySource`, pass to context
- [ ] 4.5 Update platform export orchestrators (`iOSColorsExport`, `AndroidColorsExport`, `FlutterColorsExport`, `WebColorsExport`) to pass source through
- [ ] 4.6 Add error for unsupported `sourceKind` values (penpot, tokensStudio, sketchFile)

## 5. Batch & Download Commands

- [ ] 5.1 Update `BatchConfigRunner` — create source instances per-config
- [ ] 5.2 Update `DownloadColors` — use source dispatch (FigmaColorsSource / TokensFileColorsSource)
- [ ] 5.3 Update `DownloadAll.exportColors()` — use source dispatch
- [ ] 5.4 Update `DownloadIcons` / `DownloadImages` — create `FigmaComponentsSource`
- [ ] 5.5 Update `DownloadAll.exportIcons()` / `DownloadAll.exportImages()` — pass source through

## 6. PKL Schema Changes

- [ ] 6.1 Add `SourceKind` typealias to `Common.pkl`
- [ ] 6.2 Add optional `sourceKind: SourceKind?` to `FrameSource` in `Common.pkl`
- [ ] 6.3 Add optional `sourceKind: SourceKind?` to `VariablesSource` in `Common.pkl`
- [ ] 6.4 Run `./bin/mise run codegen:pkl` to regenerate Swift types
- [ ] 6.5 Add `DesignSourceKind` bridging in platform entry files (`Sources/ExFig-*/Config/*Entry.swift`)
- [ ] 6.6 Update `*SourceInput` construction in entry bridge methods (`iconsSourceInput()`, `imagesSourceInput()`, `colorsSourceInput()`) to pass `sourceKind`

## 7. Tests

- [ ] 7.1 Unit tests for `FigmaColorsSource` — verify identical output to old `ColorsExportContextImpl.loadColorsFromFigma()`
- [ ] 7.2 Unit tests for `TokensFileColorsSource` — verify identical output to old `loadColorsFromTokensFile()`
- [ ] 7.3 Unit tests for `DesignSourceKind` — allCases, rawValue round-trip
- [ ] 7.4 Verify `ColorsSourceInput` default `sourceKind == .figma`
- [ ] 7.5 Update existing `ColorsExportContextImpl` tests if any reference internal methods
- [ ] 7.6 Run full test suite (`./bin/mise run test`) — all existing tests must pass unchanged

## 8. Verification

- [ ] 8.1 `./bin/mise run build` — clean compile
- [ ] 8.2 `./bin/mise run test` — all tests pass
- [ ] 8.3 `./bin/mise run lint` — no new warnings
- [ ] 8.4 `./bin/mise run format-check` — formatting clean
- [ ] 8.5 E2E: `exfig colors -i exfig.pkl` — identical output to pre-refactoring
- [ ] 8.6 E2E: `exfig batch exfig.pkl` — identical output to pre-refactoring
