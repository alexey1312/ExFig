## 1. ExportReport Struct & JSON Serialization

- [ ] 1.1 Create `ExportReport` struct in `Sources/ExFigCLI/Report/ExportReport.swift` with fields: version (Int, default 1), command, config, startTime, endTime, duration, success, error, stats (ReportStats), warnings
- [ ] 1.2 Create `ReportStats: Encodable` struct with count fields only (colors, icons, images, typography) — analogous to `BatchReport.Stats` in `Batch.swift:901`. Do NOT add Codable to `ExportStats` (it has non-Codable batch-only fields: `computedNodeHashes`, `granularCacheStats`, `fileVersions`)
- [ ] 1.3 Add `Encodable` conformance to `ExportReport` and serialization via `JSONCodec.encodePrettySorted()`
- [ ] 1.4 Write unit tests for `ExportReport` JSON serialization (success case, failure case, empty warnings, version field)

## 2. --report Flag on Export Commands

- [ ] 2.1 Add `@Option(name: .long, help: "Path to write JSON report") var report: String?` to `ExportColors.swift`
- [ ] 2.2 Add `@Option(name: .long, help: "Path to write JSON report") var report: String?` to `ExportIcons.swift`
- [ ] 2.3 Add `@Option(name: .long, help: "Path to write JSON report") var report: String?` to `ExportImages.swift`
- [ ] 2.4 Add `@Option(name: .long, help: "Path to write JSON report") var report: String?` to `ExportTypography.swift`
- [ ] 2.5 Extract shared `writeExportReport(report:path:)` helper (wraps write in do/catch with warning on failure — same pattern as `Batch.swift:710-716`)
- [ ] 2.6 Modify each export command's `run()` to capture results: currently `_ = try await performExport(...)` discards the result. Change to capture count from `performExport()` (or use `performExportWithResult()`) and wrap in do/catch to capture errors. Record `startTime = Date()` before export, `endTime = Date()` after, build `ExportReport`, call `writeExportReport`

## 3. Warning Collection

- [ ] 3.1 Create `WarningCollector` actor in `Sources/ExFigCLI/Report/WarningCollector.swift` — follow `SharedThemeAttributesCollector` pattern (`Sources/ExFigCLI/Batch/SharedThemeAttributes.swift`). Store warnings as `[String]`. Note: TerminalUI does NOT currently store warnings — it only prints them
- [ ] 3.2 Extend `TerminalUI.warning()` methods to forward formatted message to `WarningCollector` when one is active (pass via `@TaskLocal` or inject into TerminalUI). Only active when `--report` is specified
- [ ] 3.3 Integrate warning collection into `ExportReport` construction in each export command
- [ ] 3.4 Write tests for `WarningCollector` (add warnings, retrieve, empty state)

## 4. Asset Manifest (Phase 2)

- [ ] 4.1 Create `AssetManifest` and `ManifestEntry` structs with fields: path, action, checksum, assetType
- [ ] 4.2 Create `FileAction` enum: created, modified, unchanged, deleted
- [ ] 4.3 Add optional file tracking to `FileWriter`: before writing, check if file exists and compute `FNV1aHasher.hashToHex()` of new content. Compare with existing file hash to determine action (created/modified/unchanged). Only active when `--report` is specified — zero overhead otherwise
- [ ] 4.4 Compute content checksum via `FNV1aHasher.hashToHex()` (already in `Sources/ExFigCLI/Cache/FNV1aHasher.swift`) — NOT SHA256 (no CryptoKit/swift-crypto dependency in project). Produces 16-char lowercase hex
- [ ] 4.5 Add `manifest` field to `ExportReport` (optional, present when tracking enabled)
- [ ] 4.6 Write unit tests for FileWriter tracking (created, modified, unchanged detection)
- [ ] 4.7 Write unit tests for AssetManifest JSON serialization

## 5. Deleted File Detection

- [ ] 5.1 Implement `deleted` action detection by comparing current manifest against previous report file at the same `--report` path
- [ ] 5.2 Write tests for deleted file detection (file in previous report but not in current export)

## 6. Integration Testing

- [ ] 6.1 Write integration test: `exfig colors --report` produces valid JSON with version, command, stats, timestamps
- [ ] 6.2 Write integration test: export failure still writes report with `success: false`
- [ ] 6.3 Write integration test: report write failure does not fail the export
- [ ] 6.4 Write integration test: zero-file export produces report with empty manifest
