import Foundation

/// TaskLocal storage for injecting SharedDownloadQueue into export commands during batch processing.
/// Similar pattern to InjectedClientStorage and SharedGranularCacheStorage.
enum SharedDownloadQueueStorage {
    /// TaskLocal variable to inject shared download queue.
    @TaskLocal
    static var queue: SharedDownloadQueue?

    /// TaskLocal variable for current config identifier (for job tracking).
    @TaskLocal
    static var configId: String?

    /// TaskLocal variable for config priority (lower = higher priority, based on submission order).
    @TaskLocal
    static var configPriority: Int = 0

    /// Check if pipelined downloads are enabled (queue is injected).
    static var isEnabled: Bool {
        queue != nil
    }
}
