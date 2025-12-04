# Tasks: JSON Export with W3C Design Tokens

## 1. Command Implementation

- [x] 1.1 Create `Sources/ExFig/Subcommands/Download.swift` with main command
- [x] 1.2 Add `DownloadColors` subcommand
- [x] 1.3 Add `DownloadIcons` subcommand
- [x] 1.4 Add `DownloadImages` subcommand
- [x] 1.5 Add `DownloadTypography` subcommand
- [x] 1.6 Add `DownloadAll` subcommand
- [x] 1.7 Register download command in `ExFigCommand.swift`
- [x] 1.8 Add `--format w3c|raw` flag (default: w3c)
- [x] 1.9 Add `--compact` flag for minified output
- [x] 1.10 Add `--output` / `-o` option for output path
- [x] 1.11 Add `--asset-format svg|png|pdf|jpg` flag for icons/images (default: png)
- [x] 1.12 Add `--scale 1|2|3|4` flag for raster formats (default: 3)

## 2. W3C Design Tokens Exporter

- [x] 2.1 Create `Sources/ExFig/Output/W3CTokensExporter.swift`
- [x] 2.2 Implement `W3CToken` struct with `$type`, `$value`, `$description`
- [x] 2.3 Implement color token conversion (RGBA 0-1 → hex)
- [x] 2.4 Implement variable name → nested hierarchy transformation (slash → depth)
- [x] 2.5 Implement VARIABLE_ALIAS resolution to final values (in ColorsVariablesLoader)
- [x] 2.6 Implement mode variants in `$value` (Light, Dark, etc.)
- [x] 2.7 Implement typography token conversion
- [x] 2.8 Implement asset token conversion with Figma export URLs
- [x] 2.9 Implement Figma Image API integration for asset URLs
- [x] 2.10 Support format selection (svg, png, pdf, jpg) for assets
- [x] 2.11 Support scale option for raster formats

## 3. Raw Format Exporter

- [x] 3.1 Create `RawExportMetadata` struct for source wrapper
- [x] 3.2 Create `RawExportOutput` struct combining source and data
- [x] 3.3 Implement JSON serialization with pretty-print option

## 4. Loader Integration

- [x] 4.1 Raw export fetches API data directly (no loader modification needed)
- [x] 4.2 Raw data access via direct endpoint calls (RawDataCapture protocol not needed)
- [x] 4.3 Ensure Figma Variables are included in raw output

## 5. Testing

- [x] 5.1 Add unit tests for W3C token conversion
- [x] 5.2 Add unit tests for color hex conversion
- [x] 5.3 Add unit tests for variable alias resolution
- [x] 5.4 Add unit tests for download commands
- [x] 5.5 Add integration tests with mock Figma responses
- [x] 5.6 Test JSON output structure and formatting

## 6. Documentation

- [x] 6.1 Add `download` command to CLI help
- [x] 6.2 Document W3C Design Tokens format in CONFIG.md
- [x] 6.3 Document raw format structure in CONFIG.md
- [x] 6.4 Add examples to README.md
