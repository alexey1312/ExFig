import Foundation

/// Compatibility shim for SharedDownloadQueue access.
///
/// Reads download queue from `BatchSharedState.current`.
/// This avoids nested TaskLocal.withValue() calls which cause Swift runtime crashes on Linux.
/// See: https://github.com/swiftlang/swift/issues/75501
///
/// ## Usage
///
/// ```swift
/// // Read queue (shim to BatchSharedState)
/// if let queue = SharedDownloadQueueStorage.queue { ... }
///
/// // Direct access (preferred)
/// if let queue = BatchSharedState.current?.downloadQueue { ... }
/// ```
///
/// ## Note
///
/// `configId` and `configPriority` are now passed via `ConfigExecutionContext`
/// parameter to `PipelinedDownloader.download()`, not via TaskLocal.
enum SharedDownloadQueueStorage {
    /// Get shared download queue from BatchSharedState.
    static var queue: SharedDownloadQueue? {
        BatchSharedState.current?.downloadQueue
    }

    /// Check if pipelined downloads are enabled (queue is available).
    static var isEnabled: Bool {
        queue != nil
    }
}
