## ADDED Requirements

### Requirement: PKL Configuration Format

The system SHALL use PKL (Programmable, Scalable, Safe) as the configuration format, replacing YAML.

#### Scenario: Load basic PKL configuration

- **GIVEN** a file `exfig.pkl` exists in the current directory
- **AND** the file contains valid PKL syntax with `amends` declaration
- **WHEN** `exfig colors` is executed without `-i` option
- **THEN** the system loads and evaluates `exfig.pkl`
- **AND** exports proceed using the parsed configuration

#### Scenario: Load PKL configuration with explicit path

- **GIVEN** a file `configs/ios.pkl` exists
- **WHEN** `exfig colors -i configs/ios.pkl` is executed
- **THEN** the system loads and evaluates `configs/ios.pkl`

#### Scenario: PKL file not found

- **GIVEN** no `exfig.pkl` file exists in the current directory
- **AND** no `-i` option is provided
- **WHEN** `exfig colors` is executed
- **THEN** the system exits with error "Config file not found. Create exfig.pkl, or specify path with -i option."

#### Scenario: PKL syntax error

- **GIVEN** a file `exfig.pkl` with invalid PKL syntax
- **WHEN** `exfig colors -i exfig.pkl` is executed
- **THEN** the system exits with error containing PKL evaluation error message
- **AND** the error includes line number and column from PKL

### Requirement: PKL CLI Dependency

The system SHALL require PKL CLI to be installed separately via mise.

#### Scenario: PKL CLI found via mise shims

- **GIVEN** pkl is installed via `mise use pkl`
- **AND** mise shims are in standard location `~/.local/share/mise/shims/pkl`
- **WHEN** ExFig evaluates a PKL config
- **THEN** the system uses the mise-installed pkl

#### Scenario: PKL CLI found in PATH

- **GIVEN** pkl is installed and available in system PATH
- **AND** mise shims do not exist
- **WHEN** ExFig evaluates a PKL config
- **THEN** the system uses pkl from PATH

#### Scenario: PKL CLI not installed

- **GIVEN** pkl is not installed via mise
- **AND** pkl is not in system PATH
- **WHEN** `exfig colors -i exfig.pkl` is executed
- **THEN** the system exits with error "pkl not found. Install with: mise use pkl"

### Requirement: PKL Configuration Inheritance

The system SHALL support PKL's native `amends` mechanism for configuration inheritance.

#### Scenario: Single-level inheritance

- **GIVEN** a base config `base.pkl` with `figma.lightFileId = "ABC"`
- **AND** a derived config `ios.pkl` with `amends "base.pkl"` and `ios.colors.assetsFolder = "Colors"`
- **WHEN** `exfig colors -i ios.pkl` is executed
- **THEN** the system uses `figma.lightFileId = "ABC"` from base
- **AND** the system uses `ios.colors.assetsFolder = "Colors"` from derived

#### Scenario: Multi-level inheritance

- **GIVEN** `base.pkl` defines common Figma settings
- **AND** `platform.pkl` amends `base.pkl` and adds platform-specific paths
- **AND** `project.pkl` amends `platform.pkl` and overrides specific values
- **WHEN** `exfig colors -i project.pkl` is executed
- **THEN** settings are merged with later files overriding earlier ones

#### Scenario: Remote schema inheritance

- **GIVEN** a config with `amends "package://github.com/niceplaces/exfig/releases/download/schemas-v2.0.0/exfig-schemas@2.0.0#/ExFig.pkl"`
- **WHEN** `exfig colors -i exfig.pkl` is executed
- **THEN** PKL fetches and caches the remote schema
- **AND** configuration is validated against the schema types

### Requirement: PKL Schema Validation

The system SHALL validate configuration against PKL schemas at evaluation time.

#### Scenario: Missing required field

- **GIVEN** a PKL config without required `ios.xcodeprojPath` field
- **AND** the schema defines `xcodeprojPath: String` as required
- **WHEN** `exfig colors -i exfig.pkl` is executed
- **THEN** PKL evaluation fails with type error
- **AND** error message indicates missing required field

