## 1. ExportReport Struct & JSON Serialization

- [ ] 1.1 Create `ExportReport` struct in `Sources/ExFigCLI/Batch/ExportReport.swift` with fields: command, config, startTime, endTime, duration, success, error, stats (ExportStats), warnings
- [ ] 1.2 Add `Codable` conformance to `ExportReport` and serialization via `JSONCodec.encodePrettySorted()`
- [ ] 1.3 Add `Codable` conformance to `ExportStats` (subset: colors, icons, images, typography counts only — exclude batch-only fields)
- [ ] 1.4 Write unit tests for `ExportReport` JSON serialization (success case, failure case, empty warnings)

## 2. --report Flag on Export Commands

- [ ] 2.1 Add `@Option(name: .long) var report: String?` to `ExportColors.swift`
- [ ] 2.2 Add `@Option(name: .long) var report: String?` to `ExportIcons.swift`
- [ ] 2.3 Add `@Option(name: .long) var report: String?` to `ExportImages.swift`
- [ ] 2.4 Add `@Option(name: .long) var report: String?` to `ExportTypography.swift`
- [ ] 2.5 Extract shared `writeExportReport(report:path:)` helper (wraps write in do/catch with warning on failure)
- [ ] 2.6 Wire report generation into each export command's run() method: capture start time, build ExportReport after export, call writeExportReport

## 3. Warning Collection

- [ ] 3.1 Expose collected warnings from `TerminalUI` as `[String]` accessor
- [ ] 3.2 Integrate warning collection into `ExportReport` construction in each export command
- [ ] 3.3 Write tests for warning collection (with warnings, empty warnings)

## 4. Asset Manifest (Phase 2)

- [ ] 4.1 Create `AssetManifest` and `ManifestEntry` structs with fields: path, action, checksum, assetType
- [ ] 4.2 Create `FileAction` enum: created, modified, unchanged, deleted
- [ ] 4.3 Add optional file tracking to `FileWriter`: record path + content hash before write, detect action
- [ ] 4.4 Implement SHA256 checksum computation from in-memory data during file write
- [ ] 4.5 Add `manifest` field to `ExportReport` (optional, present when tracking enabled)
- [ ] 4.6 Write unit tests for FileWriter tracking (created, modified, unchanged detection)
- [ ] 4.7 Write unit tests for AssetManifest JSON serialization

## 5. Deleted File Detection

- [ ] 5.1 Implement `deleted` action detection by comparing current manifest against previous report file
- [ ] 5.2 Write tests for deleted file detection (file in previous report but not in current export)

## 6. Integration Testing

- [ ] 6.1 Write integration test: `exfig colors --report` produces valid JSON file
- [ ] 6.2 Write integration test: export failure still writes report with `success: false`
- [ ] 6.3 Write integration test: report write failure does not fail the export
