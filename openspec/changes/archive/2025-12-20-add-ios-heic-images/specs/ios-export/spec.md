## ADDED Requirements

### Requirement: HEIC Output Format for Images

The system SHALL support HEIC as an output format for iOS image exports.

When `outputFormat: heic` is configured, the system SHALL:

- Convert source images (PNG or SVG) to HEIC format
- Use Apple ImageIO framework for encoding (macOS only)
- Support both lossy and lossless encoding modes via `heicOptions.encoding`
- Apply configurable quality setting via `heicOptions.quality` (0-100, default 90)
- Round odd image dimensions to even (HEIC encoder requirement)
- Force sRGB colorspace for consistent encoding

#### Scenario: HEIC export from SVG source (lossy)

- **WHEN** iOS images configured with `sourceFormat: svg` and `outputFormat: heic`
- **AND** `heicOptions.encoding` is `lossy` (or not specified)
- **THEN** SVG is rasterized via resvg at each scale
- **AND** RGBA output is encoded to lossy HEIC via ImageIO
- **AND** output files have `.heic` extension in asset catalog

#### Scenario: HEIC export from SVG source (lossless)

- **WHEN** iOS images configured with `sourceFormat: svg` and `outputFormat: heic`
- **AND** `heicOptions.encoding` is `lossless`
- **THEN** SVG is rasterized via resvg at each scale
- **AND** RGBA output is encoded to lossless HEIC via ImageIO
- **AND** quality parameter is ignored
- **AND** output files have `.heic` extension in asset catalog

#### Scenario: HEIC export from PNG source (lossy)

- **WHEN** iOS images configured with `sourceFormat: png` (or default) and `outputFormat: heic`
- **AND** `heicOptions.encoding` is `lossy` (or not specified)
- **THEN** PNGs are downloaded from Figma API at configured scales
- **AND** PNG is decoded to RGBA via PngDecoder
- **AND** RGBA is encoded to lossy HEIC via HeicConverter
- **AND** output files have `.heic` extension in asset catalog

#### Scenario: HEIC export from PNG source (lossless)

- **WHEN** iOS images configured with `sourceFormat: png` (or default) and `outputFormat: heic`
- **AND** `heicOptions.encoding` is `lossless`
- **THEN** PNGs are downloaded from Figma API at configured scales
- **AND** PNG is decoded to RGBA via PngDecoder
- **AND** RGBA is encoded to lossless HEIC via HeicConverter
- **AND** quality parameter is ignored
- **AND** output files have `.heic` extension in asset catalog

#### Scenario: Linux platform fallback

- **WHEN** HEIC output is configured on Linux
- **THEN** system logs warning `heicUnavailableFallingBackToPng`
- **AND** falls back to PNG output format
- **AND** export completes successfully with PNG files

#### Scenario: Contents.json for HEIC assets

- **WHEN** HEIC images are exported to asset catalog
- **THEN** Contents.json references files with `.heic` extension
- **AND** asset catalog is valid and loadable in Xcode

### Requirement: HEIC Options Configuration

The system SHALL support configurable HEIC encoding via `heicOptions` parameter.

#### Scenario: Default encoding and quality

- **WHEN** `heicOptions` is not specified
- **THEN** encoding defaults to `lossy`
- **AND** quality defaults to 90

#### Scenario: Custom lossy quality

- **WHEN** `heicOptions.quality` is set to 70
- **AND** `heicOptions.encoding` is `lossy` (or not specified)
- **THEN** HEIC encoder uses 70% quality
- **AND** output file size is smaller than 90% quality

#### Scenario: Lossless encoding

- **WHEN** `heicOptions.encoding` is set to `lossless`
- **THEN** HEIC encoder uses lossless mode
- **AND** `heicOptions.quality` is ignored
- **AND** output has no compression artifacts

## MODIFIED Requirements

### Requirement: WebP Default Quality (Breaking Change)

The system SHALL use 90 as the default WebP quality instead of 80.

#### Scenario: Default WebP quality

- **WHEN** WebP output is configured without explicit quality
- **THEN** quality defaults to 90 (was 80)

**Note:** This is a breaking change for consistency with HEIC defaults.
