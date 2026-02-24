# Tokens File Source Capability

## ADDED Requirements

### Requirement: Parse W3C DTCG Format

The system SHALL parse `.tokens.json` files conforming to the W3C DTCG v2025.10 format. The parser SHALL support
nested token groups, `$type` inheritance from parent groups, and all token types defined in the design-tokens-export
capability (`color`, `dimension`, `number`, `typography`, `fontFamily`, `fontWeight`).

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
- **WHEN** the file is parsed
- **THEN** the parser SHALL produce one color token named "Brand/Primary" with RGB (0.231, 0.510, 0.965)

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
- **WHEN** the file is parsed
- **THEN** the parser SHALL produce two color tokens: "Colors/Red/500" and "Colors/Blue/500"
- **AND** both tokens SHALL inherit `$type: "color"` from the parent group

#### Scenario: Parse composite typography token

- **GIVEN** a `.tokens.json` file containing a typography token with composite `$value`:
  ```json
  {
    "Heading": {
      "H1": {
        "$type": "typography",
        "$value": {
          "fontFamily": ["Inter"],
          "fontWeight": 700,
          "fontSize": { "value": 32, "unit": "px" }
        }
      }
    }
  }
  ```
- **WHEN** the file is parsed
- **THEN** the parser SHALL produce a `TextStyle` with fontName "Inter", fontWeight 700, fontSize 32

#### Scenario: Parse dimension token

- **GIVEN** a `.tokens.json` file containing:
  ```json
  {
    "Spacing": {
      "Medium": {
        "$type": "dimension",
        "$value": { "value": 16, "unit": "px" }
      }
    }
  }
  ```
- **WHEN** the file is parsed
- **THEN** the parser SHALL produce a dimension token with value 16 and unit "px"

#### Scenario: Parse token with extensions

- **GIVEN** a `.tokens.json` file containing a token with `$extensions`
- **WHEN** the file is parsed
- **THEN** the parser SHALL preserve `$extensions` data as metadata on the parsed token
- **AND** `$extensions` SHALL NOT affect the token's resolved value

#### Scenario: Parse token with $deprecated

- **GIVEN** a `.tokens.json` file containing a token with `"$deprecated": true`
- **WHEN** the file is parsed
- **THEN** the parser SHALL mark the token as deprecated
- **AND** the token SHALL still be included in the output (deprecated is metadata, not exclusion)

### Requirement: Group Features ($root, $extends, $deprecated)

The parser SHALL support v2025.10 group features: `$root` tokens within groups, `$extends` for group inheritance,
and `$deprecated` on both tokens and groups.

#### Scenario: Parse group with $root token

- **GIVEN** a `.tokens.json` file containing:
  ```json
  {
    "accent": {
      "$root": {
        "$type": "color",
        "$value": { "colorSpace": "srgb", "components": [0.231, 0.510, 0.965], "hex": "#3b82f6" }
      },
      "light": {
        "$type": "color",
        "$value": { "colorSpace": "srgb", "components": [0.745, 0.843, 0.992], "hex": "#bed7fd" }
      }
    }
  }
  ```
- **WHEN** the file is parsed
- **THEN** the parser SHALL produce tokens "accent.$root" and "accent/light"
- **AND** aliases referencing `{accent.$root}` SHALL resolve to the root token

#### Scenario: Parse group with $extends

- **GIVEN** a `.tokens.json` file containing:
  ```json
  {
    "base": {
      "primary": {
        "$type": "color",
        "$value": { "colorSpace": "srgb", "components": [0, 0, 1], "hex": "#0000ff" }
      }
    },
    "brand": {
      "$extends": "#/base",
      "secondary": {
        "$type": "color",
        "$value": { "colorSpace": "srgb", "components": [1, 0, 0], "hex": "#ff0000" }
      }
    }
  }
  ```
- **WHEN** the file is parsed
- **THEN** "brand" group SHALL inherit "primary" from "base" (deep merge)
- **AND** "brand/secondary" SHALL be added alongside inherited tokens

### Requirement: Source Type in PKL Config

A new `tokensFile` source type SHALL be available in the PKL schema alongside existing Figma sources. The source
SHALL accept a file path to a `.tokens.json` file and optional group filter.

#### Scenario: PKL config with tokensFile source

- **GIVEN** a PKL config with:
  ```pkl
  colors = new Listing {
    new iOS.ColorsEntry {
      source = new Common.TokensFile {
        path = "./design-tokens.tokens.json"
        groupFilter = "Colors/Brand"
      }
    }
  }
  ```
