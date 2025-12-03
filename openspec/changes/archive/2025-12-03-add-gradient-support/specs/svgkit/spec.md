## ADDED Requirements

### Requirement: SVG Gradient Types

The system SHALL provide data types for representing SVG gradients:

- `SVGGradientStop` with offset (0.0-1.0), color, and opacity
- `SVGLinearGradient` with id, x1, y1, x2, y2, stops, and spreadMethod
- `SVGRadialGradient` with id, cx, cy, r, fx, fy, stops, and spreadMethod
- `SVGFill` enum with cases: none, solid, linearGradient, radialGradient

All types SHALL conform to `Sendable` and `Equatable` protocols.

#### Scenario: Create linear gradient

- **WHEN** creating SVGLinearGradient with id="grad1", x1=0, y1=0, x2=24, y2=24, and two stops
- **THEN** gradient object is created with correct coordinates and stops

#### Scenario: Create gradient stop with opacity

- **WHEN** creating SVGGradientStop with offset=0.5, color=#FF0000, opacity=0.8
- **THEN** stop object stores opacity value correctly

### Requirement: SVG Gradient Parsing

The system SHALL parse SVG gradient definitions from `<defs>` element:

- Parse `<linearGradient>` elements with x1, y1, x2, y2 attributes
- Parse `<radialGradient>` elements with cx, cy, r, fx, fy attributes
- Parse `<stop>` child elements with offset, stop-color, stop-opacity
- Support percentage values (e.g., "50%") for coordinates and offsets
- Resolve `url(#gradientId)` references in fill/stroke attributes

#### Scenario: Parse linear gradient from SVG

- **WHEN** parsing SVG containing `<linearGradient id="grad1" x1="0" y1="0" x2="24" y2="24">`
- **THEN** ParsedSVG.linearGradients contains gradient with id "grad1"

#### Scenario: Parse gradient stops

- **WHEN** parsing gradient with stops at offset="0%" and offset="100%"
- **THEN** stops are parsed with offset values 0.0 and 1.0

#### Scenario: Resolve fill url reference

- **WHEN** parsing `<rect fill="url(#myGrad)">`
- **THEN** path.fill is .linearGradient with matching gradient data

#### Scenario: Handle missing gradient reference

- **WHEN** parsing `<rect fill="url(#nonexistent)">`
- **THEN** path.fill is .none

### Requirement: Vector Drawable Gradient Generation

The system SHALL generate Android Vector Drawable XML with gradient support:

- Add `xmlns:aapt` namespace when gradients are present
- Generate `<aapt:attr name="android:fillColor">` wrapper for gradient fills
- Generate `<gradient android:type="linear|radial">` with coordinates
- Generate `<item android:offset="..." android:color="..."/>` for stops
- Format colors as ARGB hex (#AARRGGBB) including opacity

#### Scenario: Generate linear gradient XML

- **WHEN** generating VD XML for path with linear gradient fill
- **THEN** output contains `<aapt:attr>` with `<gradient android:type="linear">`

#### Scenario: Generate gradient stop with opacity

- **WHEN** generating VD XML for gradient stop with opacity=0.5
- **THEN** output contains color with alpha channel (e.g., "#80FF0000")

#### Scenario: No aapt namespace without gradients

- **WHEN** generating VD XML for SVG with only solid colors
- **THEN** output does not contain `xmlns:aapt`

### Requirement: Compose ImageVector Gradient Generation

The system SHALL generate Jetpack Compose code with Brush gradients:

- Generate `Brush.linearGradient()` for linear gradient fills
- Generate `Brush.radialGradient()` for radial gradient fills
- Include colorStops array with offset and Color pairs
- Include start/end Offset for linear, center/radius for radial
- Add required imports: `androidx.compose.ui.graphics.Brush`, `androidx.compose.ui.geometry.Offset`

#### Scenario: Generate linear gradient brush

- **WHEN** generating Compose code for path with linear gradient
- **THEN** output contains `Brush.linearGradient(colorStops = arrayOf(...), start = Offset(...), end = Offset(...))`

#### Scenario: Generate radial gradient brush

- **WHEN** generating Compose code for path with radial gradient
- **THEN** output contains `Brush.radialGradient(colorStops = arrayOf(...), center = Offset(...), radius = ...)`

#### Scenario: Solid color backward compatibility

- **WHEN** generating Compose code for path with solid color fill
- **THEN** output contains `SolidColor(Color(...))` as before
