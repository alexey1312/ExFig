import ExFigCore
import Foundation

/// Helper for downloading files with optional pipelining support.
/// Uses SharedDownloadQueue when available in batch mode, falls back to direct FileDownloader otherwise.
enum PipelinedDownloader {
    /// Download files using pipelined queue if available, otherwise use direct downloader.
    ///
    /// - Parameters:
    ///   - files: Files to download (can contain both local and remote files)
    ///   - fileDownloader: Fallback downloader for standalone mode
    ///   - onProgress: Progress callback (current, total)
    /// - Returns: Downloaded files with local URLs
    ///
    /// In batch mode, configId and priority are read from TaskLocal storage.
    static func download(
        files: [FileContents],
        fileDownloader: FileDownloader,
        onProgress: DownloadProgressCallback? = nil
    ) async throws -> [FileContents] {
        // Check if pipelined downloads are enabled
        if let queue = SharedDownloadQueueStorage.queue,
           let configId = SharedDownloadQueueStorage.configId
        {
            try await downloadWithQueue(
                files: files,
                configId: configId,
                priority: SharedDownloadQueueStorage.configPriority,
                queue: queue,
                onProgress: onProgress
            )
        } else {
            // Standalone mode - use direct downloader
            try await fileDownloader.fetch(files: files, onProgress: onProgress)
        }
    }

    /// Download using shared queue for cross-config pipelining.
    private static func downloadWithQueue(
        files: [FileContents],
        configId: String,
        priority: Int,
        queue: SharedDownloadQueue,
        onProgress: DownloadProgressCallback?
    ) async throws -> [FileContents] {
        let remoteFiles = files.filter { $0.sourceURL != nil }
        let localFiles = files.filter { $0.sourceURL == nil }

        guard !remoteFiles.isEmpty else {
            return localFiles
        }

        // Create and submit download job
        let job = DownloadJob(
            files: remoteFiles,
            configId: configId,
            priority: priority
        )

        // Submit and start processing
        let jobId = await queue.submitAndProcess(job: job)

        // Report initial progress
        if let onProgress {
            await onProgress(0, remoteFiles.count)
        }

        // Wait for completion
        let result = try await queue.waitForCompletion(jobId: jobId)

        // Report final progress
        if let onProgress {
            await onProgress(result.downloadedFiles.count, remoteFiles.count)
        }

        return localFiles + result.downloadedFiles
    }
}