- **WHEN** the config is evaluated
- **THEN** the system SHALL read colors from the specified `.tokens.json` file
- **AND** only tokens under the "Colors/Brand" group SHALL be included

#### Scenario: PKL config with tokensFile and no group filter

- **GIVEN** a PKL config with `tokensFile` source and no `groupFilter`
- **WHEN** the config is evaluated
- **THEN** all color tokens in the file SHALL be included regardless of group path

#### Scenario: tokensFile source validation

- **GIVEN** a PKL config with `tokensFile` source pointing to a non-existent path
- **WHEN** the config is validated
- **THEN** the system SHALL report an error: "Tokens file not found: {path}"

### Requirement: Offline Workflow

When `tokensFile` source is used, the system MUST NOT require Figma API access or the `FIGMA_PERSONAL_TOKEN`
environment variable. The export SHALL complete using only the local file.

#### Scenario: Export without Figma token using tokensFile source

- **GIVEN** a PKL config using only `tokensFile` sources
- **AND** the `FIGMA_PERSONAL_TOKEN` environment variable is not set
- **WHEN** `exfig colors -i config.pkl` is executed
- **THEN** the export SHALL complete successfully
- **AND** no Figma API calls SHALL be made

#### Scenario: Mixed sources with and without Figma

- **GIVEN** a PKL config with one `tokensFile` source and one `variablesColors` source
- **AND** the `FIGMA_PERSONAL_TOKEN` environment variable is set
- **WHEN** `exfig colors -i config.pkl` is executed
- **THEN** the `tokensFile` entry SHALL be processed from the local file
- **AND** the `variablesColors` entry SHALL be processed via Figma API
- **AND** both entries SHALL produce independent output

### Requirement: Token Type Mapping

The parser SHALL map W3C token types to ExFigCore domain models. Unmapped token types SHALL be skipped with a
warning message identifying the token name and unsupported type.

| W3C Token Type | ExFigCore Model | `$value` Format                                          |
| -------------- | --------------- | -------------------------------------------------------- |
| `color`        | `Color`         | Object: `{colorSpace, components, alpha?, hex?}`         |
| `typography`   | `TextStyle`     | Object: `{fontFamily, fontSize, fontWeight, lineHeight?}`|
| `dimension`    | (numeric value) | Object: `{value, unit}` — unit is `"px"` or `"rem"`     |
| `number`       | (numeric value) | Plain JSON number                                        |
| `fontFamily`   | (string value)  | String or array of strings                               |
| `fontWeight`   | (numeric value) | Number (1–1000) or string alias (e.g., "bold")           |

#### Scenario: Color token mapped to Color model

- **GIVEN** a token:
  ```json
  { "$type": "color", "$value": { "colorSpace": "srgb", "components": [0.231, 0.510, 0.965], "hex": "#3b82f6" } }
  ```
- **WHEN** the token is mapped
- **THEN** the result SHALL be a `Color` with red=0.231, green=0.510, blue=0.965, alpha=1.0

#### Scenario: Color token with alpha

- **GIVEN** a token:
  ```json
  { "$type": "color", "$value": { "colorSpace": "srgb", "components": [0.231, 0.510, 0.965], "alpha": 0.502 } }
  ```
- **WHEN** the token is mapped
- **THEN** the result SHALL be a `Color` with alpha=0.502

#### Scenario: Color token with non-sRGB color space

- **GIVEN** a token with `"colorSpace": "display-p3"`
- **WHEN** the token is mapped
- **THEN** the parser SHALL convert from Display P3 to sRGB for ExFigCore `Color` (which uses sRGB internally)
- **OR** emit a warning if conversion is not supported: "Color space 'display-p3' converted to sRGB with possible gamut clipping"

#### Scenario: Dimension token mapped

- **GIVEN** a token:
  ```json
  { "$type": "dimension", "$value": { "value": 16, "unit": "px" } }
  ```
- **WHEN** the token is mapped
- **THEN** the result SHALL be a numeric value 16 with unit "px"

#### Scenario: Typography token mapped to TextStyle

- **GIVEN** a typography token with:
  ```json
  "$value": { "fontFamily": ["Inter"], "fontSize": { "value": 16, "unit": "px" }, "fontWeight": 400 }
  ```
- **WHEN** the token is mapped
- **THEN** the result SHALL be a `TextStyle` with fontName "Inter", fontSize 16.0

#### Scenario: fontWeight as string alias

- **GIVEN** a token `{ "$type": "fontWeight", "$value": "bold" }`
- **WHEN** the token is mapped
- **THEN** the result SHALL resolve "bold" to numeric weight 700

#### Scenario: fontFamily as array