#### Scenario: Invalid field type

- **GIVEN** a PKL config with `figma.timeout = "fast"` (string instead of number)
- **AND** the schema defines `timeout: Duration?`
- **WHEN** `exfig colors -i exfig.pkl` is executed
- **THEN** PKL evaluation fails with type error
- **AND** error message indicates type mismatch

#### Scenario: Valid configuration passes

- **GIVEN** a PKL config with all required fields
- **AND** all field types match schema definitions
- **WHEN** `exfig colors -i exfig.pkl` is executed
- **THEN** configuration is loaded successfully

### Requirement: Batch PKL Configuration Discovery

The system SHALL discover `.pkl` configuration files in batch mode.

#### Scenario: Discover PKL files in directory

- **GIVEN** a directory `configs/` containing `ios.pkl`, `android.pkl`, and `README.md`
- **WHEN** `exfig batch configs/` is executed
- **THEN** the system discovers `ios.pkl` and `android.pkl`
- **AND** `README.md` is ignored

#### Scenario: Validate PKL configs in batch

- **GIVEN** a directory with `valid.pkl` and `invalid.pkl`
- **AND** `invalid.pkl` has syntax errors
- **WHEN** `exfig batch configs/` is executed
- **THEN** `valid.pkl` is processed successfully
- **AND** `invalid.pkl` reports evaluation error
- **AND** batch continues with remaining configs

### Requirement: PKL to JSON Evaluation

The system SHALL evaluate PKL configurations to JSON for internal processing.

#### Scenario: PKL output as JSON

- **GIVEN** a valid PKL configuration file
- **WHEN** the system evaluates the configuration
- **THEN** pkl is invoked with `--format json` flag
- **AND** JSON output is parsed into internal Params structure

#### Scenario: Large configuration evaluation

- **GIVEN** a PKL config with 50+ color entries across multiple platforms
- **WHEN** the system evaluates the configuration
- **THEN** all entries are correctly parsed from JSON
- **AND** evaluation completes within 1 second

---

## Plugin Architecture Requirements

### Requirement: Platform Plugin Registration

The system SHALL support platform plugins for extensible export functionality.

#### Scenario: iOS plugin registers exporters

- **GIVEN** the ExFig-iOS plugin is linked
- **WHEN** ExFigCLI initializes the plugin registry
- **THEN** iOSColorsExporter, iOSIconsExporter, iOSImagesExporter, iOSTypographyExporter are registered
- **AND** plugin identifier is "ios"

#### Scenario: Android plugin registers exporters

- **GIVEN** the ExFig-Android plugin is linked
- **WHEN** ExFigCLI initializes the plugin registry
- **THEN** AndroidColorsExporter, AndroidIconsExporter, AndroidImagesExporter, AndroidTypographyExporter are registered
- **AND** plugin identifier is "android"

#### Scenario: Plugin provides config keys

- **GIVEN** the iOS plugin is registered
- **WHEN** PluginRegistry is queried for iOS config keys
- **THEN** the system returns `["ios.colors", "ios.icons", "ios.images", "ios.typography"]`

### Requirement: AssetExporter Protocol

The system SHALL use a unified AssetExporter protocol for all export operations.

#### Scenario: Export colors using plugin

- **GIVEN** a PKL config with `ios.colors` section
- **AND** the iOS plugin is registered
- **WHEN** `exfig colors -i exfig.pkl` is executed
- **THEN** the system routes to iOSColorsExporter
- **AND** exporter calls load(), process(), export() in sequence

#### Scenario: Exporter load phase

- **GIVEN** a valid iOSColorsEntry configuration
- **WHEN** iOSColorsExporter.load() is called
- **THEN** the exporter fetches data from Figma API using FigmaClient
- **AND** returns LoaderOutput with raw color data

#### Scenario: Exporter process phase

- **GIVEN** LoaderOutput from load phase
- **WHEN** iOSColorsExporter.process() is called
- **THEN** the exporter transforms raw data into [Color] domain models
- **AND** applies name validation/replacement from config

#### Scenario: Exporter export phase

