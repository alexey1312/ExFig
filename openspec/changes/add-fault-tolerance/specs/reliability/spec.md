# Reliability

Fault tolerance and resilience requirements for ExFig operations.

## ADDED Requirements

### Requirement: Automatic Retry

The system SHALL automatically retry failed API requests with exponential backoff.

#### Scenario: Retry on server error

- **WHEN** Figma API returns HTTP 500, 502, 503, or 504
- **THEN** the system retries the request up to 4 times
- **AND** waits with exponential backoff (1s, 2s, 4s, 8s) between attempts
- **AND** adds random jitter to prevent thundering herd

#### Scenario: Retry on network timeout

- **WHEN** a request times out
- **THEN** the system retries with the same backoff policy

#### Scenario: No retry on client error

- **WHEN** Figma API returns HTTP 400, 401, 403, or 404
- **THEN** the system does not retry
- **AND** reports the error immediately

#### Scenario: Retry exhaustion

- **WHEN** all retry attempts are exhausted
- **THEN** the system reports the final error
- **AND** suggests checking network connectivity or Figma status

### Requirement: Rate Limit Handling

The system SHALL respect Figma API rate limits and adapt request frequency.

#### Scenario: Rate limit response

- **WHEN** Figma API returns HTTP 429
- **THEN** the system pauses requests for the duration specified in `Retry-After` header
- **AND** resumes automatically after the wait period

#### Scenario: Adaptive throttling

- **WHEN** multiple requests are queued
- **THEN** the system uses token bucket rate limiting
- **AND** prevents exceeding 10 requests per second by default

#### Scenario: Rate limit override

- **WHEN** `--rate-limit` option is specified
- **THEN** the system uses the specified requests-per-second limit

### Requirement: Atomic File Writes

The system SHALL perform atomic file writes to prevent corruption.

#### Scenario: Successful atomic write

- **WHEN** writing an export file
- **THEN** the system writes to a temporary file first
- **AND** atomically renames to the final destination

#### Scenario: Write failure recovery

- **WHEN** a write operation fails mid-file
- **THEN** no partial file exists at the destination
- **AND** the temporary file is cleaned up

#### Scenario: Orphaned temp file cleanup

- **WHEN** ExFig starts
- **THEN** orphaned `.exfig-*.tmp` files from previous runs are deleted

### Requirement: Export Checkpointing

The system SHALL support resuming interrupted exports.

#### Scenario: Checkpoint creation

- **WHEN** a batch of items is successfully exported
- **THEN** progress is saved to `.exfig-checkpoint.json`

#### Scenario: Resume from checkpoint

- **WHEN** running export with `--resume` flag
- **AND** a valid checkpoint exists
- **THEN** completed items are skipped
- **AND** export continues from pending items

#### Scenario: Checkpoint validation

- **WHEN** resuming with `--resume`
- **AND** the configuration has changed since checkpoint
- **THEN** the system warns about config mismatch
- **AND** asks for confirmation to continue or restart

#### Scenario: Checkpoint cleanup

- **WHEN** export completes successfully
- **THEN** the checkpoint file is deleted

#### Scenario: Checkpoint expiration

- **WHEN** a checkpoint is older than 24 hours
- **THEN** it is considered expired
- **AND** export starts fresh with warning

### Requirement: Graceful Degradation

The system SHALL continue operation when non-critical errors occur.

#### Scenario: Single item failure

- **WHEN** exporting multiple items
- **AND** one item fails after retries
- **THEN** the system logs the error
- **AND** continues with remaining items
- **AND** reports failed items in summary

#### Scenario: Fail-fast mode

- **WHEN** `--fail-fast` flag is specified
- **AND** any item fails
- **THEN** the export stops immediately
- **AND** reports the failure
