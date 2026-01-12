---
paths:
  - "Sources/ExFig/Batch/**"
  - "Sources/ExFig/Pipeline/**"
---

# Batch Processing Patterns

This rule covers batch pre-fetch optimization and pipelined downloads.

## Batch Pre-fetch Optimization

When `--cache` is enabled, batch processing pre-fetches file metadata for all unique Figma file IDs before parallel
config processing. This avoids redundant API calls when multiple configs reference the same files.

**Key files:**

- `Sources/ExFig/Batch/PreFetchedFileVersions.swift` - Storage struct with `@TaskLocal` injection
- `Sources/ExFig/Batch/FileIdExtractor.swift` - Extracts unique fileIds from YAML configs
- `Sources/ExFig/Batch/FileVersionPreFetcher.swift` - Parallel pre-fetching with spinner
- `Sources/ExFig/Cache/ImageTrackingManager.swift` - Checks `PreFetchedVersionsStorage` before API call

**Pattern:**

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

## Pipelined Downloads (Batch Mode)

In batch mode, downloads from all configs are coordinated through a shared queue to enable cross-config pipelining.
While one config is fetching from Figma API, another can be downloading from CDN simultaneously.

**Key files:**

- `Sources/ExFig/Pipeline/SharedDownloadQueue.swift` - Actor coordinating downloads across configs
- `Sources/ExFig/Pipeline/SharedDownloadQueueStorage.swift` - `@TaskLocal` injection for queue
- `Sources/ExFig/Pipeline/PipelinedDownloader.swift` - Helper that uses queue when available
- `Sources/ExFig/Pipeline/DownloadJob.swift` - Represents a batch of files to download

**How it works:**

1. `Batch.swift` creates `SharedDownloadQueue` with `concurrentDownloads x parallel` capacity
2. Each config runner gets queue + priority injected via `SharedDownloadQueueStorage` TaskLocal
3. `ExportIcons`/`ExportImages` call `PipelinedDownloader.download()` which checks for injected queue
4. Downloads from all configs compete for slots in the shared queue (earlier configs get higher priority)
5. In standalone mode (no batch), falls back to direct `FileDownloader`

**Pattern:**

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