- **GIVEN** processed [Color] output
- **WHEN** iOSColorsExporter.export() is called
- **THEN** the exporter generates xcassets and/or Swift files
- **AND** returns ExportResult with written file paths

### Requirement: Shared SourceConfig

The system SHALL use a common SourceConfig structure for Figma source fields.

#### Scenario: SourceConfig in iOS entry

- **GIVEN** a PKL config with iOS colors entry containing `source` section
- **WHEN** the configuration is parsed
- **THEN** `source.tokensFileId`, `source.lightModeName`, etc. are extracted
- **AND** iOS-specific fields (`useColorAssets`, `assetsFolder`) are separate from source

#### Scenario: SourceConfig inheritance from common

- **GIVEN** a PKL config with `common.variablesColors` defined
- **AND** an iOS entry without explicit `source` section
- **WHEN** the configuration is parsed
- **THEN** source fields are inherited from `common.variablesColors`

#### Scenario: SourceConfig fields list

- **GIVEN** the SourceConfig type
- **THEN** it SHALL contain these Figma Variables fields:
  - `tokensFileId: String?`
  - `tokensCollectionName: String?`
  - `lightModeName: String?`
  - `darkModeName: String?`
  - `lightHCModeName: String?`
  - `darkHCModeName: String?`
  - `primitivesModeName: String?`
- **AND** these Figma Frame fields:
  - `figmaFrameName: String?`
  - `sourceFormat: SourceFormat?`
- **AND** these name processing fields:
  - `nameValidateRegexp: String?`
  - `nameReplaceRegexp: String?`

### Requirement: AssetConfiguration Generic Type

The system SHALL use AssetConfiguration<Entry> for single/multiple entry decoding.

#### Scenario: Single entry configuration

- **GIVEN** a PKL config with `ios.colors` as single object (not array)
- **WHEN** the configuration is decoded
- **THEN** AssetConfiguration decodes as `.single(entry)`
- **AND** `configuration.entries` returns `[entry]`

#### Scenario: Multiple entries configuration

- **GIVEN** a PKL config with `ios.colors` as array of objects
- **WHEN** the configuration is decoded
- **THEN** AssetConfiguration decodes as `.multiple(entries)`
- **AND** `configuration.entries` returns all entries

#### Scenario: Mixed platforms single/multiple

- **GIVEN** a PKL config with `ios.colors` as single and `android.colors` as array
- **WHEN** the configuration is decoded
- **THEN** iOS uses `.single` and Android uses `.multiple`
- **AND** both platforms export correctly

### Requirement: Plugin Independence

The system SHALL support independent compilation of each plugin module.

#### Scenario: Build iOS plugin independently

- **GIVEN** the ExFig-iOS target in Package.swift
- **WHEN** `swift build --target ExFig-iOS` is executed
- **THEN** the build succeeds without building other plugins

#### Scenario: Test iOS plugin in isolation

- **GIVEN** the ExFig-iOSTests target in Package.swift
- **WHEN** `swift test --filter ExFig-iOSTests` is executed
- **THEN** iOS plugin tests run without requiring Android/Flutter/Web plugins

### Requirement: PluginRegistry

The system SHALL use PluginRegistry to manage available plugins.

#### Scenario: Register all plugins at startup

- **GIVEN** ExFigCLI executable starts
- **WHEN** main() initializes
- **THEN** PluginRegistry registers iOS, Android, Flutter, Web plugins
- **AND** all plugins are available for export commands

#### Scenario: Route export to correct plugin

- **GIVEN** a PKL config with only `ios.colors` section
- **WHEN** `exfig colors -i exfig.pkl` is executed
- **THEN** PluginRegistry routes to iOSPlugin only
- **AND** Android, Flutter, Web plugins are not invoked

#### Scenario: Export multiple platforms

- **GIVEN** a PKL config with `ios.colors` and `android.colors` sections
- **WHEN** `exfig colors -i exfig.pkl` is executed
- **THEN** PluginRegistry invokes both iOSPlugin and AndroidPlugin
- **AND** each plugin exports its colors independently
