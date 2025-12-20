## ADDED Requirements

### Requirement: HEIC Output Format for Images

The system SHALL support HEIC as an output format for iOS image exports.

When `outputFormat: heic` is configured, the system SHALL:

- Convert source images (PNG or SVG) to HEIC format
- Use Apple ImageIO framework for encoding (macOS only)
- Apply configurable quality setting via `heicQuality` (0.0-1.0, default 0.9)
- Round odd image dimensions to even (HEIC encoder requirement)
- Force sRGB colorspace for consistent encoding

#### Scenario: HEIC export from SVG source

- **WHEN** iOS images configured with `sourceFormat: svg` and `outputFormat: heic`
- **THEN** SVG is rasterized via resvg at each scale
- **AND** RGBA output is encoded to HEIC via ImageIO
- **AND** output files have `.heic` extension in asset catalog

#### Scenario: HEIC export from PNG source

- **WHEN** iOS images configured with `sourceFormat: png` and `outputFormat: heic`
- **THEN** PNG is decoded to RGBA
- **AND** RGBA is encoded to HEIC via ImageIO
- **AND** output files have `.heic` extension in asset catalog

#### Scenario: Linux platform fallback

- **WHEN** HEIC output is configured on Linux
- **THEN** system logs warning about HEIC unavailability
- **AND** falls back to PNG output format
- **AND** export completes successfully with PNG files

#### Scenario: Contents.json for HEIC assets

- **WHEN** HEIC images are exported to asset catalog
- **THEN** Contents.json references files with `.heic` extension
- **AND** asset catalog is valid and loadable in Xcode

### Requirement: HEIC Quality Configuration

The system SHALL support configurable HEIC quality via `heicQuality` parameter.

#### Scenario: Default quality

- **WHEN** `heicQuality` is not specified
- **THEN** quality defaults to 0.9 (90%)

#### Scenario: Custom quality

- **WHEN** `heicQuality` is set to 0.7
- **THEN** HEIC encoder uses 70% quality
- **AND** output file size is smaller than 90% quality
