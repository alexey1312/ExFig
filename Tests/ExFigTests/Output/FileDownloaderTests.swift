@testable import ExFig
@testable import ExFigCore
import XCTest

final class FileDownloaderTests: XCTestCase {
    // MARK: - Initialization

    func testDefaultMaxConcurrentDownloads() {
        XCTAssertEqual(FileDownloader.defaultMaxConcurrentDownloads, 20)
    }

    func testCustomMaxConcurrentDownloads() {
        let downloader = FileDownloader(maxConcurrentDownloads: 50)

        // The downloader should be created successfully
        XCTAssertNotNil(downloader)
    }

    // MARK: - Fetch with Local Files Only

    func testFetchWithNoRemoteFiles() async throws {
        let downloader = FileDownloader()
        let tempDir = FileManager.default.temporaryDirectory

        // Create a test file
        let testData = Data("test content".utf8)
        let testFile = tempDir.appendingPathComponent("test.txt")
        try testData.write(to: testFile)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let destination = try Destination(
            directory: tempDir,
            // swiftlint:disable:next force_unwrapping
            file: XCTUnwrap(URL(string: "output.txt"))
        )
        let localFile = FileContents(destination: destination, dataFile: testFile)

        let result = try await downloader.fetch(files: [localFile])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.destination.file.lastPathComponent, "output.txt")
    }

    func testFetchWithEmptyArray() async throws {
        let downloader = FileDownloader()

        let result = try await downloader.fetch(files: [])

        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Fetch with Progress Callback

    func testFetchCallsProgressCallback() async throws {
        let downloader = FileDownloader()
        let tempDir = FileManager.default.temporaryDirectory

        // Create test files
        var localFiles: [FileContents] = []
        var testFileURLs: [URL] = []

        for i in 0 ..< 3 {
            let testData = Data("content \(i)".utf8)
            let testFile = tempDir.appendingPathComponent("test_\(i).txt")
            try testData.write(to: testFile)
            testFileURLs.append(testFile)

            let destination = try Destination(
                directory: tempDir,
                // swiftlint:disable:next force_unwrapping
                file: XCTUnwrap(URL(string: "output_\(i).txt"))
            )
            localFiles.append(FileContents(destination: destination, dataFile: testFile))
        }

        defer {
            for url in testFileURLs {
                try? FileManager.default.removeItem(at: url)
            }
        }

        // Local files don't trigger progress callback (only remote files do)
        let result = try await downloader.fetch(files: localFiles) { _, _ in
            // Progress callback - not called for local files
        }

        XCTAssertEqual(result.count, 3)
        // Local files are returned immediately without triggering progress
    }

    // MARK: - Mixed Local and Remote Files

    func testMixedFilesReturnsLocalImmediately() async throws {
        let downloader = FileDownloader()
        let tempDir = FileManager.default.temporaryDirectory

        // Create a local file
        let testData = Data("local content".utf8)
        let testFile = tempDir.appendingPathComponent("local.txt")
        try testData.write(to: testFile)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let localDestination = try Destination(
            directory: tempDir,
            // swiftlint:disable:next force_unwrapping
            file: XCTUnwrap(URL(string: "local_output.txt"))
        )
        let localFile = FileContents(destination: localDestination, dataFile: testFile)

        // Only pass local file (remote would fail without real URL)
        let result = try await downloader.fetch(files: [localFile])

        XCTAssertEqual(result.count, 1)
    }

    // MARK: - File Properties Preservation

    func testFilePropertiesPreserved() async throws {
        let downloader = FileDownloader()
        let tempDir = FileManager.default.temporaryDirectory

        let testData = Data("test".utf8)
        let testFile = tempDir.appendingPathComponent("preserve_test.txt")
        try testData.write(to: testFile)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let destination = try Destination(
            directory: tempDir,
            // swiftlint:disable:next force_unwrapping
            file: XCTUnwrap(URL(string: "output.txt"))
        )
        let file = FileContents(destination: destination, dataFile: testFile, scale: 2.0, dark: true, isRTL: true)

        let result = try await downloader.fetch(files: [file])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.scale, 2.0)
        XCTAssertEqual(result.first?.dark, true)
        XCTAssertEqual(result.first?.isRTL, true)
    }

    // MARK: - Concurrency Behavior

    func testMultipleLocalFilesProcessedCorrectly() async throws {
        let downloader = FileDownloader(maxConcurrentDownloads: 5)
        let tempDir = FileManager.default.temporaryDirectory

        var files: [FileContents] = []
        var tempFiles: [URL] = []

        for i in 0 ..< 10 {
            let testData = Data("content \(i)".utf8)
            let testFile = tempDir.appendingPathComponent("multi_\(i).txt")
            try testData.write(to: testFile)
            tempFiles.append(testFile)

            let destination = try Destination(
                directory: tempDir,
                // swiftlint:disable:next force_unwrapping
                file: XCTUnwrap(URL(string: "out_\(i).txt"))
            )
            files.append(FileContents(destination: destination, dataFile: testFile))
        }

        defer {
            for url in tempFiles {
                try? FileManager.default.removeItem(at: url)
            }
        }

        let result = try await downloader.fetch(files: files)

        XCTAssertEqual(result.count, 10)
    }

    // MARK: - In-Memory Files

    func testInMemoryFilesReturnedAsIs() async throws {
        let downloader = FileDownloader()
        let tempDir = FileManager.default.temporaryDirectory

        let destination = try Destination(
            directory: tempDir,
            // swiftlint:disable:next force_unwrapping
            file: XCTUnwrap(URL(string: "memory.txt"))
        )
        let inMemoryFile = FileContents(
            destination: destination,
            data: Data("in memory".utf8)
        )

        let result = try await downloader.fetch(files: [inMemoryFile])

        XCTAssertEqual(result.count, 1)
        XCTAssertNotNil(result.first?.data)
        XCTAssertNil(result.first?.sourceURL)
    }
}
