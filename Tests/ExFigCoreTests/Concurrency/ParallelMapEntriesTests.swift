import ExFigCore
import Foundation
import Testing

@Suite("ParallelMapEntries")
struct ParallelMapEntriesTests {
    @Test("Empty input returns empty array")
    func emptyInput() async throws {
        let results: [Int] = try await parallelMapEntries([Int]()) { $0 * 2 }
        #expect(results.isEmpty)
    }

    @Test("Single entry processes without task group")
    func singleEntry() async throws {
        let results = try await parallelMapEntries([42]) { $0 * 2 }
        #expect(results == [84])
    }

    @Test("Multiple entries produce correct results")
    func multipleEntries() async throws {
        let input = [1, 2, 3, 4, 5]
        let results = try await parallelMapEntries(input) { $0 * 10 }
        #expect(results == [10, 20, 30, 40, 50])
    }

    @Test("Results preserve input order")
    func preservesOrder() async throws {
        let input = Array(0 ..< 20)
        let results = try await parallelMapEntries(input, maxParallel: 3) { value in
            // Add small random delay to encourage out-of-order completion
            try await Task.sleep(for: .milliseconds(Int.random(in: 1 ... 10)))
            return value
        }
        #expect(results == input)
    }

    @Test("maxParallel=1 processes sequentially")
    func sequentialFallback() async throws {
        let input = [1, 2, 3, 4, 5]
        // With maxParallel=1, results should be in order and correct
        let results = try await parallelMapEntries(input, maxParallel: 1) { value in
            value * 2
        }

        #expect(results == [2, 4, 6, 8, 10])
    }

    @Test("Error propagation cancels remaining tasks")
    func errorPropagation() async throws {
        struct TestError: Error {}

        await #expect(throws: TestError.self) {
            try await parallelMapEntries([1, 2, 3, 4, 5], maxParallel: 2) { value in
                if value == 3 { throw TestError() }
                return value
            }
        }
    }

    @Test("Parallel verification — concurrent execution is faster than sequential")
    func parallelVerification() async throws {
        let entryCount = 5
        let delayMs = 50
        let input = Array(0 ..< entryCount)

        let start = ContinuousClock.now
        let results = try await parallelMapEntries(input, maxParallel: 5) { value in
            try await Task.sleep(for: .milliseconds(delayMs))
            return value
        }
        let elapsed = ContinuousClock.now - start

        #expect(results == input)
        // Sequential would take ~250ms (5 * 50ms); parallel should be ~50-100ms
        // Use generous 200ms threshold to avoid flaky tests
        #expect(elapsed < .milliseconds(200), "Expected parallel execution under 200ms, got \(elapsed)")
    }

    @Test("Aggregation pattern — sum of results")
    func aggregation() async throws {
        let input = [10, 20, 30]
        let counts = try await parallelMapEntries(input) { $0 }
        let total = counts.reduce(0, +)
        #expect(total == 60)
    }
}
