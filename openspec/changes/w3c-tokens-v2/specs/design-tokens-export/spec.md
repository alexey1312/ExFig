# Design Tokens Export Capability

## ADDED Requirements

### Requirement: W3C DTCG v2025.10 Color Format

Each color token SHALL have a single `$value` string containing the hex color value. Multi-mode colors SHALL use
`$extensions.modes` object mapping mode names to hex values. The `$value` field SHALL contain the default mode value.

#### Scenario: Single-mode color token export

- **GIVEN** a color named "Background/Primary" with hex value `#ffffff` in light mode only
- **WHEN** the color is exported in W3C v2025 format
- **THEN** the output token SHALL have `"$type": "color"` and `"$value": "#ffffff"`
- **AND** no `$extensions.modes` key SHALL be present

#### Scenario: Multi-mode color token export

- **GIVEN** a color named "Background/Primary" with values `#ffffff` (Light) and `#1a1a1a` (Dark)
- **WHEN** the color is exported in W3C v2025 format
- **THEN** `"$value"` SHALL be `"#ffffff"` (default/first mode)
- **AND** `"$extensions"` SHALL contain `"modes": {"Light": "#ffffff", "Dark": "#1a1a1a"}`

#### Scenario: Color with alpha transparency

- **GIVEN** a color with RGBA values (0.2, 0.5, 0.8, 0.5)
- **WHEN** the color is exported in W3C v2025 format
- **THEN** `"$value"` SHALL be `"#338acc80"` (8-digit hex with alpha)

#### Scenario: Legacy v1 format preserved with flag

- **GIVEN** a multi-mode color "Background/Primary"
- **WHEN** exported with `--w3c-version v1`
- **THEN** `"$value"` SHALL be a dict mapping mode names to hex values (current behavior)
- **AND** no `$extensions` key SHALL be present

### Requirement: Token Extensions with Figma Metadata

Each token SHALL include `$extensions.exfig` with Figma metadata when the source is a Figma file. The metadata SHALL
include `variableId` for variable-sourced tokens and `nodeId` plus `fileId` for component-sourced tokens.

#### Scenario: Variable-sourced color token with extensions

- **GIVEN** a color variable with variableId "VariableID:123:456" from file "abc123"
- **WHEN** the color is exported in W3C v2025 format
- **THEN** `"$extensions"` SHALL contain:
  ```json
  { "exfig": { "variableId": "VariableID:123:456", "fileId": "abc123" } }
  ```

#### Scenario: Component-sourced asset token with extensions

- **GIVEN** an icon component with nodeId "1:23" and fileId "def456"
- **WHEN** the asset is exported in W3C v2025 format
- **THEN** `"$extensions"` SHALL contain:
  ```json
  { "exfig": { "nodeId": "1:23", "fileId": "def456" } }
  ```

#### Scenario: Extensions merge with mode data

- **GIVEN** a multi-mode color variable with variableId "VariableID:123:456"
- **WHEN** exported in W3C v2025 format
- **THEN** `"$extensions"` SHALL contain both `"modes"` and `"exfig"` keys

### Requirement: Token Descriptions

Tokens with Figma variable descriptions SHALL include a `$description` field. Empty or whitespace-only descriptions
MUST NOT produce a `$description` field.

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
- **THEN** the primitive token SHALL have `"$value": "#3b82f6"`
- **AND** the semantic token SHALL have `"$value": "{Primitives.Blue.500}"`

#### Scenario: Multi-mode semantic color with alias per mode

- **GIVEN** a semantic variable "Background/Surface" that aliases:
  - Light mode: "Primitives/Gray/50"
  - Dark mode: "Primitives/Gray/900"
- **WHEN** exported in W3C v2025 format
- **THEN** `"$value"` SHALL be `"{Primitives.Gray.50}"` (default mode alias)
- **AND** `"$extensions.modes"` SHALL contain:
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
SHALL use `$extensions.exfig.assetUrl` instead of `$type: "asset"`.

Valid `$type` values: `color`, `dimension`, `fontFamily`, `fontWeight`, `duration`, `cubicBezier`, `number`,
`strokeStyle`, `border`, `transition`, `shadow`, `gradient`, `typography`, `fontStyle`.

#### Scenario: Asset token exported without invented type

- **GIVEN** an icon component "Icons/Search" with export URL "https://figma.com/images/..."
- **WHEN** the asset is exported in W3C v2025 format
- **THEN** the token MUST NOT include `"$type": "asset"`
- **AND** `"$extensions.exfig.assetUrl"` SHALL contain the export URL

#### Scenario: Asset token with v1 flag preserves legacy type

- **GIVEN** an icon component "Icons/Search"
- **WHEN** exported with `--w3c-version v1`
- **THEN** the token SHALL include `"$type": "asset"` and `"$value"` with the URL (current behavior)

### Requirement: Dimension Tokens

Figma number variables scoped to spatial properties SHALL export as `$type: "dimension"` with a numeric `$value`.
The unit context SHALL be stored in `$extensions.exfig.unit` when determinable from Figma scope.

Spatial scopes: `WIDTH_HEIGHT`, `GAP`, `CORNER_RADIUS`, `FONT_SIZE`, `LINE_HEIGHT`, `PARAGRAPH_SPACING`,
`PARAGRAPH_INDENT`.

#### Scenario: Spacing variable exported as dimension

- **GIVEN** a Figma number variable "Spacing/Medium" with value `16` and scope `["GAP"]`
- **WHEN** the variable is exported in W3C v2025 format
- **THEN** the token SHALL have `"$type": "dimension"` and `"$value": 16`
- **AND** `"$extensions.exfig.unit"` SHALL be `"px"`

#### Scenario: Corner radius variable exported as dimension

- **GIVEN** a Figma number variable "Radius/Large" with value `12` and scope `["CORNER_RADIUS"]`
- **WHEN** the variable is exported in W3C v2025 format
- **THEN** the token SHALL have `"$type": "dimension"` and `"$value": 12`

### Requirement: Number Tokens

Figma number variables scoped to unitless properties SHALL export as `$type: "number"` with a numeric `$value`.
Variables with no scope or unknown scope SHALL default to `$type: "number"`.

Unitless scopes: `OPACITY`, `FONT_WEIGHT`, `LETTER_SPACING`.

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
`letterSpacing`) alongside the composite `typography` token. Sub-tokens SHALL use their respective W3C `$type` values.

#### Scenario: Text style decomposed into sub-tokens

- **GIVEN** a text style "Heading/H1" with font "Inter", weight 700, size 32, line height 40
- **WHEN** the style is exported in W3C v2025 format
- **THEN** the output SHALL contain:
  - `"Heading/H1"` with `"$type": "typography"` and composite `$value`
  - `"Heading/H1/fontFamily"` with `"$type": "fontFamily"` and `"$value": "Inter"`
  - `"Heading/H1/fontWeight"` with `"$type": "fontWeight"` and `"$value": 700`
  - `"Heading/H1/fontSize"` with `"$type": "dimension"` and `"$value": 32`
  - `"Heading/H1/lineHeight"` with `"$type": "dimension"` and `"$value": 40`

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
