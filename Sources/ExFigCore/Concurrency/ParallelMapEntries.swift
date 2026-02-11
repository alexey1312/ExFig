/// Default maximum number of entries processed in parallel.
/// Limits concurrent export pipelines to avoid excessive memory and I/O pressure.
/// API rate limiting is handled separately by `RateLimitedClient`.
public let defaultMaxParallelEntries = 5

/// Process entries in parallel using a sliding window approach.
///
/// - Empty input: returns empty array immediately.
/// - Single entry: direct call, no task group overhead.
/// - Multiple entries: sliding window with configurable concurrency.
///
/// Results are returned in the same order as the input entries.
///
/// - Parameters:
///   - entries: Array of entries to process.
///   - maxParallel: Maximum number of concurrent tasks (default: 5).
///   - process: Async closure to process each entry.
/// - Returns: Array of results in the same order as input entries.
/// - Throws: Rethrows errors from `process`. Remaining in-flight tasks are cancelled on first failure.
public func parallelMapEntries<Entry: Sendable, Result: Sendable>(
    _ entries: [Entry],
    maxParallel: Int = defaultMaxParallelEntries,
    process: @escaping @Sendable (Entry) async throws -> Result
) async throws -> [Result] {
    switch entries.count {
    case 0:
        return []
    case 1:
        return try await [process(entries[0])]
    default:
        break
    }

    let effectiveMax = max(maxParallel, 1)

    return try await withThrowingTaskGroup(of: (Int, Result).self) { group in
        var results = [Result?](repeating: nil, count: entries.count)
        var nextIndex = 0

        // Seed initial batch
        for _ in 0 ..< min(effectiveMax, entries.count) {
            let index = nextIndex
            let entry = entries[index]
            group.addTask { [entry] in
                try await (index, process(entry))
            }
            nextIndex += 1
        }

        // Sliding window: as each task completes, start the next
        for try await (index, result) in group {
            results[index] = result

            if nextIndex < entries.count {
                let index = nextIndex
                let entry = entries[index]
                group.addTask { [entry] in
                    try await (index, process(entry))
                }
                nextIndex += 1
            }
        }

        // Safety: every index 0..<entries.count is assigned exactly once by the sliding window.
        // If any task throws, the function exits via `for try await` before reaching this line.
        return results.map { $0! } // swiftlint:disable:this force_unwrapping
    }
}
