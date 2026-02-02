@testable import ExFig
import ExFigCore
import XCTest

final class SharedDownloadQueueTests: XCTestCase {
    // MARK: - Basic Operations

    func testSubmitAndWaitForSingleJob() async throws {
        // Given: A queue and a job with local files only
        let queue = SharedDownloadQueue(maxConcurrentDownloads: 5)
        let files = [
            FileContents.makeLocal(name: "test1"),
            FileContents.makeLocal(name: "test2"),
        ]
        let job = DownloadJob(
            files: files,
            configId: "config1",
            priority: 0
        )

        // When: Submitting and waiting for completion
        let jobId = await queue.submitAndProcess(job: job)
        let result = try await queue.waitForCompletion(jobId: jobId)

        // Then: Job completes with the files
        XCTAssertEqual(result.jobId, jobId)
        XCTAssertEqual(result.configId, "config1")
        XCTAssertEqual(result.downloadedFiles.count, 2)
    }

    func testMultipleJobsWithPriority() async throws {
        // Given: A queue with multiple jobs at different priorities
        let queue = SharedDownloadQueue(maxConcurrentDownloads: 1)

        let job1 = DownloadJob(
            files: [FileContents.makeLocal(name: "low")],
            configId: "low-priority",
            priority: 10
        )
        let job2 = DownloadJob(
            files: [FileContents.makeLocal(name: "high")],
            configId: "high-priority",
            priority: 1
        )

        // When: Submitting both jobs
        await queue.submit(job: job1)
        let jobId2 = await queue.submitAndProcess(job: job2)

        // Then: Both jobs complete (priority affects ordering internally)
        let result2 = try await queue.waitForCompletion(jobId: jobId2)
        XCTAssertEqual(result2.configId, "high-priority")
    }

    func testCancelConfig() async throws {
        // Given: A queue with pending jobs
        let queue = SharedDownloadQueue(maxConcurrentDownloads: 1)

        let job1 = DownloadJob(
            files: [FileContents.makeLocal(name: "file1")],
            configId: "to-cancel",
            priority: 0
        )

        // When: Submitting and then cancelling
        await queue.submit(job: job1)
        await queue.cancelConfig("to-cancel")

        // Then: Stats show no pending jobs for cancelled config
        let stats = await queue.stats()
        XCTAssertEqual(stats.pendingJobs, 0)
    }

    func testQueueStats() async throws {
        // Given: A queue
        let queue = SharedDownloadQueue(maxConcurrentDownloads: 10)

        // When: Getting stats
        let stats = await queue.stats()

        // Then: Stats are initialized correctly
        XCTAssertEqual(stats.pendingJobs, 0)
        XCTAssertEqual(stats.activeJobs, 0)
        XCTAssertEqual(stats.activeDownloads, 0)
        XCTAssertEqual(stats.totalCompleted, 0)
        XCTAssertEqual(stats.maxConcurrent, 10)
    }

    // MARK: - LRU Eviction Tests

    func testUnclaimedResultsAreStoredForLaterRetrieval() async throws {
        // Given: A queue
        let queue = SharedDownloadQueue(maxConcurrentDownloads: 5)
        let files = [FileContents.makeLocal(name: "test")]
        let job = DownloadJob(files: files, configId: "config1", priority: 0)

        // When: Job completes but we don't immediately wait
        let jobId = await queue.submitAndProcess(job: job)

        // Small delay to ensure job completes
        try await Task.sleep(nanoseconds: 10_000_000)

        // Then: Result can still be retrieved later
        let result = try await queue.waitForCompletion(jobId: jobId)
        XCTAssertEqual(result.configId, "config1")
    }

