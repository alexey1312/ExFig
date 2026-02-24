# Export Report Capability

Structured JSON reporting for single export commands with timing, stats, warnings, and asset manifest.

## ADDED Requirements

### Requirement: Export commands SHALL accept --report flag

ExportColors, ExportIcons, ExportImages, and ExportTypography SHALL accept a `--report <path>` option that writes a JSON report file after export completes.

#### Scenario: Write report after successful colors export

- **WHEN** running `exfig colors -i exfig.pkl --report results.json`
- **THEN** colors are exported normally
- **AND** a JSON report file is written to `results.json`

#### Scenario: Write report after successful icons export

- **WHEN** running `exfig icons -i exfig.pkl --report report.json`
- **THEN** icons are exported normally
- **AND** a JSON report file is written to `report.json`

#### Scenario: Write report after successful images export

- **WHEN** running `exfig images -i exfig.pkl --report report.json`
- **THEN** images are exported normally
- **AND** a JSON report file is written to `report.json`

#### Scenario: Write report after successful typography export

- **WHEN** running `exfig typography -i exfig.pkl --report report.json`
- **THEN** typography is exported normally
- **AND** a JSON report file is written to `report.json`

#### Scenario: No report written when flag is omitted

- **WHEN** running `exfig colors -i exfig.pkl` without `--report`
- **THEN** colors are exported normally
- **AND** no report file is written

---

### Requirement: ExportReport SHALL contain structured JSON with timing and metadata

The report SHALL contain: `version` (integer, starting at 1), `command` (string: `"colors"`, `"icons"`, `"images"`, or `"typography"`), `config` (string path to PKL config), `startTime` (ISO8601 string), `endTime` (ISO8601 string), `duration` (number, seconds), `success` (boolean), `error` (string or null on success), `stats` (object), and `warnings` (string array).

#### Scenario: Successful export produces complete report

- **GIVEN** a valid PKL config with iOS colors entries
- **WHEN** running `exfig colors -i exfig.pkl --report results.json`
- **AND** the export completes successfully
- **THEN** the report JSON SHALL contain `"version": 1`
- **AND** `"command"` SHALL be `"colors"`
- **AND** `"config"` SHALL be the path to the PKL config file
- **AND** `"startTime"` SHALL be an ISO8601 timestamp before `"endTime"`
- **AND** `"duration"` SHALL be a positive number in seconds
- **AND** `"success"` SHALL be `true`
- **AND** `"error"` SHALL be `null`

#### Scenario: Report includes ISO8601 timestamps

- **GIVEN** an export that starts at time T1 and ends at time T2
- **WHEN** the report is written
- **THEN** `"startTime"` SHALL be T1 formatted as ISO8601
- **AND** `"endTime"` SHALL be T2 formatted as ISO8601
- **AND** `"duration"` SHALL equal the difference between T2 and T1 in seconds

---

### Requirement: Stats object SHALL contain asset counts

The `stats` object in the report SHALL include `colors`, `icons`, `images`, and `typography` integer counts. This uses a new `ReportStats: Encodable` struct with count fields only (analogous to `BatchReport.Stats`), since `ExportStats` contains non-Codable batch-only fields.

#### Scenario: Colors export populates stats correctly

- **GIVEN** a colors export that processes 42 colors
- **WHEN** the report is written
- **THEN** `stats.colors` SHALL be `42`
- **AND** `stats.icons` SHALL be `0`
- **AND** `stats.images` SHALL be `0`
- **AND** `stats.typography` SHALL be `0`

#### Scenario: Icons export populates stats correctly

- **GIVEN** an icons export that processes 15 icons
- **WHEN** the report is written
- **THEN** `stats.icons` SHALL be `15`
- **AND** `stats.colors` SHALL be `0`

---

### Requirement: All warnings SHALL be collected in the report

When `--report` is specified, all warnings emitted via TerminalUI during export SHALL be collected by a `WarningCollector` and included in the report `warnings` array as strings. TerminalUI does not currently store warnings — a new collection mechanism is required.

#### Scenario: Export with warnings includes them in report

- **GIVEN** an export that emits 3 warnings during processing
- **WHEN** the report is written
- **THEN** `warnings` SHALL be an array containing exactly 3 string entries
- **AND** each warning message SHALL match the text displayed in the terminal

#### Scenario: Export with no warnings produces empty array

- **GIVEN** an export that completes without any warnings
- **WHEN** the report is written
- **THEN** `warnings` SHALL be an empty array `[]`

---

### Requirement: Report write failure MUST NOT cause export to fail

If the report file cannot be written (invalid path, permission denied, disk full), the system SHALL log a warning and continue. The export command SHALL exit with success status if the export itself succeeded.

#### Scenario: Report write fails due to invalid path

- **GIVEN** a successful colors export
- **WHEN** `--report /nonexistent/dir/report.json` is specified
- **AND** the directory does not exist
- **THEN** the export command SHALL exit with success status
- **AND** a warning SHALL be logged indicating the report could not be written

#### Scenario: Report write fails due to permissions

- **GIVEN** a successful icons export
- **WHEN** `--report /read-only/report.json` is specified
- **AND** the path is not writable
- **THEN** the export command SHALL exit with success status
- **AND** a warning SHALL be logged indicating the report could not be written

