# Fault Tolerance

All commands support configurable retry, rate limiting, and timeout via CLI flags.

## CLI Flags

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

## Implementing in New Commands

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

| File                                                    | Purpose                                                  |
| ------------------------------------------------------- | -------------------------------------------------------- |
| `Sources/ExFig/Input/FaultToleranceOptions.swift`       | CLI options for retry/rate limit/timeout                 |
| `Sources/ExFig/Output/FileDownloader.swift`             | CDN download with configurable concurrency               |
| `Sources/FigmaAPI/Client/RateLimitedClient.swift`       | Rate-limiting wrapper                                    |
| `Sources/FigmaAPI/Client/RetryPolicy.swift`             | Retry with exponential backoff                           |
| `Sources/ExFig/Cache/CheckpointTracker.swift`           | Checkpoint management for resumable exports              |

---

## Batch Pre-fetch Optimization

When `--cache` is enabled, batch processing pre-fetches file metadata for all unique Figma file IDs before parallel config processing. This avoids redundant API calls when multiple configs reference the same files.

### Key Files

| File                                                    | Purpose                                      |
| ------------------------------------------------------- | -------------------------------------------- |
| `Sources/ExFig/Batch/PreFetchedFileVersions.swift`      | Storage struct with `@TaskLocal` injection   |
| `Sources/ExFig/Batch/FileIdExtractor.swift`             | Extracts unique fileIds from YAML configs    |
| `Sources/ExFig/Batch/FileVersionPreFetcher.swift`       | Parallel pre-fetching with spinner           |
| `Sources/ExFig/Cache/ImageTrackingManager.swift`        | Checks `PreFetchedVersionsStorage` before API call |

### Pattern

```swift
// Pre-fetched versions are injected via @TaskLocal (same pattern as InjectedClientStorage)
let result = await PreFetchedVersionsStorage.$versions.withValue(preFetchedVersions) {
    await executor.execute(configs: configs) { ... }
}

// ImageTrackingManager checks TaskLocal first, falls back to API
if let preFetched = PreFetchedVersionsStorage.versions,
   let metadata = preFetched.metadata(for: fileId) {
    return metadata  // Use pre-fetched
}
// ... fall back to API request
```

---

## Pipelined Downloads (Batch Mode)

In batch mode, downloads from all configs are coordinated through a shared queue to enable cross-config pipelining. While one config is fetching from Figma API, another can be downloading from CDN simultaneously.

### Key Files

| File                                                        | Purpose                                           |
| ----------------------------------------------------------- | ------------------------------------------------- |
| `Sources/ExFig/Pipeline/SharedDownloadQueue.swift`          | Actor coordinating downloads across configs       |
| `Sources/ExFig/Pipeline/SharedDownloadQueueStorage.swift`   | `@TaskLocal` injection for queue                  |
| `Sources/ExFig/Pipeline/PipelinedDownloader.swift`          | Helper that uses queue when available             |
| `Sources/ExFig/Pipeline/DownloadJob.swift`                  | Represents a batch of files to download           |

### How It Works

1. `Batch.swift` creates `SharedDownloadQueue` with `concurrentDownloads × parallel` capacity
2. Each config runner gets queue + priority injected via `SharedDownloadQueueStorage` TaskLocal
3. `ExportIcons`/`ExportImages` call `PipelinedDownloader.download()` which checks for injected queue
4. Downloads from all configs compete for slots in the shared queue (earlier configs get higher priority)
5. In standalone mode (no batch), falls back to direct `FileDownloader`

### Pattern

```swift
// Queue is injected via @TaskLocal (same pattern as InjectedClientStorage)
try await SharedDownloadQueueStorage.$queue.withValue(downloadQueue) {
    try await SharedDownloadQueueStorage.$configId.withValue(configFile.name) {
        try await export(...)  // PipelinedDownloader checks SharedDownloadQueueStorage
    }
}

// PipelinedDownloader uses queue when available, otherwise direct download
if let queue = SharedDownloadQueueStorage.queue,
   let configId = SharedDownloadQueueStorage.configId {
    return try await downloadWithQueue(...)  // Pipelined
} else {
    return try await fileDownloader.fetch(...)  // Direct
}
```

**Expected performance:** ~45% improvement in batch mode with multiple configs.
