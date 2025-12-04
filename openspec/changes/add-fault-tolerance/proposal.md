# Change: Add Fault Tolerance

## Why

ExFig interacts with external systems (Figma API, file system) that can fail unpredictably:

- **Figma API**: Rate limits (429), network timeouts, temporary outages
- **File system**: Disk full, permission errors, concurrent access

Currently, failures cause immediate termination with cryptic error messages like "HTTP 500". Users must restart from
scratch, potentially hitting rate limits again.

## Already Implemented

The following components are already in place and working:

| Component                 | File                            | Status  |
| ------------------------- | ------------------------------- | ------- |
| Token bucket rate limit   | `SharedRateLimiter.swift`       | ✅ Done |
| 429 handling + wait       | `RateLimitedClient.swift:32-44` | ✅ Done |
| Retry-After parsing       | `Client.swift:51-67`            | ✅ Done |
| HTTPError with retryAfter | `Client.swift:13-21`            | ✅ Done |
| Atomic file writes        | `FileWriter.swift` (`.atomic`)  | ✅ Done |
| Fair round-robin queue    | `SharedRateLimiter.swift`       | ✅ Done |

## What Changes

### Remaining work

- Add exponential backoff with jitter for retries (currently only one retry on 429)
- Extend retry to server errors (500, 502, 503, 504) and network timeouts
- **Improve error messages** — show user-friendly text with recovery suggestions
- Add retry attempt logging so users see progress
- Create checkpoint/resume capability for large exports
- Add `--resume` flag to continue interrupted exports
- Add `--fail-fast` flag to disable retries
- Clean up orphaned temp files on startup

### User-facing error improvements

Current behavior:

```
Error: HTTP 500
```

Target behavior:

```
⚠️ Figma API returned error 500 (Server Error)
   Retrying in 2s... (attempt 2/4)

❌ Export failed after 4 retries
   Suggestion: Check https://status.figma.com or try again later

   To resume this export, run:
   exfig colors --resume
```

## Impact

- Affected specs: `reliability` (new capability)
- Affected code:
  - `Sources/FigmaAPI/Client.swift` — Add RetryPolicy, improve HTTPError messages
  - `Sources/FigmaAPI/RateLimitedClient.swift` — Extend retry logic
  - `Sources/ExFig/Output/FileWriter.swift` — Temp file cleanup
  - `Sources/ExFig/Cache/` — Checkpoint management
  - `Sources/ExFig/Subcommands/*.swift` — Resume support, error display
