@testable import ExFigCLI
@testable import ExFigCore
import Foundation
import XCTest

final class FileWriterTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileWriterTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Initialization

    func testInitialization() {
        let writer = FileWriter()
        XCTAssertNotNil(writer)
    }

    func testInitializationWithCustomConcurrency() {
        let writer = FileWriter(maxConcurrentWrites: 4)
        XCTAssertNotNil(writer)
    }

    // MARK: - Sequential Write

    func testWriteSingleFile() throws {
        let writer = FileWriter()
        let content = Data("Hello, World!".utf8)
        let file = makeFileContents(filename: "test.txt", data: content)

        try writer.write(files: [file])

        let writtenURL = tempDirectory.appendingPathComponent("test.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: writtenURL.path))

        let writtenData = try Data(contentsOf: writtenURL)
        XCTAssertEqual(writtenData, content)
    }

    func testWriteMultipleFiles() throws {
        let writer = FileWriter()
        let files = [
            makeFileContents(filename: "file1.txt", data: Data("Content 1".utf8)),
            makeFileContents(filename: "file2.txt", data: Data("Content 2".utf8)),
            makeFileContents(filename: "file3.txt", data: Data("Content 3".utf8)),
        ]

        try writer.write(files: files)

        for i in 1 ... 3 {
            let url = tempDirectory.appendingPathComponent("file\(i).txt")
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
    }

    func testWriteCreatesDirectories() throws {
        let writer = FileWriter()
        let subdir = tempDirectory.appendingPathComponent("subdir/nested")
        let destination = try Destination(
            directory: subdir,
            // swiftlint:disable:next force_unwrapping
            file: XCTUnwrap(URL(string: "test.txt"))
        )
        let file = FileContents(destination: destination, data: Data("test".utf8))

        try writer.write(files: [file])

        let writtenURL = subdir.appendingPathComponent("test.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: writtenURL.path))
    }

    func testWriteEmptyArray() throws {
        let writer = FileWriter()

        // Should not throw
        try writer.write(files: [])
    }

    // MARK: - Parallel Write

    func testWriteParallelSingleFile() async throws {
        let writer = FileWriter()
        let content = Data("Parallel content".utf8)
        let file = makeFileContents(filename: "parallel.txt", data: content)

        try await writer.writeParallel(files: [file])

        let writtenURL = tempDirectory.appendingPathComponent("parallel.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: writtenURL.path))
    }

    func testWriteParallelMultipleFiles() async throws {
        let writer = FileWriter()
        let files = (1 ... 10).map { i in
            makeFileContents(filename: "parallel\(i).txt", data: Data("Content \(i)".utf8))
        }

        try await writer.writeParallel(files: files)

        for i in 1 ... 10 {
            let url = tempDirectory.appendingPathComponent("parallel\(i).txt")
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
    }

    func testWriteParallelEmptyArray() async throws {
        let writer = FileWriter()

        // Should not throw
        try await writer.writeParallel(files: [])
    }

    func testWriteParallelWithProgressCallback() async throws {
        let writer = FileWriter()
        let files = (1 ... 5).map { i in
            makeFileContents(filename: "progress\(i).txt", data: Data("Content \(i)".utf8))
        }

        let counter = ProgressCounter()

        try await writer.writeParallel(files: files) { current, total in
            await counter.record(current: current, total: total)
        }

        let finalCount = await counter.count
        let lastUpdate = await counter.lastUpdate

        XCTAssertEqual(finalCount, 5)
        XCTAssertEqual(lastUpdate?.current, 5)
        XCTAssertEqual(lastUpdate?.total, 5)
    }

    func testWriteParallelCreatesSharedDirectories() async throws {
        let writer = FileWriter()
        let subdir = tempDirectory.appendingPathComponent("shared")

        let files = (1 ... 3).map { i -> FileContents in
            let destination = Destination(
                directory: subdir,
                // swiftlint:disable:next force_unwrapping
                file: URL(string: "file\(i).txt")!
            )
            return FileContents(destination: destination, data: Data("Content \(i)".utf8))
        }

        try await writer.writeParallel(files: files)

        for i in 1 ... 3 {
            let url = subdir.appendingPathComponent("file\(i).txt")
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
    }

    // MARK: - Case Mismatch Handling (macOS case-insensitive FS)

    func testWriteRenamesDirectoryOnCaseMismatch() throws {
        let writer = FileWriter()

        // Create existing directory with different case
        let oldCaseDir = tempDirectory.appendingPathComponent("SpeechToText.imageset")
        try FileManager.default.createDirectory(at: oldCaseDir, withIntermediateDirectories: true)

        // Create a marker file to prove it's the same directory being renamed
        let markerFile = oldCaseDir.appendingPathComponent("marker.txt")
        try Data("marker".utf8).write(to: markerFile)

        // Write file to directory with new case
        let newCaseDir = tempDirectory.appendingPathComponent("speechtotext.imageset")
        let destination = try Destination(
            directory: newCaseDir,
            // swiftlint:disable:next force_unwrapping
            file: XCTUnwrap(URL(string: "test.svg"))
        )
        let file = FileContents(destination: destination, data: Data("<svg/>".utf8))

        try writer.write(files: [file])

        // Verify directory was renamed to new case
        let contents = try FileManager.default.contentsOfDirectory(atPath: tempDirectory.path)
        let imagesetDirs = contents.filter { $0.hasSuffix(".imageset") }

        XCTAssertEqual(imagesetDirs.count, 1, "Should have exactly one imageset directory")
        XCTAssertEqual(imagesetDirs.first, "speechtotext.imageset", "Directory should have new case")

        // Verify marker file still exists (proves rename, not recreate)
        let renamedMarker = newCaseDir.appendingPathComponent("marker.txt")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: renamedMarker.path),
            "Marker file should exist after rename"
        )

        // Verify new file was written
        let writtenFile = newCaseDir.appendingPathComponent("test.svg")
        XCTAssertTrue(FileManager.default.fileExists(atPath: writtenFile.path))
    }

    func testWriteParallelRenamesDirectoryOnCaseMismatch() async throws {
        let writer = FileWriter()

        // Create existing directory with different case
        let oldCaseDir = tempDirectory.appendingPathComponent("Icon24px.imageset")
        try FileManager.default.createDirectory(at: oldCaseDir, withIntermediateDirectories: true)

        // Create a marker file
        let markerFile = oldCaseDir.appendingPathComponent("marker.txt")
        try Data("marker".utf8).write(to: markerFile)

        // Write file to directory with new case
        let newCaseDir = tempDirectory.appendingPathComponent("icon24px.imageset")
        let destination = try Destination(
            directory: newCaseDir,
            // swiftlint:disable:next force_unwrapping
            file: XCTUnwrap(URL(string: "icon.svg"))
        )
        let file = FileContents(destination: destination, data: Data("<svg/>".utf8))

        try await writer.writeParallel(files: [file])

        // Verify directory was renamed to new case
        let contents = try FileManager.default.contentsOfDirectory(atPath: tempDirectory.path)
        let imagesetDirs = contents.filter { $0.hasSuffix(".imageset") }

        XCTAssertEqual(imagesetDirs.count, 1)
        XCTAssertEqual(imagesetDirs.first, "icon24px.imageset")

        // Verify marker file still exists
        let renamedMarker = newCaseDir.appendingPathComponent("marker.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: renamedMarker.path))
    }

    func testWriteDoesNotRenameWhenCaseMatches() throws {
        let writer = FileWriter()

        // Create existing directory with matching case
        let existingDir = tempDirectory.appendingPathComponent("correct.imageset")
        try FileManager.default.createDirectory(at: existingDir, withIntermediateDirectories: true)

        // Write file to same directory (same case)
        let destination = try Destination(
            directory: existingDir,
            // swiftlint:disable:next force_unwrapping
            file: XCTUnwrap(URL(string: "test.svg"))
        )
        let file = FileContents(destination: destination, data: Data("<svg/>".utf8))

        try writer.write(files: [file])

        // Verify directory still exists with same name
        let contents = try FileManager.default.contentsOfDirectory(atPath: tempDirectory.path)
        XCTAssertTrue(contents.contains("correct.imageset"))
    }

    func testWriteCreatesNewDirectoryWhenNoMismatch() throws {
        let writer = FileWriter()

        // No existing directory - should just create new one
        let newDir = tempDirectory.appendingPathComponent("brand-new.imageset")
        let destination = try Destination(
            directory: newDir,
            // swiftlint:disable:next force_unwrapping
            file: XCTUnwrap(URL(string: "test.svg"))
        )
        let file = FileContents(destination: destination, data: Data("<svg/>".utf8))

        try writer.write(files: [file])

        // Verify directory was created
        XCTAssertTrue(FileManager.default.fileExists(atPath: newDir.path))
    }

    // MARK: - Subdirectory Paths

    func testWriteCreatesSubdirectoriesFromFilePath() throws {
        let writer = FileWriter()
        let destination = try Destination(
            directory: tempDirectory,
            // swiftlint:disable:next force_unwrapping
            file: XCTUnwrap(URL(string: "subdir/file.txt"))
        )
        let file = FileContents(destination: destination, data: Data("subdirectory content".utf8))

        try writer.write(files: [file])

        let writtenURL = tempDirectory.appendingPathComponent("subdir/file.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: writtenURL.path))

        let writtenData = try Data(contentsOf: writtenURL)
        XCTAssertEqual(writtenData, Data("subdirectory content".utf8))
    }

    func testWriteParallelCreatesSubdirectoriesFromFilePath() async throws {
        let writer = FileWriter()
        let destination = try Destination(
            directory: tempDirectory,
            // swiftlint:disable:next force_unwrapping
            file: XCTUnwrap(URL(string: "icons/actions.dart"))
        )
        let file = FileContents(destination: destination, data: Data("dart content".utf8))

        try await writer.writeParallel(files: [file])

        let writtenURL = tempDirectory.appendingPathComponent("icons/actions.dart")
        XCTAssertTrue(FileManager.default.fileExists(atPath: writtenURL.path))
    }

    // MARK: - File from Disk

    func testWriteFromDataFile() throws {
        let writer = FileWriter()

        // Create source file
        let sourceURL = tempDirectory.appendingPathComponent("source.txt")
        try Data("Source content".utf8).write(to: sourceURL)

        // Create FileContents with dataFile
        let destDir = tempDirectory.appendingPathComponent("dest")
        let destination = try Destination(
            directory: destDir,
            // swiftlint:disable:next force_unwrapping
            file: XCTUnwrap(URL(string: "copied.txt"))
        )
        let file = FileContents(destination: destination, dataFile: sourceURL)

        try writer.write(files: [file])

        let destURL = destDir.appendingPathComponent("copied.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: destURL.path))
    }

    // MARK: - Helpers

    private func makeFileContents(filename: String, data: Data) -> FileContents {
        let destination = Destination(
            directory: tempDirectory,
            // swiftlint:disable:next force_unwrapping
            file: URL(string: filename)!
        )
        return FileContents(destination: destination, data: data)
    }
}

// MARK: - Test Helpers

private actor ProgressCounter {
    private(set) var count = 0
    private(set) var lastUpdate: (current: Int, total: Int)?

    func record(current: Int, total: Int) {
        count += 1
        lastUpdate = (current, total)
    }
}
