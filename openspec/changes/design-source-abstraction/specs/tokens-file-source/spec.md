## MODIFIED Requirements

### Requirement: Parse W3C DTCG Format

The system SHALL parse `.tokens.json` files conforming to the W3C DTCG v2025.10 format. The parser SHALL support
nested token groups, `$type` inheritance from parent groups, and all token types defined in the design-tokens-export
capability (`color`, `dimension`, `number`, `typography`, `fontFamily`, `fontWeight`).

The loading logic SHALL be encapsulated in a `TokensFileColorsSource` struct that implements the `ColorsSource` protocol, rather than being an inline method of `ColorsExportContextImpl`.

#### Scenario: Parse a flat color token file

- **GIVEN** a `.tokens.json` file containing:
  ```json
  {
    "Brand": {
      "Primary": {
        "$type": "color",
        "$value": { "colorSpace": "srgb", "components": [0.231, 0.510, 0.965], "hex": "#3b82f6" }
      }
    }
  }
  ```
- **WHEN** `TokensFileColorsSource.loadColors()` is called with a `ColorsSourceInput` where `tokensFilePath` points to this file
- **THEN** the source SHALL return a `ColorsLoadOutput` with one color named "Brand/Primary" in the `light` array

#### Scenario: Parse nested groups with type inheritance

- **GIVEN** a `.tokens.json` file containing:
  ```json
  {
    "Colors": {
      "$type": "color",
      "Red": {
        "500": {
          "$value": { "colorSpace": "srgb", "components": [0.937, 0.267, 0.267], "hex": "#ef4444" }
        }
      },
      "Blue": {
        "500": {
          "$value": { "colorSpace": "srgb", "components": [0.231, 0.510, 0.965], "hex": "#3b82f6" }
        }
      }
    }
  }
  ```
- **WHEN** `TokensFileColorsSource.loadColors()` is called
- **THEN** the source SHALL return two colors: "Colors/Red/500" and "Colors/Blue/500"
- **AND** both tokens SHALL inherit `$type: "color"` from the parent group

#### Scenario: Group filter applied

- **GIVEN** a `.tokens.json` file with tokens under "Brand/Colors" and "Brand/Spacing" groups
- **WHEN** `TokensFileColorsSource.loadColors()` is called with `tokensFileGroupFilter` set to "Brand.Colors"
- **THEN** only tokens under "Brand/Colors" SHALL be returned

#### Scenario: Mode-related fields ignored with warning

- **WHEN** `TokensFileColorsSource.loadColors()` is called with `darkModeName` or `lightHCModeName` set
- **THEN** the source SHALL emit a warning that mode-related fields are ignored for local tokens files
- **AND** `dark`, `lightHC`, `darkHC` arrays SHALL be empty

#### Scenario: TokensFileColorsSource implements ColorsSource

- **WHEN** `TokensFileColorsSource` is instantiated
- **THEN** it SHALL conform to the `ColorsSource` protocol
- **AND** `sourceKind` SHALL be `.tokensFile`
