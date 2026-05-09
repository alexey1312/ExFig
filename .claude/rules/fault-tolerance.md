---
paths:
  - "Sources/ExFigCLI/Input/FaultTolerance*.swift"
  - "Sources/FigmaAPI/Client/**"
---

# Fault Tolerance Patterns

This rule covers retry, rate limiting, and timeout configuration for API commands.

## CLI Flags

All commands support configurable retry, rate limiting, and timeout via CLI flags:

```bash
# Light commands (colors, typography, download colors/typography/icons/images)
exfig colors --max-retries 6 --rate-limit 15 --timeout 60

# Heavy commands (icons, images, download all) also support fail-fast and
# concurrent downloads. `download all` shares one rate-limited client across
# its colors/typography/icons/images sub-flows.
exfig icons --max-retries 4 --rate-limit 15 --timeout 90 --fail-fast
exfig icons --concurrent-downloads 50  # Increase CDN parallelism (default: 20)
exfig download all --rate-limit 25 --concurrent-downloads 50

# Batch command — `--timeout` is the resolved batch-level timeout.
# In batch mode `figma.*` rate-limiting fields (incl. `timeout`) are read ONLY from
# the first config; per-target `figma.timeout` in subsequent configs is ignored
# (warned under -v). Precedence: CLI > first config's figma.timeout > built-in default.
exfig batch ./configs/ --timeout 60 --rate-limit 20

# fetch command has its own --timeout in DownloadOptions
exfig fetch -f FILE_ID -r "Frame" -o ./out --timeout 45 --fail-fast
```

**Precedence (per knob):** CLI flag > PKL `figma.*` > built-in default. Same rule applies to:
`--timeout` / `figma.timeout`, `--rate-limit` / `figma.rateLimit`, `--max-retries` / `figma.maxRetries`,
`--concurrent-downloads` / `figma.concurrentDownloads`. Boolean flags (`--fail-fast`, `--resume`) and
batch settings (`--parallel`, `batch.parallel`/`failFast`/`resume`) follow OR semantics for booleans
and standard precedence for `parallel`.

`fetch` is config-free — it does not read `figma.*` PKL fields; only CLI flags and built-in defaults apply.

`colors` and `typography` make no CDN downloads, so `figma.concurrentDownloads` is silently ignored
(under `-v` a debug log records the skip).

`exfig batch` reads `batch:` and `figma.*` rate-limiting fields ONLY from the FIRST config in argv —
per-target `batch:` blocks in subsequent configs are ignored (logged under `-v`). The shared rate
limiter and download queue mean per-config `figma.rateLimit/maxRetries/concurrentDownloads` are
intentionally unused inside the batch run.

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

- `Sources/ExFigCLI/Input/FaultToleranceOptions.swift` - CLI options for retry/rate limit/timeout/concurrent downloads
- `Sources/ExFigCLI/Output/FileDownloader.swift` - CDN download with configurable concurrency
- `Sources/FigmaAPI/Client/RateLimitedClient.swift` - Rate-limiting wrapper
- `Sources/FigmaAPI/Client/RetryPolicy.swift` - Retry with exponential backoff
- `Sources/ExFigCLI/Cache/CheckpointTracker.swift` - Checkpoint management for resumable exports

## Defaults

| Setting           | Default | PKL key                          | Description                           |
| ----------------- | ------- | -------------------------------- | ------------------------------------- |
| `maxRetries`      | 4       | `figma.maxRetries`               | Number of retry attempts              |
| `rateLimit`       | 10      | `figma.rateLimit`                | Requests per minute                   |
| `timeout`         | 30s     | `figma.timeout`                  | Request timeout                       |
| `failFast`        | false   | `batch.failFast` (batch only)    | Stop on first error                   |
| `resume`          | false   | `batch.resume` (batch only)      | Resume from checkpoint                |
| `checkpointExpiry`| 24h     | (not configurable)               | Checkpoint file expiration            |
| `concurrentDownloads` | 20  | `figma.concurrentDownloads`      | Parallel CDN downloads                |
| `parallel`        | 3       | `batch.parallel` (batch only)    | Concurrent batch configs              |

## PKL Config Alternative

Instead of repeating CLI flags across CI workflows, set the values in `exfig.pkl`:

```pkl
figma = new Figma.FigmaConfig {
  lightFileId = "..."
  rateLimit = 25            // was --rate-limit 25
  maxRetries = 6            // was --max-retries 6
  concurrentDownloads = 50  // was --concurrent-downloads 50
  timeout = 60              // was --timeout 60
}

batch = new Batch.BatchConfig {
  parallel = 8              // was exfig batch --parallel 8
  failFast = true           // was exfig batch --fail-fast
}
```

CLI flags still override these values per-run.

## Retry Behavior

- Exponential backoff: 2s -> 4s -> 8s -> 16s with jitter
- Respects `Retry-After` header from Figma API on 429 errors
- Checkpoint system saves progress for resumption on failure

## Batch Settings Architecture

`BatchSettingsResolver.resolve(...)` is the single point where CLI flags, the FIRST config's
`batch:`/`figma.*` blocks, and built-in defaults merge into `ResolvedBatchSettings`.
`BatchConfigRunner` consumes the resolved values and MUST NOT read per-config `figma.timeout`
(or any other rate-limiting field) again — doing so silently overrides the documented
"first-config-wins" rule and contradicts the `ignoredPerTargetFigmaRateLimiting` warning.

**Single source of truth pattern:**
- `FaultToleranceDefaults` — Swift defaults; parity with PKL schema asserted at runtime via
  `BatchSettingsResolverExtendedTests.testPKLDefaultsMatchSwiftDefaults`.
- `FaultToleranceValidator.sanitized*` — clamps PKL values to ranges, falls back to default
  with a `.invalidConfigValue` warning. Used both by the resolver and by per-command
  `effective*` accessors.
- `FaultToleranceValidator.warnOnce(key:value:fallback:ui:)` — process-level dedup so the
  same out-of-range PKL value doesn't produce duplicate warnings across many call-sites.
  Has a `resetWarnedKeys()` test hook called from XCTest `setUp()` (`Lock<T>` pattern,
  same shape as `WarningCollector` / `ManifestTracker`).

**PKL module reuse:**
- `PKLModuleCache` (actor) caches `ExFig.ModuleImpl` by URL across `BatchSettingsResolver`,
  `logIgnoredPerTargetSettings`, and `BatchConfigRunner` to avoid re-evaluating the same
  config 2-3 times in one batch run. URL keys go through `standardizedFileURL`.
- Consumers must call `try options.validateUsing(preloadedModule:)` (mirror of
  `validate()` — same env+path checks minus PKL eval) to keep validation surfaces in sync.

**Slot product cap:** `concurrentDownloads * parallel` is capped at
`FaultToleranceDefaults.maxDownloadSlots = 1000` in `Batch.swift` to prevent EMFILE / CDN
throttling at extreme combinations (e.g. 200 × 50 = 10000). Out-of-range emits
`.excessiveDownloadSlots` warning.

**Batch RetryPolicy:** when constructing `RetryPolicy` in batch mode, honor `failFast`:
`RetryPolicy(maxRetries: resolved.failFast ? 0 : resolved.maxRetries)` — matches
`HeavyFaultToleranceOptions.createRetryPolicy()` outside batch.