- **GIVEN** a token `{ "$type": "fontFamily", "$value": ["Helvetica", "Arial", "sans-serif"] }`
- **WHEN** the token is mapped
- **THEN** the result SHALL use "Helvetica" as the primary font family

#### Scenario: Unsupported token type produces warning

- **GIVEN** a token `{ "$type": "cubicBezier", "$value": [0.42, 0, 0.58, 1] }`
- **WHEN** the token is mapped
- **THEN** the token SHALL be skipped
- **AND** a warning SHALL be emitted: "Unsupported token type 'cubicBezier' for token '{name}', skipping"

### Requirement: Alias Resolution

The parser SHALL resolve token alias references in `$value` fields. An alias is a string matching the pattern
`"{Group.Subgroup.Token}"`. Resolution SHALL follow the dot-separated path within the same token document.
Circular aliases SHALL be detected and reported as errors.

#### Scenario: Resolve a direct alias

- **GIVEN** a token file containing:
  ```json
  {
    "Primitives": {
      "Blue": {
        "$type": "color",
        "$value": { "colorSpace": "srgb", "components": [0.231, 0.510, 0.965], "hex": "#3b82f6" }
      }
    },
    "Semantic": {
      "Primary": { "$type": "color", "$value": "{Primitives.Blue}" }
    }
  }
  ```
- **WHEN** the file is parsed and aliases are resolved
- **THEN** "Semantic/Primary" SHALL resolve to a `Color` with RGB (0.231, 0.510, 0.965)

#### Scenario: Resolve a chained alias

- **GIVEN** token A references token B, and token B references token C (a concrete value)
- **WHEN** the file is parsed and aliases are resolved
- **THEN** token A SHALL resolve to the concrete value of token C

#### Scenario: Circular alias detected

- **GIVEN** token A references token B, and token B references token A
- **WHEN** the file is parsed
- **THEN** the parser SHALL report an error: "Circular alias detected: {A} -> {B} -> {A}"
- **AND** no tokens SHALL be emitted for the circular chain

#### Scenario: Alias to non-existent token

- **GIVEN** a token with `$value: "{Missing.Token}"`
- **WHEN** the file is parsed
- **THEN** the parser SHALL report an error: "Unresolved alias '{Missing.Token}' in token '{name}'"

#### Scenario: Alias to $root token

- **GIVEN** a token with `$value: "{accent.$root}"`
- **WHEN** the file is parsed
- **THEN** the alias SHALL resolve to the `$root` token within the "accent" group

### Requirement: Validation

The parser SHALL validate the token file structure and report clear, actionable errors for malformed input. Validation
SHALL cover JSON syntax, required fields, and value format conformance.

#### Scenario: Invalid JSON syntax

- **GIVEN** a `.tokens.json` file with malformed JSON (e.g., trailing comma)
- **WHEN** the file is parsed
- **THEN** the parser SHALL report an error including the file path and JSON parse error location

#### Scenario: Token with missing $value

- **GIVEN** a token entry `{ "$type": "color" }` with no `$value` field
- **WHEN** the file is parsed
- **THEN** the parser SHALL report an error: "Token '{name}' has $type but missing $value"

#### Scenario: Color token with invalid value structure

- **GIVEN** a color token with `$value: "#3b82f6"` (plain string instead of object)
- **WHEN** the file is parsed
- **THEN** the parser SHALL report an error: "Invalid color value for token '{name}': expected object with colorSpace and components"

#### Scenario: Color token with missing colorSpace

- **GIVEN** a color token with `$value: { "components": [1, 0, 0] }` (missing colorSpace)
- **WHEN** the file is parsed
- **THEN** the parser SHALL report an error: "Color token '{name}' missing required 'colorSpace' in $value"

#### Scenario: Dimension token with invalid value

- **GIVEN** a dimension token with `$value: 16` (plain number instead of object)
- **WHEN** the file is parsed
- **THEN** the parser SHALL report an error: "Invalid dimension value for token '{name}': expected object with value and unit"

#### Scenario: Empty token file

- **GIVEN** a `.tokens.json` file containing `{}`
- **WHEN** the file is parsed
- **THEN** the parser SHALL produce zero tokens
- **AND** no error SHALL be reported (empty is valid)

#### Scenario: Token file with mixed valid and invalid entries

- **GIVEN** a `.tokens.json` file with 10 valid tokens and 2 invalid tokens
- **WHEN** the file is parsed
- **THEN** the 10 valid tokens SHALL be parsed successfully
- **AND** errors SHALL be reported for each of the 2 invalid tokens with their names and specific issues
