# Design Tokens Export Capability

## ADDED Requirements

### Requirement: W3C DTCG v2025.10 Color Format

Each color token SHALL have a `$value` object conforming to the v2025.10 Color Module: an object with `colorSpace`
(string), `components` (array of numbers), optional `alpha` (number 0–1, defaults to 1), and optional `hex` (6-digit
sRGB fallback string). Multi-mode colors SHALL use `$extensions.com.exfig.modes` mapping mode names to color objects.
The `$value` field SHALL contain the default mode value.

#### Scenario: Single-mode color token export

- **GIVEN** a color named "Background/Primary" with RGBA (1.0, 1.0, 1.0, 1.0) in light mode only
- **WHEN** the color is exported in W3C v2025 format
- **THEN** the output token SHALL have `"$type": "color"` and `"$value"`:
  ```json
  { "colorSpace": "srgb", "components": [1, 1, 1], "hex": "#ffffff" }
  ```
- **AND** no `$extensions.com.exfig.modes` key SHALL be present

#### Scenario: Multi-mode color token export

- **GIVEN** a color named "Background/Primary" with values (1,1,1,1) in Light and (0.102,0.102,0.102,1) in Dark
- **WHEN** the color is exported in W3C v2025 format
- **THEN** `"$value"` SHALL be the default/first mode color object:
  ```json
  { "colorSpace": "srgb", "components": [1, 1, 1], "hex": "#ffffff" }
  ```
- **AND** `"$extensions.com.exfig"` SHALL contain `"modes"`:
  ```json
  {
    "modes": {
      "Light": { "colorSpace": "srgb", "components": [1, 1, 1], "hex": "#ffffff" },
      "Dark": { "colorSpace": "srgb", "components": [0.102, 0.102, 0.102], "hex": "#1a1a1a" }
    }
  }
  ```

#### Scenario: Color with alpha transparency

- **GIVEN** a color with RGBA values (0.231, 0.541, 0.800, 0.502)
- **WHEN** the color is exported in W3C v2025 format
- **THEN** `"$value"` SHALL be:
  ```json
  { "colorSpace": "srgb", "components": [0.231, 0.541, 0.8], "alpha": 0.502, "hex": "#3b8acc" }
  ```
- **AND** the `hex` field SHALL be 6 digits (no alpha in hex per spec), with alpha in the `alpha` field

#### Scenario: Legacy v1 format preserved with flag

- **GIVEN** a multi-mode color "Background/Primary"
- **WHEN** exported with `--w3c-version v1`
- **THEN** `"$value"` SHALL be a dict mapping mode names to hex values (current behavior)
- **AND** no `$extensions` key SHALL be present

### Requirement: Token Extensions with Figma Metadata

Each token SHALL include `$extensions.com.exfig` with Figma metadata when the source is a Figma file. The metadata
SHALL include `variableId` for variable-sourced tokens and `nodeId` plus `fileId` for component-sourced tokens. The
extension key uses reverse-domain notation (`com.exfig`) per the spec recommendation.

#### Scenario: Variable-sourced color token with extensions

- **GIVEN** a color variable with variableId "VariableID:123:456" from file "abc123"
- **WHEN** the color is exported in W3C v2025 format
- **THEN** `"$extensions"` SHALL contain:
  ```json
  { "com.exfig": { "variableId": "VariableID:123:456", "fileId": "abc123" } }
  ```

#### Scenario: Component-sourced asset token with extensions

- **GIVEN** an icon component with nodeId "1:23" and fileId "def456"
- **WHEN** the asset is exported in W3C v2025 format
- **THEN** `"$extensions"` SHALL contain:
  ```json
  { "com.exfig": { "nodeId": "1:23", "fileId": "def456" } }
  ```

#### Scenario: Extensions merge with mode data

- **GIVEN** a multi-mode color variable with variableId "VariableID:123:456"
- **WHEN** exported in W3C v2025 format
- **THEN** `"$extensions.com.exfig"` SHALL contain both `"modes"` and `"variableId"`/`"fileId"` keys

### Requirement: Token Descriptions

