# Tasks: Add Fault Tolerance

## 1. Retry Logic ✅

- [x] 1.1 ~~Create `RetryPolicy` struct in FigmaAPI~~ (basic retry exists in RateLimitedClient)
- [x] 1.2 Implement exponential backoff with jitter (RetryPolicy.swift)
- [x] 1.3 Extend retry wrapper to handle 500/502/503/504 errors (RateLimitedClient.swift)
- [x] 1.4 ~~Parse `Retry-After` header for 429 responses~~ (done in Client.swift:51-67)
- [x] 1.5 Define retryable vs non-retryable error types (FigmaAPIError.swift, RetryPolicy.isRetryable)
- [x] 1.6 Add retry attempt logging with user-visible progress (RetryLogger.swift, BatchExecutor.onRetryEvent)

## 2. Rate Limiting ✅

- [x] 2.1 ~~Create `RateLimiter` actor in FigmaAPI~~ (SharedRateLimiter exists)
- [x] 2.2 ~~Implement token bucket algorithm~~ (done in SharedRateLimiter)
- [x] 2.3 ~~Integrate rate limiter with FigmaClient~~ (RateLimitedClient wraps Client)
- [x] 2.4 ~~Add adaptive slowdown on 429 responses~~ (done in RateLimitedClient:32-44)
- [x] 2.5 Add `--rate-limit` CLI option to override default (Batch.swift:30-31)
- [x] 2.6 Display rate limit status in verbose mode (Batch.swift:147-152, displayRateLimitStatus)

## 3. Atomic File Operations (core complete, temp cleanup deferred)

- [x] 3.1 ~~Create `AtomicFileWriter` wrapper~~ (current .atomic option is sufficient)
- [x] 3.2 ~~Implement write-to-temp-then-rename pattern~~ (using .atomic option)
- [ ] 3.3 Add cross-platform temp file naming (`.exfig-*.tmp`) (deferred - .atomic handles this)
- [ ] 3.4 Add cleanup of orphaned temp files on startup (deferred to future iteration)
- [ ] 3.5 Handle disk space checks before write (deferred to future iteration)
- [x] 3.6 ~~Migrate FileWriter to use AtomicFileWriter~~ (already uses .atomic)

## 4. Checkpoint System ✅

- [x] 4.1 Create `ExportCheckpoint` model (ExportCheckpoint.swift - for item-level checkpointing)
- [x] 4.2 Implement checkpoint serialization/deserialization (ExportCheckpoint.save/load)
- [x] 4.3 Add checkpoint save after each batch completion (BatchCheckpoint.swift, CheckpointManager actor)
- [x] 4.4 Add `--resume` flag to batch command (Batch.swift:36-37)
- [x] 4.5 Implement checkpoint validation (config hash in ExportCheckpoint, path matching in BatchCheckpoint)
- [x] 4.6 Add checkpoint expiration (24h default - isExpired method)
- [x] 4.7 Delete checkpoint on successful completion (Batch.swift:159-165)

## 5. User-Friendly Error Handling ✅

- [x] 5.1 Create structured error types with user messages (FigmaAPIError.swift)
- [x] 5.2 Add descriptive messages for common errors:
  - HTTP 429: "Rate limited. Waiting {N}s before retry..."
  - HTTP 500-504: "Figma server error. Retrying..."
  - Timeout: "Request timed out. Retrying..."
  - Auth: "Invalid token. Check FIGMA_PERSONAL_TOKEN"
- [x] 5.3 Show retry progress: "Retrying in 2s... (attempt 2/4)" (RetryLogger.formatRetryMessage)
- [x] 5.4 Add recovery suggestions on final failure (FigmaAPIError.recoverySuggestion)
- [x] 5.5 Add `--fail-fast` flag to disable retries (Batch.swift:27-28)

## 6. Testing ✅

- [x] 6.1 Unit tests for RetryPolicy timing calculations (RetryPolicyTests.swift - 25 tests)
- [x] 6.2 ~~Unit tests for RateLimiter token bucket~~ (SharedRateLimiterTests.swift)
- [x] 6.3 Integration tests with mock 429/500 responses (RateLimitedClientRetryTests - 11 tests)
- [x] 6.4 FigmaAPIError tests (FigmaAPIErrorTests.swift - 22 tests)
- [x] 6.5 Tests for checkpoint save/resume flow (ExportCheckpointTests.swift - 21 tests, BatchCheckpointTests.swift - 15
  tests)

## 7. Documentation ✅

- [x] 7.1 Document retry behavior in README (Fault Tolerance section)
- [x] 7.2 Add troubleshooting section for rate limits (Troubleshooting section)
- [x] 7.3 Document checkpoint file location and format (.exfig-batch-checkpoint.json)
- [x] 7.4 Add --resume usage examples (Checkpoint System section)
