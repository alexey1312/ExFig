## ADDED Requirements

### Requirement: Context implementations accept injected sources

Each `*ExportContextImpl` (`ColorsExportContextImpl`, `IconsExportContextImpl`, `ImagesExportContextImpl`, `TypographyExportContextImpl`) SHALL accept the corresponding source protocol via constructor injection instead of a raw `Client`.

#### Scenario: ColorsExportContextImpl accepts ColorsSource

- **WHEN** `ColorsExportContextImpl` is constructed
- **THEN** it SHALL accept a `colorsSource: any ColorsSource` parameter
- **AND** its `loadColors()` method SHALL delegate to `colorsSource.loadColors()`

#### Scenario: IconsExportContextImpl accepts ComponentsSource

- **WHEN** `IconsExportContextImpl` is constructed
- **THEN** it SHALL accept a `componentsSource: any ComponentsSource` parameter
- **AND** its `loadIcons()` method SHALL delegate to `componentsSource.loadIcons()`

#### Scenario: ImagesExportContextImpl accepts ComponentsSource

- **WHEN** `ImagesExportContextImpl` is constructed
- **THEN** it SHALL accept a `componentsSource: any ComponentsSource` parameter
- **AND** its `loadImages()` method SHALL delegate to `componentsSource.loadImages()`

#### Scenario: TypographyExportContextImpl accepts TypographySource

- **WHEN** `TypographyExportContextImpl` is constructed
- **THEN** it SHALL accept a `typographySource: any TypographySource` parameter
- **AND** its `loadTypography()` method SHALL delegate to `typographySource.loadTypography()`

### Requirement: Source factory in subcommands

Each export subcommand (`ExportColors`, `ExportIcons`, `ExportImages`, `ExportTypography`) SHALL create the appropriate source implementation based on the resolved configuration before constructing the context.

#### Scenario: Colors subcommand creates FigmaColorsSource by default

- **WHEN** `ExportColors` runs with a PKL config that has `figma {}` section and no `tokensFilePath`
- **THEN** it SHALL create a `FigmaColorsSource` and inject it into `ColorsExportContextImpl`

#### Scenario: Colors subcommand creates TokensFileColorsSource when tokensFilePath is set

- **WHEN** `ExportColors` runs with a PKL config entry that has `tokensFilePath` set
- **THEN** it SHALL create a `TokensFileColorsSource` and inject it into `ColorsExportContextImpl`

#### Scenario: Icons subcommand creates FigmaComponentsSource

- **WHEN** `ExportIcons` runs with a PKL config that has `figma {}` section
- **THEN** it SHALL create a `FigmaComponentsSource` and inject it into `IconsExportContextImpl`

#### Scenario: Unsupported sourceKind produces clear error

- **WHEN** a subcommand encounters `sourceKind` set to `.penpot` (not yet implemented)
- **THEN** it SHALL throw an error with a message indicating that Penpot source is not yet supported

### Requirement: Batch runner source creation

`BatchConfigRunner` SHALL create source implementations per-config and pass them through `ConfigExecutionContext` or directly to context implementations.

#### Scenario: Batch mode creates sources per config

- **WHEN** batch mode processes multiple PKL configs
- **THEN** each config SHALL get its own source instances
- **AND** sources SHALL NOT be shared across configs

#### Scenario: Batch mode preserves existing behavior

- **WHEN** batch mode runs with Figma-only configs (no `tokensFilePath`, default `sourceKind`)
- **THEN** the export results SHALL be identical to the current implementation without source abstraction

### Requirement: Download commands use source dispatch

Download commands (`DownloadColors`, `DownloadIcons`, `DownloadImages`, `DownloadAll`) SHALL use the same source dispatch logic as export commands.

#### Scenario: DownloadColors dispatches to correct source

- **WHEN** `download colors` runs with a config containing `tokensFilePath`
- **THEN** it SHALL use `TokensFileColorsSource` for loading colors

#### Scenario: DownloadAll dispatches per asset type

- **WHEN** `download all` runs with a config
- **THEN** it SHALL create appropriate source instances for each asset type (colors, icons, images, typography)
