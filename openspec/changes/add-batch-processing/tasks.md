# Tasks: Add Batch Processing

## 1. Command Implementation

- [ ] 1.1 Create `Sources/ExFig/Subcommands/Batch.swift`
- [ ] 1.2 Add `--parallel` option (default: 3)
- [ ] 1.3 Add `--fail-fast` flag (default: false, continue on error)
- [ ] 1.4 Add `--report` option for JSON output
- [ ] 1.5 Register batch command in `ExFigCommand.swift`
- [ ] 1.6 Support both directory and file list inputs

## 2. Config Discovery

- [ ] 2.1 Create `ConfigDiscovery` module
- [ ] 2.2 Implement directory scanning for `*.yaml` files
- [ ] 2.3 Filter for valid exfig/figma-export configs
- [ ] 2.4 Validate configs before execution
- [ ] 2.5 Detect and warn on output path conflicts

## 3. Batch Executor

- [ ] 3.1 Create `BatchExecutor` actor
- [ ] 3.2 Implement parallel execution with semaphore
- [ ] 3.3 Integrate with shared rate limiter
- [ ] 3.4 Collect per-config results
- [ ] 3.5 Handle cancellation (Ctrl+C) gracefully

## 4. Shared Rate Limiting

- [ ] 4.1 Create `SharedRateLimiter` actor in `Sources/FigmaAPI/`
- [ ] 4.2 Implement token bucket algorithm (~0.167 req/s for Tier 1)
- [ ] 4.3 Implement fair request queuing across configs
- [ ] 4.4 Add per-config request tracking
- [ ] 4.5 Handle 429 responses with `Retry-After` header
- [ ] 4.6 Display aggregate rate limit status

## 5. Progress UI

- [ ] 5.1 Create `BatchProgressView` in TerminalUI
- [ ] 5.2 Implement multi-line progress display
- [ ] 5.3 Show per-config status and progress
- [ ] 5.4 Display shared rate limit status
- [ ] 5.5 Handle terminal resize during batch

## 6. Result Reporting

- [ ] 6.1 Create `BatchResult` model
- [ ] 6.2 Create `ConfigResult` model with success/failure
- [ ] 6.3 Implement summary display
- [ ] 6.4 Implement JSON report generation
- [ ] 6.5 Include timing and resource usage stats

## 7. Testing

- [ ] 7.1 Unit tests for config discovery
- [ ] 7.2 Unit tests for batch executor
- [ ] 7.3 Integration tests with multiple configs
- [ ] 7.4 Test rate limit distribution fairness
- [ ] 7.5 Test error handling scenarios

## 8. Documentation

- [ ] 8.1 Add batch command to CLI help
- [ ] 8.2 Document batch processing in README
- [ ] 8.3 Add examples for common batch scenarios
- [ ] 8.4 Document report format
