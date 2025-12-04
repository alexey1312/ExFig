# Figma Export

Raw data export capabilities for Figma API responses.

## ADDED Requirements

### Requirement: Download Command

The system SHALL provide a `download` command to fetch raw Figma API data without processing.

#### Scenario: Download colors as JSON

- **WHEN** running `exfig download colors -o colors.json`
- **THEN** raw color data from Figma API is saved to `colors.json`
- **AND** the file contains valid JSON with metadata wrapper

#### Scenario: Download all data types

- **WHEN** running `exfig download all -o ./raw/`
- **THEN** separate JSON files are created for colors, icons, images, and typography
- **AND** each file is named `{type}.json`

#### Scenario: Download with compact output

- **WHEN** running `exfig download colors -o colors.json --compact`
- **THEN** JSON is saved without whitespace formatting

### Requirement: JSON Metadata Wrapper

The system SHALL wrap raw API data with export metadata.

#### Scenario: Metadata structure

- **WHEN** any download command completes
- **THEN** the output JSON contains a `meta` object with:
  - `exportedAt`: ISO 8601 timestamp
  - `figmaFileKey`: The Figma file identifier
  - `figmaFileVersion`: The file version at export time
  - `exfigVersion`: The ExFig version used
  - `dataType`: The type of data exported

#### Scenario: Data preservation

- **WHEN** downloading raw data
- **THEN** the `data` field contains unmodified Figma API response
- **AND** no transformations or filtering are applied

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