---

### Requirement: Report SHALL be written even when export fails

When the export itself fails with an error, the report SHALL still be written with `success: false` and `error` containing the error description.

#### Scenario: Failed export produces error report

- **GIVEN** an export that fails due to an invalid Figma token
- **WHEN** `--report results.json` is specified
- **THEN** a report file SHALL be written to `results.json`
- **AND** `"success"` SHALL be `false`
- **AND** `"error"` SHALL contain the error message string
- **AND** `"stats"` SHALL reflect any partial progress (or all zeros)

#### Scenario: Failed export with report write failure

- **GIVEN** an export that fails
- **WHEN** `--report` path is also unwritable
- **THEN** the export command SHALL exit with failure status (from the export error)
- **AND** a warning SHALL be logged about the report write failure

---

### Requirement: Asset manifest SHALL track generated files

When manifest tracking is enabled, the report SHALL include a `manifest` object with a `files` array. Each file entry SHALL contain: `path` (string, relative to working directory), `action` (string enum), `checksum` (FNV-1a 16-char hex string or null), and `assetType` (string).

#### Scenario: Manifest lists all generated color files

- **GIVEN** a colors export that generates 3 Swift files
- **WHEN** the report is written with manifest tracking
- **THEN** `manifest.files` SHALL contain 3 entries
- **AND** each entry SHALL have `assetType` equal to `"color"`
- **AND** each entry SHALL have a relative `path` string
- **AND** each entry SHALL have a non-null `checksum`

#### Scenario: Manifest lists all generated icon files

- **GIVEN** an icons export that generates 10 SVG assets and 1 Swift extension
- **WHEN** the report is written with manifest tracking
- **THEN** `manifest.files` SHALL contain 11 entries
- **AND** each entry SHALL have `assetType` equal to `"icon"`

#### Scenario: Manifest paths are relative to working directory

- **GIVEN** a working directory of `/project`
- **AND** an export that writes to `/project/Resources/Colors.swift`
- **WHEN** the manifest is generated
- **THEN** the file entry `path` SHALL be `"Resources/Colors.swift"`

---

### Requirement: File action detection SHALL classify write operations

The system SHALL detect and report the following file actions: `created` (file did not exist before write), `modified` (file existed but content changed), `unchanged` (file existed with identical content), and `deleted` (file existed in previous report but is no longer generated).

#### Scenario: New file is marked as created

- **GIVEN** an export writes a file to a path that does not exist
- **WHEN** the manifest entry is recorded
- **THEN** the `action` SHALL be `"created"`

#### Scenario: Changed file is marked as modified

- **GIVEN** an export writes a file to a path that already exists
- **AND** the new content differs from the existing file content
- **WHEN** the manifest entry is recorded
- **THEN** the `action` SHALL be `"modified"`

#### Scenario: Identical file is marked as unchanged

- **GIVEN** an export writes a file to a path that already exists
- **AND** the new content is identical to the existing file content
- **WHEN** the manifest entry is recorded
- **THEN** the `action` SHALL be `"unchanged"`

#### Scenario: Missing file is marked as deleted

- **GIVEN** a previous report at the same path lists a file entry
- **AND** the current export does not generate that file
- **WHEN** the manifest is finalized
- **THEN** a `"deleted"` entry SHALL be added for that file
- **AND** the `checksum` SHALL be `null`

---

### Requirement: Content checksum SHALL be computed for manifest files

Each file in the manifest SHALL include a `checksum` field containing an FNV-1a 64-bit hex digest of the file content (using `FNV1aHasher.hashToHex()` already in the codebase). This enables downstream tools to detect changes without reading file contents. FNV-1a is non-cryptographic but sufficient for change detection — same algorithm used by the granular cache system.

#### Scenario: Written file has FNV-1a checksum

- **GIVEN** an export writes a file with known content
- **WHEN** the manifest entry is recorded
- **THEN** `checksum` SHALL be a 16-character lowercase hexadecimal string
- **AND** the value SHALL match the FNV-1a hash of the written file content

#### Scenario: Deleted file has null checksum

- **GIVEN** a file marked with action `"deleted"`
- **WHEN** the manifest entry is recorded
- **THEN** `checksum` SHALL be `null`

#### Scenario: Unchanged file has checksum matching existing content

- **GIVEN** an export that detects a file is unchanged
- **WHEN** the manifest entry is recorded
- **THEN** `checksum` SHALL equal the FNV-1a hash of the existing file content

---

### Requirement: Report SHALL include version field for forward compatibility

The `version` field SHALL be an integer starting at `1`. It SHALL be incremented when breaking changes are made to the report schema structure.

#### Scenario: Initial report version

- **GIVEN** any export with `--report`
- **WHEN** the report is written
- **THEN** `"version"` SHALL be `1`

---

### Requirement: Manifest SHALL handle zero-file exports gracefully

When an export completes successfully but produces no output files, the manifest SHALL be present with an empty `files` array.

#### Scenario: Export produces no files

- **GIVEN** a valid config with no matching assets in Figma
- **WHEN** the export completes successfully with `--report`
- **THEN** `manifest.files` SHALL be an empty array `[]`
- **AND** `stats` SHALL reflect zero counts for the relevant asset type
