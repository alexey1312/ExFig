# Configuration

Default values and constraints for PKL configuration schemas.

## ADDED Requirements

### Requirement: iOS default values

iOS PKL schema SHALL provide sensible default values for commonly used fields to reduce boilerplate in configuration files.

#### Scenario: iOS ColorsEntry defaults

- **WHEN** an iOS ColorsEntry does not specify `useColorAssets`
- **THEN** the system SHALL use `true` as the default value

#### Scenario: iOS ColorsEntry nameStyle default

- **WHEN** an iOS ColorsEntry does not specify `nameStyle`
- **THEN** the system SHALL use `"camelCase"` as the default value

#### Scenario: iOS IconsEntry defaults

- **WHEN** an iOS IconsEntry does not specify `format`
- **THEN** the system SHALL use `"pdf"` as the default value

#### Scenario: iOS IconsEntry assetsFolder default

- **WHEN** an iOS IconsEntry does not specify `assetsFolder`
- **THEN** the system SHALL use `"Icons"` as the default value

#### Scenario: iOS ImagesEntry scales default

- **WHEN** an iOS ImagesEntry does not specify `scales`
- **THEN** the system SHALL use `[1, 2, 3]` as the default value

#### Scenario: iOS ImagesEntry format defaults

- **WHEN** an iOS ImagesEntry does not specify `sourceFormat` or `outputFormat`
- **THEN** the system SHALL use `"png"` as the default for both

#### Scenario: iOS iOSConfig xcassetsInMainBundle default

- **WHEN** an iOSConfig does not specify `xcassetsInMainBundle`
- **THEN** the system SHALL use `true` as the default value

### Requirement: Android default values

Android PKL schema SHALL provide sensible default values for commonly used fields.

#### Scenario: Android ImagesEntry format default

- **WHEN** an Android ImagesEntry does not specify `format`
- **THEN** the system SHALL use `"png"` as the default value

#### Scenario: Android IconsEntry nameStyle default

- **WHEN** an Android IconsEntry does not specify `nameStyle`
- **THEN** the system SHALL use `"snake_case"` as the default value

#### Scenario: Android ImagesEntry scales default

- **WHEN** an Android ImagesEntry does not specify `scales`
- **THEN** the system SHALL use `[1, 1.5, 2, 3, 4]` as the default value

#### Scenario: Android ThemeAttributes defaults

- **WHEN** ThemeAttributes does not specify `attrsFile`, `stylesFile`, `stylesNightFile`
- **THEN** the system SHALL use `"values/attrs.xml"`, `"values/styles.xml"`, `"values-night/styles.xml"` respectively

### Requirement: Flutter default values

Flutter PKL schema SHALL provide sensible default values for commonly used fields.

#### Scenario: Flutter ColorsEntry className default

- **WHEN** a Flutter ColorsEntry does not specify `className`
- **THEN** the system SHALL use `"AppColors"` as the default value

#### Scenario: Flutter ImagesEntry scales default

- **WHEN** a Flutter ImagesEntry does not specify `scales`
- **THEN** the system SHALL use `[1, 2, 3]` as the default value

### Requirement: Web default values

Web PKL schema SHALL provide sensible default values for commonly used fields.

#### Scenario: Web IconsEntry defaults

- **WHEN** a Web IconsEntry does not specify `iconSize`
- **THEN** the system SHALL use `24` as the default value

#### Scenario: Web IconsEntry generateReactComponents default

- **WHEN** a Web IconsEntry does not specify `generateReactComponents`
- **THEN** the system SHALL use `true` as the default value

### Requirement: Common and Figma default values

Common and Figma PKL schemas SHALL provide sensible default values.

#### Scenario: Cache defaults

- **WHEN** a Cache config does not specify `enabled` or `path`
- **THEN** the system SHALL use `false` and `".exfig-cache.json"` respectively

#### Scenario: Figma timeout default

- **WHEN** a FigmaConfig does not specify `timeout`
- **THEN** the system SHALL use `30` seconds as the default value

### Requirement: PKL constraints for required string fields

PKL schemas SHALL validate that required string fields are not empty using `!isEmpty` constraint.

#### Scenario: Empty xcodeprojPath rejected

- **WHEN** a PKL config specifies `xcodeprojPath = ""`
- **THEN** `pkl eval` SHALL fail with a constraint violation error

#### Scenario: Empty tokensFileId rejected

- **WHEN** a PKL config specifies `tokensFileId = ""`
- **THEN** `pkl eval` SHALL fail with a constraint violation error

### Requirement: PKL constraints for numeric ranges

PKL schemas SHALL validate numeric fields with appropriate range constraints.

#### Scenario: Figma timeout range

- **WHEN** a PKL config specifies `timeout = 0`
- **THEN** `pkl eval` SHALL fail with a constraint violation error

#### Scenario: Valid Figma timeout

- **WHEN** a PKL config specifies `timeout = 60`
- **THEN** `pkl eval` SHALL succeed

### Requirement: Defaults do not change generated Swift code

Adding default values to PKL schemas SHALL NOT change the generated Swift types (`codegen:pkl` output).

#### Scenario: Zero diff after codegen

- **WHEN** `./bin/mise run codegen:pkl` is run after adding defaults to PKL schemas
- **THEN** the generated `Sources/ExFigConfig/Generated/*.pkl.swift` files SHALL have zero diff
