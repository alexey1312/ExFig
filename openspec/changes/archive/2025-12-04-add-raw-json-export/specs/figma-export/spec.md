# JSON Export

JSON export capabilities for Figma design data with W3C Design Tokens support.

## ADDED Requirements

### Requirement: Download Command

The system SHALL provide a `download` command to fetch Figma design data as JSON.

#### Scenario: Download colors as W3C tokens (default)

- **WHEN** running `exfig download colors -o colors.json`
- **THEN** color data is saved in W3C Design Tokens format
- **AND** the file contains valid JSON with `$type`, `$value`, and optional `$description`

#### Scenario: Download colors as raw Figma JSON

- **WHEN** running `exfig download colors -o colors.json --format raw`
- **THEN** raw Figma API response is saved with metadata wrapper
- **AND** the `data` field contains unmodified Figma API response

#### Scenario: Download all data types

- **WHEN** running `exfig download all -o ./tokens/`
- **THEN** separate JSON files are created for colors, icons, images, and typography
- **AND** each file is named `{type}.json`

#### Scenario: Download with compact output

- **WHEN** running `exfig download colors -o colors.json --compact`
- **THEN** JSON is saved without whitespace formatting

### Requirement: W3C Design Tokens Format

The system SHALL support W3C Design Tokens format as the default output.

#### Scenario: Color token structure

- **WHEN** exporting colors in W3C format
- **THEN** each token has `$type` set to `"color"`
- **AND** `$value` contains mode variants as keys (e.g., `"Light"`, `"Dark"`)
- **AND** color values are hex strings (#RRGGBB or #RRGGBBAA)

#### Scenario: Token hierarchy from variable names

- **WHEN** a Figma variable is named `Statement/Background/PrimaryPressed`
- **THEN** it becomes nested JSON: `{ "Statement": { "Background": { "PrimaryPressed": { ... } } } }`

#### Scenario: Variable alias resolution

- **WHEN** a Figma variable references another via VARIABLE_ALIAS
- **THEN** the alias is resolved to the final concrete value
- **AND** the output contains the resolved value, not the alias reference

#### Scenario: Token description

- **WHEN** a Figma variable has a description
- **THEN** the token includes `$description` field with that text

### Requirement: Typography Tokens

The system SHALL export typography data as W3C Design Tokens.

#### Scenario: Typography token structure

- **WHEN** exporting typography in W3C format
- **THEN** each token has `$type` set to `"typography"`
- **AND** `$value` contains font properties (fontFamily, fontSize, fontWeight, lineHeight, letterSpacing)

### Requirement: Asset Tokens

The system SHALL export icons and images as W3C asset tokens with Figma export URLs.

#### Scenario: Icon token with format selection

- **WHEN** running `exfig download icons -o icons.json --asset-format svg`
- **THEN** each token has `$type` set to `"asset"`
- **AND** `$value` contains the Figma export URL for SVG format

#### Scenario: Image token with format selection

- **WHEN** running `exfig download images -o images.json --asset-format png`
- **THEN** each token has `$type` set to `"asset"`
- **AND** `$value` contains the Figma export URL for PNG format

#### Scenario: Asset format default

- **WHEN** no `--asset-format` is specified
- **THEN** PNG format at 3x scale is used by default

#### Scenario: Asset scale option

- **WHEN** running `exfig download images --asset-format png --scale 2`
- **THEN** `$value` contains the Figma export URL for PNG at 2x scale

#### Scenario: Supported asset formats

- **WHEN** specifying `--asset-format`
- **THEN** supported values are: `svg`, `png`, `pdf`, `jpg`

### Requirement: Raw Format with Metadata

The system SHALL wrap raw API data with export metadata when using `--format raw`.

#### Scenario: Raw metadata structure

- **WHEN** downloading with `--format raw`
- **THEN** the output JSON contains a `source` object with:
  - `name`: The Figma file name
  - `fileId`: The Figma file identifier
  - `exportedAt`: ISO 8601 timestamp
  - `exfigVersion`: The ExFig version used
- **AND** contains a `data` object with unmodified Figma API response

### Requirement: Output Path Handling

The system SHALL support flexible output path configuration.

#### Scenario: File output

- **WHEN** `-o` specifies a file path ending in `.json`
- **THEN** data is written to that exact file path

#### Scenario: Directory output

- **WHEN** `-o` specifies a directory path
- **THEN** data is written to `{directory}/{type}.json`

#### Scenario: Default output

- **WHEN** no `-o` option is provided
- **THEN** data is written to `./{type}.json` in current directory