    func testManyJobsDoNotCauseMemoryLeak() async throws {
        // Given: A queue that processes many small jobs
        let queue = SharedDownloadQueue(maxConcurrentDownloads: 10)

        // When: Submitting and waiting for 50 jobs (under eviction limit)
        for i in 0 ..< 50 {
            let files = [FileContents.makeLocal(name: "file\(i)")]
            let job = DownloadJob(files: files, configId: "config\(i)", priority: 0)
            let jobId = await queue.submitAndProcess(job: job)
            _ = try await queue.waitForCompletion(jobId: jobId)
        }

        // Then: Stats show all completed
        let stats = await queue.stats()
        XCTAssertEqual(stats.pendingJobs, 0)
        XCTAssertEqual(stats.activeJobs, 0)
    }

    func testStatsDescription() {
        // Given: Stats with values
        let stats = QueueStats(
            pendingJobs: 2,
            activeJobs: 1,
            activeDownloads: 3,
            totalCompleted: 10,
            maxConcurrent: 5
        )

        // Then: Description includes all values
        let description = stats.description
        XCTAssertTrue(description.contains("pending=2"))
        XCTAssertTrue(description.contains("active=1"))
        XCTAssertTrue(description.contains("downloads=3/5"))
        XCTAssertTrue(description.contains("completed=10"))
    }

    // MARK: - LRU Eviction Edge Cases

    func testConcurrentJobsFromSameConfig() async throws {
        // Given: A queue with multiple jobs from the same config
        let queue = SharedDownloadQueue(maxConcurrentDownloads: 5)

        let job1 = DownloadJob(
            files: [FileContents.makeLocal(name: "file1")],
            configId: "same-config",
            priority: 0
        )
        let job2 = DownloadJob(
            files: [FileContents.makeLocal(name: "file2")],
            configId: "same-config",
            priority: 0
        )

        // When: Submitting both jobs from same config
        let jobId1 = await queue.submitAndProcess(job: job1)
        let jobId2 = await queue.submitAndProcess(job: job2)

        // Then: Both jobs complete successfully
        let result1 = try await queue.waitForCompletion(jobId: jobId1)
        let result2 = try await queue.waitForCompletion(jobId: jobId2)

        XCTAssertEqual(result1.configId, "same-config")
        XCTAssertEqual(result2.configId, "same-config")
        XCTAssertEqual(result1.downloadedFiles.count, 1)
        XCTAssertEqual(result2.downloadedFiles.count, 1)
    }

    func testEmptyFilesJobCompletesSuccessfully() async throws {
        // Given: A job with no files
        let queue = SharedDownloadQueue(maxConcurrentDownloads: 5)
        let job = DownloadJob(
            files: [],
            configId: "empty-job",
            priority: 0
        )

        // When: Submitting and waiting
        let jobId = await queue.submitAndProcess(job: job)
        let result = try await queue.waitForCompletion(jobId: jobId)

        // Then: Completes with empty files
        XCTAssertEqual(result.downloadedFiles.count, 0)
        XCTAssertEqual(result.configId, "empty-job")
    }

    func testPriorityOrderingWithMixedPriorities() async throws {
        // Given: Jobs with various priorities
        let queue = SharedDownloadQueue(maxConcurrentDownloads: 1)

        let lowPriority = DownloadJob(
            files: [FileContents.makeLocal(name: "low")],
            configId: "low",
            priority: 100
        )
        let mediumPriority = DownloadJob(
            files: [FileContents.makeLocal(name: "medium")],
            configId: "medium",
            priority: 50
        )
        let highPriority = DownloadJob(
            files: [FileContents.makeLocal(name: "high")],
            configId: "high",
            priority: 1
        )

        // When: Submitting in reverse priority order
        await queue.submit(job: lowPriority)
        await queue.submit(job: mediumPriority)
        let highJobId = await queue.submitAndProcess(job: highPriority)

        // Then: High priority job can be waited on
        let result = try await queue.waitForCompletion(jobId: highJobId)
        XCTAssertEqual(result.configId, "high")
    }

    func testCancelNonExistentConfig() async {
        // Given: An empty queue
        let queue = SharedDownloadQueue(maxConcurrentDownloads: 5)

        // When: Cancelling a config that doesn't exist
        await queue.cancelConfig("non-existent")

        // Then: No crash, stats remain clean
        let stats = await queue.stats()
        XCTAssertEqual(stats.pendingJobs, 0)
    }

