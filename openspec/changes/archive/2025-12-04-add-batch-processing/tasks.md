# Tasks: Add Batch Processing

## 1. Command Implementation

- [x] 1.1 Create `Sources/ExFig/Subcommands/Batch.swift`
- [x] 1.2 Add `--parallel` option (default: 3)
- [x] 1.3 Add `--fail-fast` flag (default: false, continue on error)
- [x] 1.4 Add `--report` option for JSON output
- [x] 1.5 Register batch command in `ExFigCommand.swift`
- [x] 1.6 Support both directory and file list inputs

## 2. Config Discovery

- [x] 2.1 Create `ConfigDiscovery` module
- [x] 2.2 Implement directory scanning for `*.yaml` files
- [x] 2.3 Filter for valid exfig/figma-export configs
- [x] 2.4 Validate configs before execution
- [x] 2.5 Detect and warn on output path conflicts

## 3. Batch Executor

- [x] 3.1 Create `BatchExecutor` actor
- [x] 3.2 Implement parallel execution with semaphore
- [x] 3.3 Integrate with shared rate limiter
- [x] 3.4 Collect per-config results
- [x] 3.5 Handle cancellation (Ctrl+C) gracefully

## 4. Shared Rate Limiting

- [x] 4.1 Create `SharedRateLimiter` actor in `Sources/FigmaAPI/`
- [x] 4.2 Implement token bucket algorithm (~0.167 req/s for Tier 1)
- [x] 4.3 Implement fair request queuing across configs
- [x] 4.4 Add per-config request tracking
- [x] 4.5 Handle 429 responses with `Retry-After` header
- [x] 4.6 Display aggregate rate limit status

## 5. Progress UI

- [x] 5.1 Create `BatchProgressView` in TerminalUI
- [x] 5.2 Implement multi-line progress display
- [x] 5.3 Show per-config status and progress
- [x] 5.4 Display shared rate limit status
- [x] 5.5 Handle terminal resize during batch

## 6. Result Reporting

- [x] 6.1 Create `BatchResult` model
- [x] 6.2 Create `ConfigResult` model with success/failure
- [x] 6.3 Implement summary display
- [x] 6.4 Implement JSON report generation
- [x] 6.5 Include timing and resource usage stats

## 7. Testing

- [x] 7.1 Unit tests for config discovery
- [x] 7.2 Unit tests for batch executor
- [x] 7.3 Integration tests with multiple configs
- [x] 7.4 Test rate limit distribution fairness
- [x] 7.5 Test error handling scenarios

## 8. Documentation

- [x] 8.1 Add batch command to CLI help
- [x] 8.2 Document batch processing in README
- [x] 8.3 Add examples for common batch scenarios
- [x] 8.4 Document report format
