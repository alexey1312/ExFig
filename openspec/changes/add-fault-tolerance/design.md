# Design: Fault Tolerance

## Context

ExFig makes multiple HTTP requests to Figma API and writes many files to disk. Both operations can fail:

### Figma API Limitations

- **Rate limits**: 10-20 requests/minute depending on endpoint and plan
- **429 responses**: Include `Retry-After` header
- **Timeouts**: Large file exports can take 30+ seconds
- **Transient errors**: 500, 502, 503 responses

### File System Issues

- Disk space exhaustion mid-export
- Permission changes during write
- Network drives disconnecting
- Concurrent tool access

## Goals / Non-Goals

### Goals

- Automatically recover from transient API failures
- Respect Figma rate limits without manual intervention
- Ensure file writes are atomic (all-or-nothing)
- Enable resuming interrupted large exports
- Provide clear feedback on retry attempts

### Non-Goals

- Offline mode (caching all Figma data locally)
- Automatic conflict resolution for concurrent edits
- Figma webhook integration for change detection

## Decisions

### Decision 1: Retry Strategy

**Decision**: Exponential backoff with jitter.

```swift
struct RetryPolicy: Sendable {
    let maxRetries: Int = 4
    let baseDelay: TimeInterval = 1.0
    let maxDelay: TimeInterval = 30.0
    let jitterFactor: Double = 0.2

    func delay(for attempt: Int) -> TimeInterval {
        let exponential = baseDelay * pow(2.0, Double(attempt))
        let capped = min(exponential, maxDelay)
        let jitter = capped * jitterFactor * Double.random(in: -1...1)
        return capped + jitter
    }
}
```

**Retryable conditions**:

- HTTP 429 (Rate Limited) - use `Retry-After` header if present
- HTTP 500, 502, 503, 504 (Server errors)
- Network timeout
- Connection reset

**Non-retryable**:

- HTTP 400, 401, 403, 404 (Client errors)
- Invalid JSON response
- Authentication failures

### Decision 2: Rate Limit Handling

**Decision**: Adaptive throttling with token bucket.

```swift
actor RateLimiter {
    private var tokens: Double = 10.0
    private let maxTokens: Double = 10.0
    private let refillRate: Double = 0.5  // tokens per second
    private var lastRefill: Date = Date()

    func acquire() async {
        refillTokens()
        while tokens < 1.0 {
            try? await Task.sleep(for: .milliseconds(100))
            refillTokens()
        }
        tokens -= 1.0
    }

    func onRateLimited(retryAfter: TimeInterval) {
        tokens = 0
        // Pause all requests for retryAfter duration
    }
}
```

### Decision 3: Atomic File Writes

**Decision**: Write to temp file, then atomic rename.

```swift
func writeAtomically(content: Data, to destination: URL) throws {
    let tempURL = destination
        .deletingLastPathComponent()
        .appendingPathComponent(".exfig-\(UUID().uuidString).tmp")

    try content.write(to: tempURL)

    do {
        // Atomic rename
        _ = try FileManager.default.replaceItemAt(destination, withItemAt: tempURL)
    } catch {
        // Cleanup temp file on failure
        try? FileManager.default.removeItem(at: tempURL)
        throw error
    }
}
```

### Decision 4: Checkpoint System

**Decision**: Save progress to `.exfig-checkpoint.json` after each batch.

```json
{
  "exportId": "uuid",
  "startedAt": "2024-01-15T10:00:00Z",
  "configHash": "sha256-of-config",
  "completed": {
    "colors": true,
    "icons": ["icon1", "icon2"],
    "images": [],
    "typography": false
  },
  "pending": {
    "icons": ["icon3", "icon4"],
    "images": ["img1", "img2"]
  }
}
```

**Resume behavior**:

- `--resume` flag checks for checkpoint file
- Validates config hasn't changed (hash match)
- Skips completed items, continues with pending
- Checkpoint deleted on successful completion

## Risks / Trade-offs

| Risk                          | Impact | Mitigation                               |
| ----------------------------- | ------ | ---------------------------------------- |
| Retry storms                  | Medium | Jitter + global rate limiter             |
| Stale checkpoints             | Low    | Include timestamp, auto-expire after 24h |
| Temp file accumulation        | Low    | Cleanup on startup                       |
| Disk full during atomic write | Medium | Check space before write                 |

## Migration Plan

### Phase 1: API Resilience

1. Add RetryPolicy to FigmaAPI Client
2. Implement exponential backoff
3. Handle 429 with Retry-After

### Phase 2: Rate Limiting

1. Add RateLimiter actor
2. Integrate with all API calls
3. Add `--rate-limit` CLI option for override

### Phase 3: Atomic Writes

1. Modify FileWriter for atomic operations
2. Add temp file cleanup on startup
3. Handle cross-filesystem moves

### Phase 4: Checkpointing

1. Implement checkpoint save/load
2. Add `--resume` flag
3. Add checkpoint expiration

## Open Questions

1. Should checkpoints be stored in config directory or output directory?
2. Should we support `--dry-run` to preview what would be exported?
3. Should rate limit settings be configurable in exfig.yaml?
