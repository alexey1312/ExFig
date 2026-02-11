/// Default maximum number of entries processed in parallel.
/// Balances throughput vs Figma API Tier 1 rate limits (10-20 req/min).
public let defaultMaxParallelEntries = 5

/// Process entries in parallel using a sliding window approach.
///
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

        return results.map { $0! } // swiftlint:disable:this force_unwrapping
    }
}
