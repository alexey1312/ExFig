# ExFigKit Library

Reusable library module extracted from ExFig CLI for use by GUI and CLI.

## ADDED Requirements

### Requirement: Configuration Model

The system SHALL provide a `Params` struct representing ExFig configuration with support for all platforms (iOS, Android, Flutter, Web) and asset types (colors, icons, images, typography).

#### Scenario: Decode YAML configuration

- **GIVEN** a valid exfig.yaml file
- **WHEN** the configuration is decoded using YAMLDecoder
- **THEN** a Params instance is created with all platform settings

#### Scenario: Support single and multiple entry formats

- **GIVEN** icons configuration in either legacy (single object) or modern (array) format
- **WHEN** the configuration is parsed
- **THEN** both formats are supported via IconsConfiguration enum

### Requirement: Asset Loaders

The system SHALL provide loaders for fetching assets from Figma API: ColorsLoader, ColorsVariablesLoader, IconsLoader, ImagesLoader, TextStylesLoader.

#### Scenario: Load colors from Figma Variables

- **GIVEN** a Figma file with Variables collection
- **WHEN** ColorsVariablesLoader.load() is called
- **THEN** colors with light/dark modes are returned

#### Scenario: Load icons with batch progress

- **GIVEN** a Figma file with icon components
- **WHEN** IconsLoader.load(onBatchProgress:) is called
- **THEN** icons are returned and progress callback is invoked for each batch

### Requirement: File Output

The system SHALL provide FileWriter for writing exported files to disk, and converters for image format conversion (WebP, HEIC, PNG).

#### Scenario: Write files atomically

- **GIVEN** a list of FileContents to write
- **WHEN** FileWriter.write(files:) is called
- **THEN** files are written atomically with directory creation

#### Scenario: Convert SVG to HEIC

- **GIVEN** an SVG image and HEIC options (lossy/lossless, quality)
- **WHEN** SvgToHeicConverter.convert() is called
- **THEN** HEIC data is returned at configured quality

### Requirement: Progress Reporting Protocol

The system SHALL provide a ProgressReporter protocol for reporting export progress, warnings, and errors.

#### Scenario: Report export progress

- **GIVEN** an export operation in progress
- **WHEN** a phase changes (fetching, processing, downloading, writing)
- **THEN** ProgressReporter.reportProgress() is called with phase details

#### Scenario: Report warnings without stopping

- **GIVEN** a non-fatal issue during export (e.g., missing optional config)
- **WHEN** the issue is detected
- **THEN** ProgressReporter.reportWarning() is called and export continues

### Requirement: Cache Management

The system SHALL provide version tracking and granular cache for skipping unchanged assets.

#### Scenario: Skip export when file unchanged

- **GIVEN** cache is enabled and file version matches cached version
- **WHEN** export is requested
- **THEN** export is skipped and cache hit is reported

#### Scenario: Track per-node content hashes

- **GIVEN** granular cache is enabled
- **WHEN** export completes
- **THEN** node content hashes are saved for future comparison
