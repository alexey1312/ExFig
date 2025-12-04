# Design: Fault Tolerance

## Context

ExFig makes multiple HTTP requests to Figma API and writes many files to disk. Both operations can fail:

### Figma API Limitations

- **Rate limits**: 10-20 requests/minute depending on endpoint and plan
- **429 responses**: Include `Retry-After` header
- **Timeouts**: Large file exports can take 30+ seconds
- **Transient errors**: 500, 502, 503, 504 responses

### File System Issues

- Disk space exhaustion mid-export
- Permission changes during write
- Network drives disconnecting
- Concurrent tool access

## Existing Implementation

These components are already built and working:

### SharedRateLimiter (Sources/FigmaAPI/SharedRateLimiter.swift)

Token bucket rate limiter with fair round-robin scheduling:

```swift
public actor SharedRateLimiter {
    private var tokens: Double = 3.0      // Burst capacity
    private let maxTokens: Double = 3.0
    private let minInterval: TimeInterval  // 60/requestsPerMinute

    public func acquire(for configID: ConfigID) async { ... }
    public func reportRateLimit(retryAfter: TimeInterval?) { ... }
}
```

### RateLimitedClient (Sources/FigmaAPI/RateLimitedClient.swift)

Wraps Client with rate limiting and basic 429 retry:

```swift
public func request<T: Endpoint>(_ endpoint: T) async throws -> T.Content {
    await rateLimiter.acquire(for: configID)
    do {
        return try await client.request(endpoint)
    } catch let error as HTTPError where error.statusCode == 429 {
        await rateLimiter.reportRateLimit(retryAfter: error.retryAfter)
        let retryAfter = error.retryAfter ?? 60.0
        try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
        await rateLimiter.clearPause()
        await rateLimiter.acquire(for: configID)
        return try await client.request(endpoint)  // Single retry
    }
}
```

**Limitation**: Only retries once, only on 429, no backoff, silent to user.

### HTTPError (Sources/FigmaAPI/Client.swift)

```swift
public struct HTTPError: Error, Sendable {
    public let statusCode: Int
    public let retryAfter: TimeInterval?
    public let body: Data

    public var localizedDescription: String {
        "HTTP \(statusCode)"  // ⚠️ Not user-friendly
    }
}
```

### Atomic Writes (Sources/ExFig/Output/FileWriter.swift)

Already using `.atomic` option:

```swift
try data.write(to: fileURL, options: .atomic)
```

## Goals / Non-Goals

### Goals

- Automatically recover from transient API failures (500, 502, 503, 504)
- Respect Figma rate limits without manual intervention ✅ Done
- Ensure file writes are atomic (all-or-nothing) ✅ Done
- Enable resuming interrupted large exports
- **Provide clear, actionable feedback to users**

### Non-Goals

- Offline mode (caching all Figma data locally)
- Automatic conflict resolution for concurrent edits
- Figma webhook integration for change detection

## Decisions

### Decision 1: Enhanced Retry Strategy

**Decision**: Extend existing RateLimitedClient with exponential backoff and server error handling.

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

    func isRetryable(_ error: Error) -> Bool {
        guard let http = error as? HTTPError else {
            return error is URLError  // Network errors
        }
        return [429, 500, 502, 503, 504].contains(http.statusCode)
    }
}
```

### Decision 2: User-Friendly Error Messages

**Decision**: Replace cryptic errors with actionable messages.

```swift
public struct FigmaAPIError: LocalizedError, Sendable {
    public let statusCode: Int
    public let retryAfter: TimeInterval?
    public let attempt: Int?
    public let maxAttempts: Int?

    public var errorDescription: String? {
        switch statusCode {
        case 401:
            return "Authentication failed. Check FIGMA_PERSONAL_TOKEN environment variable."
        case 403:
            return "Access denied. Verify you have access to this Figma file."
        case 404:
            return "File not found. Check the file ID in your configuration."
        case 429:
            let wait = retryAfter.map { String(format: "%.0fs", $0) } ?? "60s"
            return "Rate limited by Figma API. Waiting \(wait)..."
        case 500...504:
            return "Figma server error (\(statusCode)). This is usually temporary."
        default:
            return "Figma API error: HTTP \(statusCode)"
        }
    }

    public var recoverySuggestion: String? {
        switch statusCode {
        case 401:
            return "Run: export FIGMA_PERSONAL_TOKEN=your_token"
        case 429:
            return "Try again later or reduce batch size with --rate-limit"
        case 500...504:
            return "Check https://status.figma.com or retry in a few minutes"
        default:
            return nil
        }
    }
}
```

### Decision 3: Retry Progress Logging

**Decision**: Show users what's happening during retries.

```
⏳ Fetching icons from Figma...
⚠️ Server error (502). Retrying in 2s... (attempt 2/4)
⚠️ Server error (502). Retrying in 4s... (attempt 3/4)
✓ Fetched 42 icons
```

### Decision 4: Checkpoint System (unchanged)

**Decision**: Save progress to `.exfig-checkpoint.json` after each batch.

```json
{
  "exportId": "uuid",
  "startedAt": "2024-01-15T10:00:00Z",
  "configHash": "sha256-of-config",
  "completed": {
    "colors": true,
    "icons": ["icon1", "icon2"]
  },
  "pending": {
    "icons": ["icon3", "icon4"],
    "images": ["img1", "img2"]
  }
}
```

## Risks / Trade-offs

| Risk                          | Impact | Mitigation                               |
| ----------------------------- | ------ | ---------------------------------------- |
| Retry storms                  | Medium | Jitter + global rate limiter (✅ exists) |
| Stale checkpoints             | Low    | Include timestamp, auto-expire after 24h |
| Verbose output annoys users   | Low    | Only show retry info, not every request  |
| Disk full during atomic write | Medium | Check space before write                 |

## Migration Plan

### Phase 1: Error Messages (Priority)

1. Create `FigmaAPIError` with user-friendly messages
2. Update RateLimitedClient to use new error type
3. Add retry progress logging to TerminalUI

### Phase 2: Extended Retry

1. Add RetryPolicy to FigmaAPI
2. Extend retry to 500/502/503/504 errors
3. Add exponential backoff with jitter

### Phase 3: CLI Options

1. Add `--rate-limit` CLI option
2. Add `--fail-fast` flag
3. Display rate limit status in verbose mode

### Phase 4: Checkpointing

1. Implement checkpoint save/load
2. Add `--resume` flag
3. Add checkpoint expiration

## Open Questions

1. Should checkpoints be stored in config directory or output directory?
2. Should we support `--dry-run` to preview what would be exported?
3. Should rate limit settings be configurable in exfig.yaml?
