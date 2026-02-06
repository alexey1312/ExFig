/// A simple box that makes a value accessible across concurrency boundaries.
///
/// Use when bridging sync-to-async code with `DispatchSemaphore` where
/// the semaphore already ensures sequential access to the value.
final class SendableBox<T>: @unchecked Sendable {
    var value: T
    init(_ value: T) {
        self.value = value
    }
}