Tokens with Figma variable descriptions SHALL include a `$description` field. Empty or whitespace-only descriptions
MUST NOT produce a `$description` field. The `$description` value MUST be a plain JSON string per the spec.

#### Scenario: Color with description

- **GIVEN** a color variable with description "Primary brand color used for CTA buttons"
- **WHEN** the color is exported in W3C v2025 format
- **THEN** the token SHALL include `"$description": "Primary brand color used for CTA buttons"`

#### Scenario: Color with empty description

- **GIVEN** a color variable with description `""`
- **WHEN** the color is exported in W3C v2025 format
- **THEN** the token MUST NOT include a `"$description"` field

#### Scenario: Typography style with description

- **GIVEN** a text style with description "Heading level 1 for landing pages"
- **WHEN** the style is exported in W3C v2025 format
- **THEN** the token SHALL include `"$description": "Heading level 1 for landing pages"`

### Requirement: Token Aliases

Semantic tokens referencing primitive tokens SHALL use the W3C alias syntax `"{Group.Token}"` in their `$value` field.
The alias path SHALL use dot-separated group names matching the output token hierarchy.

#### Scenario: Semantic color referencing a primitive

- **GIVEN** a semantic variable "Semantic/Primary" aliasing primitive "Primitives/Blue/500" (hex `#3b82f6`)
- **WHEN** exported in W3C v2025 format
- **THEN** the primitive token SHALL have `"$value"` as a color object with `"hex": "#3b82f6"`
- **AND** the semantic token SHALL have `"$value": "{Primitives.Blue.500}"`

#### Scenario: Multi-mode semantic color with alias per mode

- **GIVEN** a semantic variable "Background/Surface" that aliases:
  - Light mode: "Primitives/Gray/50"
  - Dark mode: "Primitives/Gray/900"
- **WHEN** exported in W3C v2025 format
- **THEN** `"$value"` SHALL be `"{Primitives.Gray.50}"` (default mode alias)
- **AND** `"$extensions.com.exfig.modes"` SHALL contain:
  ```json
  { "Light": "{Primitives.Gray.50}", "Dark": "{Primitives.Gray.900}" }
  ```

#### Scenario: Alias resolution disabled with v1 flag

- **GIVEN** a semantic variable aliasing a primitive
- **WHEN** exported with `--w3c-version v1`
- **THEN** the `$value` SHALL contain the resolved hex value (current behavior)
- **AND** no alias reference syntax SHALL appear

### Requirement: No Invented Token Types

The exporter MUST NOT use `$type` values not defined in the W3C DTCG v2025.10 specification. Asset references
SHALL use `$extensions.com.exfig.assetUrl` instead of `$type: "asset"`.

Valid `$type` values: `color`, `dimension`, `fontFamily`, `fontWeight`, `duration`, `cubicBezier`, `number`,
`strokeStyle`, `border`, `transition`, `shadow`, `gradient`, `typography`.

Note: `fontStyle` is acknowledged in the spec as "still to be documented" and SHOULD NOT be used until formally defined.

#### Scenario: Asset token exported without invented type

- **GIVEN** an icon component "Icons/Search" with export URL "https://figma.com/images/..."
- **WHEN** the asset is exported in W3C v2025 format
- **THEN** the token MUST NOT include `"$type": "asset"`
- **AND** `"$extensions.com.exfig.assetUrl"` SHALL contain the export URL

#### Scenario: Asset token with v1 flag preserves legacy type

- **GIVEN** an icon component "Icons/Search"
- **WHEN** exported with `--w3c-version v1`
- **THEN** the token SHALL include `"$type": "asset"` and `"$value"` with the URL (current behavior)

### Requirement: Dimension Tokens

Figma number variables scoped to spatial properties SHALL export as `$type: "dimension"` with an object `$value`
containing `value` (number) and `unit` (string: `"px"` or `"rem"`). The unit is part of the value per v2025.10 spec,
NOT in `$extensions`. Figma variables don't carry unit info, so `"px"` is the default.

