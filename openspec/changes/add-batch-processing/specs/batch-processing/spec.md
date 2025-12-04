# Batch Processing

Multi-config batch export capabilities.

## ADDED Requirements

### Requirement: Batch Command

The system SHALL provide a `batch` command to process multiple config files.

#### Scenario: Process directory of configs

- **WHEN** running `exfig batch ./configs/`
- **THEN** all `*.yaml` files in the directory are discovered
- **AND** each valid config is processed
- **AND** results are aggregated in a summary

#### Scenario: Process specific files

- **WHEN** running `exfig batch config1.yaml config2.yaml`
- **THEN** only the specified configs are processed

#### Scenario: Invalid config handling

- **WHEN** a config file is invalid
- **THEN** it is reported as failed
- **AND** processing continues with remaining configs

### Requirement: Parallel Execution

The system SHALL execute multiple configs in parallel with controlled concurrency.

#### Scenario: Default parallelism

- **WHEN** running batch without `--parallel` option
- **THEN** up to 3 configs are processed concurrently

#### Scenario: Custom parallelism

- **WHEN** running `exfig batch ./configs/ --parallel 5`
- **THEN** up to 5 configs are processed concurrently

#### Scenario: Sequential execution

- **WHEN** running `exfig batch ./configs/ --parallel 1`
- **THEN** configs are processed one at a time

### Requirement: Shared Rate Limiting

The system SHALL share rate limits across all parallel configs.

#### Scenario: Global rate limit

- **WHEN** multiple configs are processing in parallel
- **THEN** total API requests do not exceed the global rate limit
- **AND** requests are fairly distributed across configs

#### Scenario: Rate limit adaptation

- **WHEN** Figma API returns 429 for any config
- **THEN** all configs pause and respect the Retry-After period

### Requirement: Batch Progress Display

The system SHALL display progress for all configs during batch execution.

#### Scenario: Multi-config progress

- **WHEN** batch is running
- **THEN** progress is shown for each active config
- **AND** completed configs show final status
- **AND** pending configs show waiting status

#### Scenario: Rate limit visibility

- **WHEN** batch is running
- **THEN** current aggregate request rate is displayed
- **AND** rate limit headroom is visible

### Requirement: Batch Error Handling

The system SHALL handle errors gracefully during batch processing.

#### Scenario: Continue on error (default)

- **WHEN** one config fails during batch
- **THEN** remaining configs continue processing
- **AND** failed config is reported in summary

#### Scenario: Fail-fast mode

- **WHEN** running with `--fail-fast`
- **AND** any config fails
- **THEN** batch stops immediately
- **AND** reports partial results

#### Scenario: All configs fail

- **WHEN** all configs in batch fail
- **THEN** exit code is non-zero
- **AND** all errors are reported

### Requirement: Batch Reporting

The system SHALL provide detailed batch execution reports.

#### Scenario: Summary display

- **WHEN** batch completes
- **THEN** summary shows count of succeeded and failed configs
- **AND** per-config export counts are displayed

#### Scenario: JSON report

- **WHEN** running with `--report batch-report.json`
- **THEN** detailed results are saved to JSON file
- **AND** includes timing, counts, and error details

### Requirement: Output Conflict Detection

The system SHALL detect and warn about output path conflicts.

#### Scenario: Overlapping output paths

- **WHEN** two configs write to the same output path
- **THEN** warning is displayed before execution
- **AND** user can choose to continue or abort

#### Scenario: No conflicts

- **WHEN** all configs have unique output paths
- **THEN** batch proceeds without warnings
