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

The report SHALL contain: `command` (string), `config` (string path to PKL config), `startTime` (ISO8601 string), `endTime` (ISO8601 string), `duration` (number, seconds), `success` (boolean), `error` (string or null on success), `stats` (object), and `warnings` (string array).

#### Scenario: Successful export produces complete report

- **GIVEN** a valid PKL config with iOS colors entries
- **WHEN** running `exfig colors -i exfig.pkl --report results.json`
- **AND** the export completes successfully
- **THEN** the report JSON SHALL contain `"command": "colors"`
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

### Requirement: Stats object SHALL reuse ExportStats structure

The `stats` object in the report SHALL include `colors`, `icons`, `images`, and `typography` integer counts matching the existing `ExportStats` structure from `BatchResult.swift`.

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

All warnings emitted via TerminalUI during export SHALL be collected and included in the report `warnings` array as strings.

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

When manifest tracking is enabled, the report SHALL include a `manifest` object with a `files` array. Each file entry SHALL contain: `path` (string, relative to working directory), `action` (string enum), `checksum` (SHA256 hex string or null), and `assetType` (string).

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

### Requirement: SHA256 checksum SHALL be computed for manifest files

Each file in the manifest SHALL include a `checksum` field containing the SHA256 hex digest of the file content. This enables downstream tools to detect changes without reading file contents.

#### Scenario: Written file has SHA256 checksum

- **GIVEN** an export writes a file with known content
- **WHEN** the manifest entry is recorded
- **THEN** `checksum` SHALL be a 64-character lowercase hexadecimal string
- **AND** the value SHALL match the SHA256 hash of the written file content

#### Scenario: Deleted file has null checksum

- **GIVEN** a file marked with action `"deleted"`
- **WHEN** the manifest entry is recorded
- **THEN** `checksum` SHALL be `null`

#### Scenario: Unchanged file has checksum matching existing content

- **GIVEN** an export that detects a file is unchanged
- **WHEN** the manifest entry is recorded
- **THEN** `checksum` SHALL equal the SHA256 of the existing file content
