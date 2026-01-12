---
paths:
  - "Sources/ExFig/Input/FaultTolerance*.swift"
  - "Sources/FigmaAPI/Client/**"
---

# Fault Tolerance Patterns

This rule covers retry, rate limiting, and timeout configuration for API commands.

## CLI Flags

All commands support configurable retry, rate limiting, and timeout via CLI flags:

```bash
# Light commands (colors, typography, download subcommands)
exfig colors --max-retries 6 --rate-limit 15 --timeout 60

# Heavy commands (icons, images) also support fail-fast and concurrent downloads
exfig icons --max-retries 4 --rate-limit 15 --timeout 90 --fail-fast
exfig icons --concurrent-downloads 50  # Increase CDN parallelism (default: 20)

# Batch command with timeout (overrides all per-config timeouts)
exfig batch ./configs/ --timeout 60 --rate-limit 20

# fetch command has its own --timeout in DownloadOptions
exfig fetch -f FILE_ID -r "Frame" -o ./out --timeout 45 --fail-fast
```

**Timeout precedence:** CLI `--timeout` > YAML `figma.timeout` > FigmaClient default (30s)

## Implementing Fault Tolerance in New Commands

When implementing new commands that make API calls:

```swift
// 1. Add appropriate options group
@OptionGroup
var faultToleranceOptions: FaultToleranceOptions  // For light commands

@OptionGroup
var faultToleranceOptions: HeavyFaultToleranceOptions  // For heavy download commands

// 2. Get client using resolveClient() helper (supports batch mode injection)
// Note: CLI timeout in options takes precedence over config timeout
let client = resolveClient(
    accessToken: options.accessToken,
    timeout: options.params.figma.timeout,
    options: faultToleranceOptions,
    ui: ui
)

// 3. Use the client for all API calls
let data = try await client.request(endpoint)
```

## Key Files

- `Sources/ExFig/Input/FaultToleranceOptions.swift` - CLI options for retry/rate limit/timeout/concurrent downloads
- `Sources/ExFig/Output/FileDownloader.swift` - CDN download with configurable concurrency
- `Sources/FigmaAPI/Client/RateLimitedClient.swift` - Rate-limiting wrapper
- `Sources/FigmaAPI/Client/RetryPolicy.swift` - Retry with exponential backoff
- `Sources/ExFig/Cache/CheckpointTracker.swift` - Checkpoint management for resumable exports

## Defaults

| Setting           | Default | Description                           |
| ----------------- | ------- | ------------------------------------- |
| `maxRetries`      | 4       | Number of retry attempts              |
| `rateLimit`       | 10      | Requests per minute                   |
| `timeout`         | 30s     | Request timeout                       |
| `failFast`        | false   | Stop on first error                   |
| `resume`          | false   | Resume from checkpoint                |
| `checkpointExpiry`| 24h     | Checkpoint file expiration            |
| `concurrentDownloads` | 20  | Parallel CDN downloads                |

## Retry Behavior

- Exponential backoff: 2s -> 4s -> 8s -> 16s with jitter
- Respects `Retry-After` header from Figma API on 429 errors
- Checkpoint system saves progress for resumption on failure
