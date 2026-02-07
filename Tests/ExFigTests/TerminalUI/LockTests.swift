@testable import ExFigCLI
import XCTest

final class LockTests: XCTestCase {
    // MARK: - Basic Read/Write

    func testInitialValue() {
        let lock = Lock(42)

        let value = lock.withLock { $0 }

        XCTAssertEqual(value, 42)
    }

    func testMutateValue() {
        let lock = Lock(10)

        lock.withLock { $0 += 5 }

        let value = lock.withLock { $0 }
        XCTAssertEqual(value, 15)
    }

    func testReturnValue() {
        let lock = Lock("hello")

        let length = lock.withLock { $0.count }

        XCTAssertEqual(length, 5)
    }

    // MARK: - Complex Types

    func testWithArray() {
        let lock = Lock([1, 2, 3])

        lock.withLock { $0.append(4) }

        let count = lock.withLock { $0.count }
        XCTAssertEqual(count, 4)
    }

    func testWithDictionary() {
        let lock = Lock(["key": "value"])

        lock.withLock { $0["newKey"] = "newValue" }

        let value = lock.withLock { $0["newKey"] }
        XCTAssertEqual(value, "newValue")
    }

    func testWithStruct() {
        struct Counter {
            var value: Int = 0
        }

        let lock = Lock(Counter())

        lock.withLock { $0.value += 1 }
        lock.withLock { $0.value += 1 }

        let final = lock.withLock { $0.value }
        XCTAssertEqual(final, 2)
    }

    // MARK: - Concurrent Access

    func testConcurrentReads() async {
        let lock = Lock(100)

        await withTaskGroup(of: Int.self) { group in
            for _ in 0 ..< 100 {
                group.addTask {
                    lock.withLock { $0 }
                }
            }

            for await value in group {
                XCTAssertEqual(value, 100)
            }
        }
    }

    func testConcurrentWrites() async {
        let lock = Lock(0)

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 1000 {
                group.addTask {
                    lock.withLock { $0 += 1 }
                }
            }
        }

        let final = lock.withLock { $0 }
        XCTAssertEqual(final, 1000)
    }

    func testConcurrentReadWrite() async {
        let lock = Lock(0)

        await withTaskGroup(of: Void.self) { group in
            // Writers
            for _ in 0 ..< 500 {
                group.addTask {
                    lock.withLock { $0 += 1 }
                }
            }

            // Readers
            for _ in 0 ..< 500 {
                group.addTask {
                    _ = lock.withLock { $0 }
                }
            }
        }

        let final = lock.withLock { $0 }
        XCTAssertEqual(final, 500)
    }

    // MARK: - Error Handling

    func testThrowingClosure() {
        enum TestError: Error {
            case testError
        }

        let lock = Lock(42)

        XCTAssertThrowsError(
            try lock.withLock { _ -> Int in
                throw TestError.testError
            }
        ) { error in
            XCTAssertTrue(error is TestError)
        }
    }

    func testThrowingDoesNotMutate() {
        enum TestError: Error {
            case testError
        }

        let lock = Lock(42)

        do {
            try lock.withLock { value in
                value = 100
                throw TestError.testError
            }
        } catch {
            // Expected
        }

        // Value should be 100 because mutation happened before throw
        // (defer only unlocks, doesn't rollback)
        let final = lock.withLock { $0 }
        XCTAssertEqual(final, 100)
    }

    // MARK: - Discardable Result

    func testDiscardableResult() {
        let lock = Lock(0)

        // Should compile without warning when result is not used
        lock.withLock { $0 += 1 }

        let value = lock.withLock { $0 }
        XCTAssertEqual(value, 1)
    }

    // MARK: - Optional Value

    func testOptionalValue() {
        let lock = Lock<Int?>(nil)

        XCTAssertNil(lock.withLock { $0 })

        lock.withLock { $0 = 42 }

        XCTAssertEqual(lock.withLock { $0 }, 42)
    }
}
