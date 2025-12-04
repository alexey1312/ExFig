# Design: Batch Processing

## Context

Organizations often have multiple Figma files:

- Different products/apps
- Different platforms (iOS app, Android app, web)
- Different brands/themes
- Component libraries vs product files

Each requires a separate `exfig.yaml` config. Running exports sequentially is slow and doesn't optimize API usage.

### Constraints

- Figma API rate limits apply globally (per token), not per file
- Parallel exports can overwhelm rate limits if uncoordinated
- Different configs may have dependencies (shared component library)

## Goals / Non-Goals

### Goals

- Process multiple configs from a directory
- Parallel execution with shared rate limiting
- Clear progress visibility for all configs
- Aggregated success/failure reporting
- Respect global Figma API limits

### Non-Goals

- Dependency resolution between configs
- Distributed processing across machines
- Config generation or discovery

## Decisions

### Decision 1: Command Structure

**Options considered**:

| Option                              | Pros                  | Cons                      |
| ----------------------------------- | --------------------- | ------------------------- |
| `--config-dir` on existing commands | Minimal new API       | Complex flag combinations |
| Separate `batch` command            | Clear intent, focused | Another command           |
| Auto-detect directory               | Zero config           | Implicit behavior         |

**Decision**: Add **`exfig batch`** command.

```bash
# Process all configs in directory
exfig batch ./configs/

# Process specific configs
exfig batch config1.yaml config2.yaml config3.yaml

# With options
exfig batch ./configs/ --parallel 5
```

### Decision 2: Parallelism Model

**Decision**: Controlled parallelism with shared rate limiter.

```swift
actor BatchExecutor {
    let maxParallel: Int
    let rateLimiter: RateLimiter  // Shared across all configs

    func execute(configs: [ConfigFile]) async throws -> BatchResult {
        try await withThrowingTaskGroup(of: ConfigResult.self) { group in
            var running = 0
            var results: [ConfigResult] = []

            for config in configs {
                // Wait if at max parallelism
                while running >= maxParallel {
                    if let result = try await group.next() {
                        results.append(result)
                        running -= 1
                    }
                }

                group.addTask {
                    try await self.processConfig(config)
                }
                running += 1
            }

            // Collect remaining results
            for try await result in group {
                results.append(result)
            }

            return BatchResult(configs: results)
        }
    }
}
```

**Default parallelism**: 3 configs (configurable via `--parallel`)

### Decision 3: Rate Limit Distribution

**Decision**: Single shared rate limiter with fair queuing.

```swift
actor SharedRateLimiter {
    // Tier 1 limit: 10-20 req/min depending on plan
    // Use conservative 10 req/min = 0.167 req/s for safety
    // See: https://developers.figma.com/docs/rest-api/rate-limits/
    private let globalLimit: Double = 10.0 / 60.0  // ~0.167 requests/second
    private var queues: [ConfigID: RequestQueue] = [:]

    func acquire(for config: ConfigID) async {
        // Fair round-robin across configs
        await fairQueue.enqueue(config)
        await globalLimiter.acquire()
    }
}
```

This prevents one config from starving others during parallel execution.

### Decision 4: Progress Display

**Decision**: Multi-line progress with per-config status.

```
Batch Export (3/5 configs)
├─ [████████░░] ios-app.yaml      Colors: 45/50  Icons: 120/120 ✓
├─ [██████░░░░] android-app.yaml  Colors: 30/50  Icons: 80/120
├─ [░░░░░░░░░░] web-app.yaml      Waiting...
└─ Rate limit: 8.5 req/s (10 max)
```

### Decision 5: Error Handling

**Decision**: Continue by default, fail-fast optional.

```bash
# Default: continue on error, report at end
exfig batch ./configs/

# Fail on first error
exfig batch ./configs/ --fail-fast
```

Result summary:

```
Batch complete: 4 succeeded, 1 failed

✓ ios-app.yaml         45 colors, 120 icons, 30 images
✓ android-app.yaml     45 colors, 120 icons, 30 images
✓ flutter-app.yaml     45 colors, 120 icons, 30 images
✓ web-components.yaml  20 colors, 50 icons
✗ legacy-app.yaml      Error: Invalid Figma file key

See ./batch-report.json for details
```

## Risks / Trade-offs

| Risk                           | Impact | Mitigation                               |
| ------------------------------ | ------ | ---------------------------------------- |
| Rate limit exhaustion          | High   | Shared limiter, adaptive backoff         |
| Memory usage with many configs | Medium | Stream processing, limit parallelism     |
| Complex error states           | Medium | Clear per-config status, detailed report |
| Config conflicts               | Low    | Warn on overlapping output paths         |

## Resolved Questions

1. **Mixing export types** — No. Each config defines its own exports. v1 processes configs as-is.
2. **Glob patterns** — No. Shell expands globs automatically (`exfig batch ./configs/*.yaml` works).
3. **Default report file** — No. Use `--report` explicitly when needed. Keeps default output clean.
