# Tasks: Add Raw JSON Export

## 1. Command Implementation

- [ ] 1.1 Create `Sources/ExFig/Subcommands/Download.swift` with main command
- [ ] 1.2 Add `DownloadColors` subcommand
- [ ] 1.3 Add `DownloadIcons` subcommand
- [ ] 1.4 Add `DownloadImages` subcommand
- [ ] 1.5 Add `DownloadTypography` subcommand
- [ ] 1.6 Add `DownloadAll` subcommand
- [ ] 1.7 Register download command in `ExFigCommand.swift`

## 2. JSON Output

- [ ] 2.1 Create `RawExportMetadata` struct for wrapper
- [ ] 2.2 Create `RawExportOutput` struct combining metadata and data
- [ ] 2.3 Implement JSON serialization with pretty-print option
- [ ] 2.4 Add `--compact` flag for minified output
- [ ] 2.5 Add `--output` / `-o` option for output path

## 3. Loader Integration

- [ ] 3.1 Modify loaders to optionally return raw API responses
- [ ] 3.2 Add `RawDataCapture` protocol for consistent raw data access
- [ ] 3.3 Ensure Figma Variables are included in raw output

## 4. Testing

- [ ] 4.1 Add unit tests for download commands
- [ ] 4.2 Add integration tests with mock Figma responses
- [ ] 4.3 Test JSON output structure and formatting

## 5. Documentation

- [ ] 5.1 Add `download` command to CLI help
- [ ] 5.2 Document JSON output format in CONFIG.md
- [ ] 5.3 Add examples to README.md
