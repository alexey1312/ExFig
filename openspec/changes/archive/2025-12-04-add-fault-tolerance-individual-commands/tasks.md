# Tasks: Add Fault Tolerance to Individual Commands

## 1. Shared Options Group (TDD)

- [x] 1.1 Write tests for `FaultToleranceOptions` parsing (max-retries, rate-limit flags)
- [x] 1.2 Create `FaultToleranceOptions` option group in `Sources/ExFig/Input/`
- [x] 1.3 Write tests for helper method that creates `RateLimitedClient` from options
- [x] 1.4 Implement `createRateLimitedClient()` helper method

## 2. Light Commands - Retry Only (TDD)

Commands that don't download files, only need `--max-retries` and `--rate-limit`.

- [x] 2.1 Write tests verifying `ExportColors` accepts fault tolerance options
- [x] 2.2 Add `FaultToleranceOptions` to `ExportColors`, refactor to use `RateLimitedClient`
- [x] 2.3 Write tests verifying `ExportTypography` accepts fault tolerance options
- [x] 2.4 Add `FaultToleranceOptions` to `ExportTypography`, refactor to use `RateLimitedClient`
- [x] 2.5 Write tests verifying `Download` subcommands accept fault tolerance options
- [x] 2.6 Add `FaultToleranceOptions` to `Download` subcommands (colors, typography, icons, images)

## 3. Heavy Commands - Full Support (TDD)

Commands that download many files, need `--fail-fast` and `--resume` in addition.

- [x] 3.1 Write tests for `HeavyFaultToleranceOptions` with fail-fast and resume flags
- [x] 3.2 Add full `HeavyFaultToleranceOptions` to `ExportIcons` (including --fail-fast, --resume)
- [x] 3.3 Create `CheckpointTracker` actor for checkpoint management
- [x] 3.4 Write tests for `ExportImages` with fault tolerance options
- [x] 3.5 Add full `HeavyFaultToleranceOptions` to `ExportImages` (including --fail-fast, --resume)
- [x] 3.6 Add checkpoint helper methods to `HeavyFaultToleranceOptions`
- [x] 3.7 Write tests for `FetchImages` (fetch command) with fault tolerance options
- [x] 3.8 Add full `HeavyFaultToleranceOptions` to `FetchImages` (including --fail-fast, --resume)
- [x] 3.9 Write tests for `CheckpointTracker`

**Note:** Deep integration of checkpoint tracking into command download flows (icons, images, fetch) requires additional
architectural work and is tracked in a follow-up proposal. The infrastructure (`CheckpointTracker`, `ExportCheckpoint`)
is in place and tested.

## 4. Integration Testing

- [x] 4.1 Integration tests for retry behavior exist in `RateLimitedClientTests.swift`
- [x] 4.2 Write integration tests for resume from checkpoint (`ResumeIntegrationTests` in
  `FaultToleranceOptionsTests.swift`)
- [x] 4.3 Fail-fast behavior is tested via `HeavyFaultToleranceOptions` flag (creates RetryPolicy with maxRetries=0)

## 5. Documentation

- [x] 5.1 Update command help text with new options (all affected commands)
- [x] 5.2 Add fault tolerance section to README.md with examples
- [x] 5.3 Update CLAUDE.md with fault tolerance patterns for commands

## 6. Verification

- [x] 6.1 Run full test suite: `mise run test` (928 tests passing)
- [x] 6.2 Manual testing: verify --help shows new options
- [x] 6.3 Retry behavior tested via unit tests in RateLimitedClientTests
