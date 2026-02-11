---
paths:
  - "Sources/ExFigCLI/Batch/**"
  - "Sources/ExFigCLI/Pipeline/**"
---

# Batch Processing Patterns

This rule covers batch pre-fetch optimization, pipelined downloads, and the BatchSharedState architecture.

## BatchSharedState Architecture

All batch mode state is consolidated into a single `BatchSharedState` actor with ONE `@TaskLocal`.
This avoids nested `TaskLocal.withValue()` calls which cause Swift runtime crashes on Linux.

**Key types:**

| Type | Purpose |
|------|---------|
| `BatchSharedState` | Actor holding all shared state, single `@TaskLocal` |
| `BatchContext` | Immutable pre-fetched data (versions, components, cache, nodes) |
| `ConfigExecutionContext` | Per-config data passed explicitly (configId, priority, assetType) |

**Key files:**

- `Sources/ExFigCLI/Batch/BatchContext.swift` - BatchSharedState actor, BatchContext, ConfigExecutionContext
- `Sources/ExFigCLI/Batch/BatchConfigRunner.swift` - Per-config processing with explicit context passing
- `Sources/ExFigCLI/Shared/ComponentPreFetcher.swift` - Updates actor state, no nested withValue

**Architecture (single nesting level):**

```swift
// Create consolidated state
let batchState = BatchSharedState(
    context: BatchContext(
        versions: preFetchedVersions,
        components: preFetchedComponents,
        granularCache: sharedGranularCache,
        nodes: preFetchedNodes
    ),
    progressView: progressView,
    themeCollector: themeAttributesCollector,
    downloadQueue: downloadQueue
)

// SINGLE withValue scope - no nesting!
let result = await BatchSharedState.$current.withValue(batchState) {
    await executor.execute(configs: configs) { configFile in
        // Per-config context passed explicitly
        let context = ConfigExecutionContext(
            configId: configFile.name,
            configPriority: priorityMap[configFile.name] ?? 0
        )
        // ... process with explicit context
    }
}

// Access anywhere via static property
if let state = BatchSharedState.current {
    let versions = state.versions      // nonisolated - immutable
    let queue = state.downloadQueue    // nonisolated - let property
    let comps = await state.getComponents()  // actor-isolated - mutable
}
```

**Why this matters (Linux crash fix):**

```swift
// OLD - 10+ nesting levels caused crash on Linux
$collector.withValue(c) {
    $progressView.withValue(p) {
        $context.withValue(ctx) {
            $queue.withValue(q) {
                ComponentPreFetcher:
                    $context.withValue(localCtx) { // CRASH!
                    }
            }
        }
    }
}

// NEW - single nesting level
BatchSharedState.$current.withValue(state) {
    // Everything accessible via state actor
}
```

## Batch Pre-fetch Optimization

When `--cache` is enabled, batch processing pre-fetches file metadata for all unique Figma file IDs
before parallel config processing. This avoids redundant API calls when multiple configs reference same files.

**Pre-fetch phases:**

1. **FileMetadata** - Fast, lightweight version check
2. **Components** - Only for files with changed versions
3. **Nodes** - Only when granular cache enabled, for files with components

**Key files:**

- `Sources/ExFigCLI/Batch/PreFetchedFileVersions.swift` - Storage struct for file metadata
- `Sources/ExFigCLI/Batch/PreFetchedComponents.swift` - Storage struct for components
- `Sources/ExFigCLI/Batch/PreFetchedNodes.swift` - Storage struct for nodes
- `Sources/ExFigCLI/Batch/FileVersionPreFetcher.swift` - Parallel pre-fetching with spinner
- `Sources/ExFigCLI/Cache/ImageTrackingManager.swift` - Checks BatchSharedState before API call

**Pattern:**

```swift
// ImageTrackingManager checks BatchSharedState first
if let state = BatchSharedState.current,
   let metadata = state.versions?.metadata(for: fileId) {
    return metadata  // Use pre-fetched
}
// ... fall back to API request
```

## Pipelined Downloads (Batch Mode)

In batch mode, downloads from all configs are coordinated through a shared queue to enable
cross-config pipelining. While one config is fetching from Figma API, another can be downloading
from CDN simultaneously.

**Key files:**

- `Sources/ExFigCLI/Pipeline/SharedDownloadQueue.swift` - Actor coordinating downloads across configs
- `Sources/ExFigCLI/Pipeline/PipelinedDownloader.swift` - Uses queue from BatchSharedState
- `Sources/ExFigCLI/Pipeline/DownloadJob.swift` - Represents a batch of files to download

**How it works:**

1. `Batch.swift` creates `SharedDownloadQueue` with `concurrentDownloads x parallel` capacity
2. Queue is stored in `BatchSharedState.downloadQueue`
3. `PipelinedDownloader.download()` receives `ConfigExecutionContext` with configId/priority
4. Downloads from all configs compete for slots (earlier configs get higher priority)
5. In standalone mode (no BatchSharedState), falls back to direct `FileDownloader`

**Pattern:**

```swift
// PipelinedDownloader receives context explicitly
static func download(
    files: [FileContents],
    fileDownloader: FileDownloader,
    context: ConfigExecutionContext? = nil,  // Explicit, not TaskLocal
    onProgress: DownloadProgressCallback? = nil
) async throws -> [FileContents] {
    // Check BatchSharedState for queue
    if let batchState = BatchSharedState.current,
       let queue = batchState.downloadQueue,
       let configId = context?.configId {
        return try await downloadWithQueue(
            files: files,
            configId: configId,
            priority: context?.configPriority ?? 0,
            queue: queue,
            onProgress: onProgress
        )
    } else {
        // Standalone mode - direct download
        return try await fileDownloader.fetch(files: files, onProgress: onProgress)
    }
}
```

**Expected performance:** ~45% improvement in batch mode with multiple configs.
