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

    func testDownloadWithQueueInjected() async throws {
        // Given: Queue injected via TaskLocal
        let queue = SharedDownloadQueue(maxConcurrentDownloads: 5)
        let files = [FileContents.makeLocal(name: "test")]
        let downloader = FileDownloader()

        // When: Downloading with queue injection (local files only)
        let result = try await SharedDownloadQueueStorage.$queue.withValue(queue) {
            try await SharedDownloadQueueStorage.$configId.withValue("test-config") {
                try await PipelinedDownloader.download(
                    files: files,
                    fileDownloader: downloader
                )
            }
        }

        // Then: Uses queue (local files pass through)
        XCTAssertEqual(result.count, 1)
    }
}

// MARK: - SharedDownloadQueueStorage Tests

final class SharedDownloadQueueStorageTests: XCTestCase {
    func testIsEnabledWhenQueueInjected() async {
        // Given: No queue injected initially
        XCTAssertFalse(SharedDownloadQueueStorage.isEnabled)

        // When: Queue is injected
        let queue = SharedDownloadQueue(maxConcurrentDownloads: 5)
        await SharedDownloadQueueStorage.$queue.withValue(queue) {
            // Then: isEnabled returns true
            await MainActor.run {
                XCTAssertTrue(SharedDownloadQueueStorage.isEnabled)
            }
        }

        // After: isEnabled returns false again
        XCTAssertFalse(SharedDownloadQueueStorage.isEnabled)
    }

    func testDefaultPriority() {
        // Given: No priority set
        // Then: Default priority is 0
        XCTAssertEqual(SharedDownloadQueueStorage.configPriority, 0)
    }

    func testConfigIdInjection() async {
        // Given: No config ID initially
        XCTAssertNil(SharedDownloadQueueStorage.configId)

        // When: Config ID is injected
        await SharedDownloadQueueStorage.$configId.withValue("my-config") {
            // Then: Config ID is available
            await MainActor.run {
                XCTAssertEqual(SharedDownloadQueueStorage.configId, "my-config")
            }
        }

        // After: Config ID is nil again
        XCTAssertNil(SharedDownloadQueueStorage.configId)
    }
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