Spatial scopes: `WIDTH_HEIGHT`, `GAP`, `CORNER_RADIUS`, `FONT_SIZE`, `LINE_HEIGHT`, `PARAGRAPH_SPACING`,
`PARAGRAPH_INDENT`.

#### Scenario: Spacing variable exported as dimension

- **GIVEN** a Figma number variable "Spacing/Medium" with value `16` and scope `["GAP"]`
- **WHEN** the variable is exported in W3C v2025 format
- **THEN** the token SHALL have `"$type": "dimension"` and:
  ```json
  "$value": { "value": 16, "unit": "px" }
  ```

#### Scenario: Corner radius variable exported as dimension

- **GIVEN** a Figma number variable "Radius/Large" with value `12` and scope `["CORNER_RADIUS"]`
- **WHEN** the variable is exported in W3C v2025 format
- **THEN** the token SHALL have `"$type": "dimension"` and:
  ```json
  "$value": { "value": 12, "unit": "px" }
  ```

### Requirement: Number Tokens

Figma number variables scoped to unitless properties SHALL export as `$type: "number"` with a plain numeric `$value`.
Variables with no scope or unknown scope SHALL default to `$type: "number"`.

Unitless scopes: `OPACITY`, `FONT_WEIGHT`.

#### Scenario: Opacity variable exported as number

- **GIVEN** a Figma number variable "Opacity/Disabled" with value `0.4` and scope `["OPACITY"]`
- **WHEN** the variable is exported in W3C v2025 format
- **THEN** the token SHALL have `"$type": "number"` and `"$value": 0.4`

#### Scenario: Variable with no scope defaults to number

- **GIVEN** a Figma number variable "ZIndex/Modal" with value `100` and no scopes
- **WHEN** the variable is exported in W3C v2025 format
- **THEN** the token SHALL have `"$type": "number"` and `"$value": 100`

### Requirement: Typography Decomposition

Typography tokens SHALL export individual sub-tokens (`fontFamily`, `fontWeight`, `fontSize`, `lineHeight`,
`letterSpacing`) alongside the composite `typography` token. Sub-tokens SHALL use their respective W3C `$type` values
and correct `$value` formats per v2025.10.

#### Scenario: Text style decomposed into sub-tokens

- **GIVEN** a text style "Heading/H1" with font "Inter", weight 700, size 32, line height 1.25
- **WHEN** the style is exported in W3C v2025 format
- **THEN** the output SHALL contain:
  - `"Heading/H1"` with `"$type": "typography"` and composite `$value`:
    ```json
    {
      "fontFamily": ["Inter"],
      "fontSize": { "value": 32, "unit": "px" },
      "fontWeight": 700,
      "lineHeight": 1.25
    }
    ```
  - `"Heading/H1/fontFamily"` with `"$type": "fontFamily"` and `"$value": ["Inter"]`
  - `"Heading/H1/fontWeight"` with `"$type": "fontWeight"` and `"$value": 700`
  - `"Heading/H1/fontSize"` with `"$type": "dimension"` and `"$value": {"value": 32, "unit": "px"}`
  - `"Heading/H1/lineHeight"` with `"$type": "number"` and `"$value": 1.25`

Note: `fontFamily` uses array format per v2025.10 (single string or array of strings). `fontSize` is a dimension
object. `lineHeight` is a plain number (ratio, not px). `fontWeight` is a number (1–1000) or string alias per spec.

#### Scenario: Text style without optional properties

- **GIVEN** a text style "Body/Regular" with font "Inter", weight 400, size 16, no letter spacing, no explicit line height
- **WHEN** the style is exported in W3C v2025 format
- **THEN** `"letterSpacing"` and `"lineHeight"` sub-tokens MUST NOT be emitted
- **AND** the composite `typography` token SHALL omit `letterSpacing` and `lineHeight` from its `$value`

#### Scenario: Typography export with v1 flag

- **GIVEN** a text style "Heading/H1"
- **WHEN** exported with `--w3c-version v1`
- **THEN** only the composite `typography` token SHALL be emitted (current behavior)
- **AND** no individual sub-tokens SHALL be present
