## ADDED Requirements

### Requirement: Context implementations accept injected sources

Each `*ExportContextImpl` (`ColorsExportContextImpl`, `IconsExportContextImpl`, `ImagesExportContextImpl`, `TypographyExportContextImpl`) SHALL accept the corresponding source protocol via constructor injection.

#### Scenario: ColorsExportContextImpl accepts ColorsSource

- **WHEN** `ColorsExportContextImpl` is constructed
- **THEN** it SHALL accept a `colorsSource: any ColorsSource` parameter instead of `client: Client`
- **AND** its `loadColors()` method SHALL delegate to `colorsSource.loadColors()`
- **AND** it SHALL NOT contain source-specific dispatch logic (no `if tokensFilePath`)

#### Scenario: IconsExportContextImpl accepts ComponentsSource alongside Client

- **WHEN** `IconsExportContextImpl` is constructed
- **THEN** it SHALL accept a `componentsSource: any ComponentsSource` parameter
- **AND** it SHALL retain `client: Client` for the granular cache path (`loadIconsWithGranularCache()`)
- **AND** its basic `loadIcons()` method SHALL delegate to `componentsSource.loadIcons()`

#### Scenario: ImagesExportContextImpl accepts ComponentsSource alongside Client

- **WHEN** `ImagesExportContextImpl` is constructed
- **THEN** it SHALL accept a `componentsSource: any ComponentsSource` parameter
- **AND** it SHALL retain `client: Client` for the granular cache path (`loadImagesWithGranularCache()`)
- **AND** its basic `loadImages()` method SHALL delegate to `componentsSource.loadImages()`

#### Scenario: TypographyExportContextImpl accepts TypographySource

- **WHEN** `TypographyExportContextImpl` is constructed
- **THEN** it SHALL accept a `typographySource: any TypographySource` parameter instead of `client: Client`
- **AND** its `loadTypography()` method SHALL delegate to `typographySource.loadTypography()`

### Requirement: Centralized SourceFactory

The system SHALL provide a `SourceFactory` enum in `Sources/ExFigCLI/Source/SourceFactory.swift` with static methods for creating source instances:

```swift
enum SourceFactory {
    static func createColorsSource(for input: ColorsSourceInput, client: Client, ui: TerminalUI, filter: String?) -> any ColorsSource
    static func createComponentsSource(for sourceKind: DesignSourceKind, ...) -> any ComponentsSource
    static func createTypographySource(for sourceKind: DesignSourceKind, ...) -> any TypographySource
}
```

#### Scenario: Factory dispatches by sourceKind

- **WHEN** `SourceFactory.createColorsSource()` is called with `sourceKind == .figma`
- **THEN** it SHALL return a `FigmaColorsSource` instance

#### Scenario: Factory dispatches tokensFile

- **WHEN** `SourceFactory.createColorsSource()` is called with `sourceKind == .tokensFile`
- **THEN** it SHALL return a `TokensFileColorsSource` instance

#### Scenario: Factory throws for unsupported sourceKind

- **WHEN** `SourceFactory.createColorsSource()` is called with `sourceKind == .penpot`
- **THEN** it SHALL throw `ExFigError.unsupportedSourceKind(.penpot)`

### Requirement: Source factories used in Plugin*Export files

Each plugin export orchestrator (`PluginColorsExport.swift`, `PluginIconsExport.swift`, `PluginImagesExport.swift`, `PluginTypographyExport.swift`) SHALL use `SourceFactory` to create sources before constructing context implementations.

#### Scenario: PluginColorsExport uses SourceFactory

- **WHEN** `exportiOSColorsViaPlugin()` in `PluginColorsExport.swift` runs
- **THEN** it SHALL call `SourceFactory.createColorsSource()` and pass the result to `ColorsExportContextImpl`

#### Scenario: PluginIconsExport uses SourceFactory

- **WHEN** `exportiOSIconsViaPlugin()` in `PluginIconsExport.swift` runs
- **THEN** it SHALL call `SourceFactory.createComponentsSource()` and pass the result to `IconsExportContextImpl`

### Requirement: Batch runner source creation

`BatchConfigRunner` SHALL create source implementations per-config via `SourceFactory` and pass them through `ConfigExecutionContext` or directly to context implementations.

#### Scenario: Batch mode creates sources per config

- **WHEN** batch mode processes multiple PKL configs
- **THEN** each config SHALL get its own source instances
- **AND** sources SHALL NOT be shared across configs

#### Scenario: Batch mode preserves existing behavior

- **WHEN** batch mode runs with Figma-only configs (no `tokensFilePath`, default `sourceKind`)
- **THEN** the export results SHALL be identical to the current implementation without source abstraction

### Requirement: Download colors uses source dispatch

`DownloadColors` and `DownloadAll.exportColors()` SHALL use `SourceFactory` for source creation.

#### Scenario: DownloadColors dispatches to correct source

- **WHEN** `download colors` runs with a config containing `tokensFilePath`
- **THEN** it SHALL use `TokensFileColorsSource` for loading colors

#### Scenario: DownloadAll.exportColors dispatches correctly

- **WHEN** `download all` runs with a config
- **THEN** `exportColors()` SHALL use `SourceFactory.createColorsSource()` for source creation

### DEFERRED: Download icons/images and MCP handlers

Download icons/images commands (`DownloadIcons`, `DownloadImages`, `DownloadAll.exportIcons/exportImages`) use `DownloadImageLoader` — a separate code path from the export loaders (`IconsLoader`/`ImagesLoader`). Abstracting this path is deferred to a follow-up change.

MCP `exfig_download` tool handler uses loaders directly. Export tools (`exfig_export`) invoke subprocess and inherit dispatch automatically. Direct loader calls in `exfig_download` are deferred to the same follow-up change.
