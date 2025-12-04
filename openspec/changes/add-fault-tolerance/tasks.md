# Tasks: Add Fault Tolerance

## 1. Retry Logic

- [ ] 1.1 Create `RetryPolicy` struct in FigmaAPI
- [ ] 1.2 Implement exponential backoff with jitter
- [ ] 1.3 Add retry wrapper to `Client.swift` request method
- [ ] 1.4 Parse `Retry-After` header for 429 responses
- [ ] 1.5 Define retryable vs non-retryable error types
- [ ] 1.6 Add retry attempt logging

## 2. Rate Limiting

- [ ] 2.1 Create `RateLimiter` actor in FigmaAPI
- [ ] 2.2 Implement token bucket algorithm
- [ ] 2.3 Integrate rate limiter with FigmaClient
- [ ] 2.4 Add adaptive slowdown on 429 responses
- [ ] 2.5 Add `--rate-limit` CLI option to override default
- [ ] 2.6 Display rate limit status in verbose mode

## 3. Atomic File Operations

- [ ] 3.1 Create `AtomicFileWriter` in Output module
- [ ] 3.2 Implement write-to-temp-then-rename pattern
- [ ] 3.3 Add cross-platform temp file naming
- [ ] 3.4 Add cleanup of orphaned temp files on startup
- [ ] 3.5 Handle disk space checks before write
- [ ] 3.6 Migrate FileWriter to use AtomicFileWriter

## 4. Checkpoint System

- [ ] 4.1 Create `ExportCheckpoint` model
- [ ] 4.2 Implement checkpoint serialization/deserialization
- [ ] 4.3 Add checkpoint save after each batch completion
- [ ] 4.4 Add `--resume` flag to export commands
- [ ] 4.5 Implement checkpoint validation (config hash)
- [ ] 4.6 Add checkpoint expiration (24h default)
- [ ] 4.7 Delete checkpoint on successful completion

## 5. Error Handling

- [ ] 5.1 Create structured error types for recoverable vs fatal errors
- [ ] 5.2 Add user-friendly error messages with recovery suggestions
- [ ] 5.3 Log detailed error context for debugging
- [ ] 5.4 Add `--fail-fast` flag to disable retries

## 6. Testing

- [ ] 6.1 Unit tests for RetryPolicy timing calculations
- [ ] 6.2 Unit tests for RateLimiter token bucket
- [ ] 6.3 Integration tests with mock 429 responses
- [ ] 6.4 Tests for atomic file write failure scenarios
- [ ] 6.5 Tests for checkpoint save/resume flow

## 7. Documentation

- [ ] 7.1 Document retry behavior in README
- [ ] 7.2 Add troubleshooting section for rate limits
- [ ] 7.3 Document checkpoint file location and format
- [ ] 7.4 Add --resume usage examples
