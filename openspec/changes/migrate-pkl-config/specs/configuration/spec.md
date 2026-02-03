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
