import Foundation

/// Thread-safe lock wrapper compatible with macOS 12.0+.
/// Uses NSLock internally but provides type-safe state management.
/// Marked @unchecked Sendable because NSLock is thread-safe.
final class Lock<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: T

    init(_ value: T) {
        self.value = value
    }

    /// Execute closure with exclusive access to the protected value.
    @discardableResult
    func withLock<U>(_ body: (inout T) throws -> U) rethrows -> U {
        lock.lock()
        defer { lock.unlock() }
        return try body(&value)
    }
}