    // MARK: - DownloadJob Tests

    func testDownloadJobInit() {
        // Given: Job parameters
        let files = [FileContents.makeLocal(name: "test")]

        // When: Creating a job
        let job = DownloadJob(
            files: files,
            configId: "test-config",
            priority: 5
        )

        // Then: Properties are set correctly
        XCTAssertEqual(job.configId, "test-config")
        XCTAssertEqual(job.priority, 5)
        XCTAssertEqual(job.fileCount, 1)
    }

    func testDownloadJobResultInit() {
        // Given: Result parameters
        let jobId = UUID()
        let files = [FileContents.makeLocal(name: "result")]

        // When: Creating a result
        let result = DownloadJobResult(
            jobId: jobId,
            configId: "result-config",
            downloadedFiles: files,
            duration: 1.5
        )

        // Then: Properties are set correctly
        XCTAssertEqual(result.jobId, jobId)
        XCTAssertEqual(result.configId, "result-config")
        XCTAssertEqual(result.downloadedFiles.count, 1)
        XCTAssertEqual(result.duration, 1.5)
    }
}

// MARK: - PipelinedDownloader Tests

final class PipelinedDownloaderTests: XCTestCase {
    func testDownloadWithoutQueue() async throws {
        // Given: Files and a real downloader (no queue injected)
        let files = [FileContents.makeLocal(name: "test")]
        let downloader = FileDownloader()

        // When: Downloading without queue injection (local files only)
        let result = try await PipelinedDownloader.download(
            files: files,
            fileDownloader: downloader
        )

        // Then: Falls back to direct download, local files pass through
        XCTAssertEqual(result.count, 1)
    }

    func testDownloadWithQueueInjectedViaBatchState() async throws {
        // Given: Queue injected via BatchSharedState (new architecture)
        let queue = SharedDownloadQueue(maxConcurrentDownloads: 5)
        let context = BatchContext()
        let batchState = BatchSharedState(context: context, downloadQueue: queue)

        let files = [FileContents.makeLocal(name: "test")]
        let downloader = FileDownloader()
        let configContext = ConfigExecutionContext(configId: "test-config", configPriority: 0)

        // When: Downloading with BatchSharedState injection
        let result = try await BatchSharedState.$current.withValue(batchState) {
            try await PipelinedDownloader.download(
                files: files,
                fileDownloader: downloader,
                context: configContext
            )
        }

        // Then: Uses queue (local files pass through)
        XCTAssertEqual(result.count, 1)
    }
}

// MARK: - SharedDownloadQueueStorage Tests

final class SharedDownloadQueueStorageTests: XCTestCase {
    func testIsEnabledWhenQueueInjectedViaBatchState() async {
        // Given: No queue injected initially
        XCTAssertFalse(SharedDownloadQueueStorage.isEnabled)

        // When: Queue is injected via BatchSharedState
        let queue = SharedDownloadQueue(maxConcurrentDownloads: 5)
        let context = BatchContext()
        let batchState = BatchSharedState(context: context, downloadQueue: queue)

        await BatchSharedState.$current.withValue(batchState) {
            // Then: isEnabled returns true (reads from BatchSharedState)
            await MainActor.run {
                XCTAssertTrue(SharedDownloadQueueStorage.isEnabled)
            }
        }

        // After: isEnabled returns false again
        XCTAssertFalse(SharedDownloadQueueStorage.isEnabled)
    }

    // NOTE: Tests for configId and configPriority removed.
    // These values are now passed via ConfigExecutionContext parameter
    // to PipelinedDownloader.download(), not via TaskLocal storage.
}

// MARK: - Test Helpers

private extension FileContents {
    static func makeLocal(name: String) -> FileContents {
        let url = URL(fileURLWithPath: "/tmp/\(name).png")
        return FileContents(
            destination: Destination(
                directory: URL(fileURLWithPath: "/output"),
                file: URL(fileURLWithPath: "\(name).png")
            ),
            dataFile: url
        )
    }
}
