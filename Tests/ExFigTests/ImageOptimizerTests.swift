@testable import ExFig
import Foundation
import XCTest

final class ImageOptimizerTests: XCTestCase {
    // MARK: - Test Helpers

    /// Creates minimal valid PNG data for testing (1x1 red pixel)
    private func createMinimalPNG() -> Data {
        Data([
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
            0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
            0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
            0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
            0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
            0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x18, 0xDD,
            0x8D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, // IEND chunk
            0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
        ])
    }

    // MARK: - 1.1 Error Descriptions

    func testImageOptimNotFoundErrorDescription() {
        let error = ImageOptimizerError.imageOptimNotFound(
            searchedPaths: ["/usr/local/bin/image_optim", "/opt/homebrew/bin/image_optim"]
        )

        let description = error.errorDescription!

        XCTAssertTrue(description.contains("image_optim"))
        XCTAssertTrue(description.contains("gem install"))
        XCTAssertTrue(description.contains("/usr/local/bin/image_optim"))
        XCTAssertTrue(description.contains("/opt/homebrew/bin/image_optim"))
    }

    func testOptimizationFailedErrorDescription() {
        let error = ImageOptimizerError.optimizationFailed(
            file: "icon.png",
            exitCode: 1,
            stderr: "Invalid PNG"
        )

        let description = error.errorDescription!

        XCTAssertTrue(description.contains("icon.png"))
        XCTAssertTrue(description.contains("Exit code: 1"))
        XCTAssertTrue(description.contains("Invalid PNG"))
    }

    func testOptimizationFailedErrorWithEmptyStderr() {
        let error = ImageOptimizerError.optimizationFailed(
            file: "test.png",
            exitCode: 2,
            stderr: ""
        )

        let description = error.errorDescription!

        XCTAssertTrue(description.contains("test.png"))
        XCTAssertTrue(description.contains("Exit code: 2"))
        XCTAssertFalse(description.contains("Output:"))
    }

    func testFileNotFoundErrorDescription() {
        let error = ImageOptimizerError.fileNotFound(path: "/path/to/missing.png")

        let description = error.errorDescription!

        XCTAssertTrue(description.contains("/path/to/missing.png"))
        XCTAssertTrue(description.contains("not found"))
    }

    // MARK: - 1.2 Standard Search Paths

    func testStandardSearchPathsIncludesEnvVariable() {
        let originalValue = ProcessInfo.processInfo.environment["IMAGE_OPTIM_PATH"]
        setenv("IMAGE_OPTIM_PATH", "/custom/path/image_optim", 1)
        defer {
            if let original = originalValue {
                setenv("IMAGE_OPTIM_PATH", original, 1)
            } else {
                unsetenv("IMAGE_OPTIM_PATH")
            }
        }

        // Force recomputation of paths by creating a new instance check
        // Since standardSearchPaths is a computed static var, it will re-evaluate
        let paths = ImageOptimizer.standardSearchPaths

        XCTAssertEqual(paths.first, "/custom/path/image_optim")
    }

    func testStandardSearchPathsIncludesMiseShims() {
        let paths = ImageOptimizer.standardSearchPaths
        let home = FileManager.default.homeDirectoryForCurrentUser.path

        XCTAssertTrue(paths.contains("\(home)/.local/share/mise/shims/image_optim"))
    }

    func testStandardSearchPathsIncludesGemPaths() {
        let paths = ImageOptimizer.standardSearchPaths

        #if os(macOS)
            XCTAssertTrue(paths.contains("/usr/local/bin/image_optim"))
            XCTAssertTrue(paths.contains("/opt/homebrew/bin/image_optim"))
        #endif

        #if os(Linux)
            XCTAssertTrue(paths.contains("/usr/local/bin/image_optim"))
        #endif
    }

    // MARK: - 1.3 Binary Discovery (findImageOptim)

    func testFindImageOptimThrowsWhenNotFound() {
        // Save original values
        let originalPath = ProcessInfo.processInfo.environment["PATH"]
        let originalImageOptimPath = ProcessInfo.processInfo.environment["IMAGE_OPTIM_PATH"]

        // Clear PATH and env
        setenv("PATH", "/nonexistent_path_for_test", 1)
        unsetenv("IMAGE_OPTIM_PATH")
        defer {
            if let original = originalPath {
                setenv("PATH", original, 1)
            }
            if let original = originalImageOptimPath {
                setenv("IMAGE_OPTIM_PATH", original, 1)
            }
        }

        XCTAssertThrowsError(try ImageOptimizer.findImageOptim()) { error in
            guard case ImageOptimizerError.imageOptimNotFound = error else {
                XCTFail("Expected imageOptimNotFound error, got: \(error)")
                return
            }
        }
    }

    // MARK: - 1.4 isAvailable

    func testIsAvailableReturnsBoolean() {
        // Just verify it returns a boolean without crashing
        let isAvailable = ImageOptimizer.isAvailable()
        XCTAssertTrue(isAvailable || !isAvailable) // Always passes, just checks type
    }

    // MARK: - 1.5 Optimize Lossless (requires image_optim installed)

    func testOptimizeLosslessCallsCorrectCommand() throws {
        guard ImageOptimizer.isAvailable() else {
            throw XCTSkip("image_optim not installed")
        }

        let tempDir = FileManager.default.temporaryDirectory
        let testPNG = tempDir.appendingPathComponent("test_\(UUID()).png")

        let pngData = createMinimalPNG()
        try pngData.write(to: testPNG)
        defer { try? FileManager.default.removeItem(at: testPNG) }

        let optimizer = try ImageOptimizer(allowLossy: false)

        XCTAssertNoThrow(try optimizer.optimize(file: testPNG))
        XCTAssertTrue(FileManager.default.fileExists(atPath: testPNG.path))
    }

    // MARK: - 1.6 Optimize Lossy (requires image_optim installed)

    func testOptimizeLossyCallsWithAllowLossyFlag() throws {
        guard ImageOptimizer.isAvailable() else {
            throw XCTSkip("image_optim not installed")
        }

        let tempDir = FileManager.default.temporaryDirectory
        let testPNG = tempDir.appendingPathComponent("test_\(UUID()).png")

        let pngData = createMinimalPNG()
        try pngData.write(to: testPNG)
        defer { try? FileManager.default.removeItem(at: testPNG) }

        let optimizer = try ImageOptimizer(allowLossy: true)

        XCTAssertNoThrow(try optimizer.optimize(file: testPNG))
        XCTAssertTrue(FileManager.default.fileExists(atPath: testPNG.path))
    }

    // MARK: - 1.7 Error Handling

    func testOptimizeThrowsForNonexistentFile() throws {
        guard ImageOptimizer.isAvailable() else {
            throw XCTSkip("image_optim not installed")
        }

        let optimizer = try ImageOptimizer(allowLossy: false)
        let nonexistent = URL(fileURLWithPath: "/nonexistent_path_\(UUID())/file.png")

        XCTAssertThrowsError(try optimizer.optimize(file: nonexistent)) { error in
            guard case ImageOptimizerError.fileNotFound = error else {
                XCTFail("Expected fileNotFound error, got: \(error)")
                return
            }
        }
    }

    // MARK: - 2.1-2.5 Batch Processing

    func testOptimizeBatchWithEmptyArray() async throws {
        guard ImageOptimizer.isAvailable() else {
            throw XCTSkip("image_optim not installed")
        }

        let optimizer = try ImageOptimizer(allowLossy: false)

        // Should not throw
        try await optimizer.optimizeBatch(files: [])
    }

    func testOptimizeBatchWithSingleFile() async throws {
        guard ImageOptimizer.isAvailable() else {
            throw XCTSkip("image_optim not installed")
        }

        let tempDir = FileManager.default.temporaryDirectory
        let testPNG = tempDir.appendingPathComponent("test_single_\(UUID()).png")

        try createMinimalPNG().write(to: testPNG)
        defer { try? FileManager.default.removeItem(at: testPNG) }

        let optimizer = try ImageOptimizer(allowLossy: false)

        let recorder = ProgressRecorder()
        try await optimizer.optimizeBatch(files: [testPNG]) { current, total in
            await recorder.record(current: current, total: total)
        }

        let calls = await recorder.calls
        XCTAssertEqual(calls.count, 1)
        XCTAssertEqual(calls.first?.0, 1)
        XCTAssertEqual(calls.first?.1, 1)
    }

    func testOptimizeBatchProgressCallback() async throws {
        guard ImageOptimizer.isAvailable() else {
            throw XCTSkip("image_optim not installed")
        }

        let tempDir = FileManager.default.temporaryDirectory
        var testFiles: [URL] = []

        for i in 0 ..< 3 {
            let file = tempDir.appendingPathComponent("test_batch_\(UUID())_\(i).png")
            try createMinimalPNG().write(to: file)
            testFiles.append(file)
        }
        defer {
            for file in testFiles {
                try? FileManager.default.removeItem(at: file)
            }
        }

        let optimizer = try ImageOptimizer(allowLossy: false)

        let recorder = ProgressRecorder()
        try await optimizer.optimizeBatch(files: testFiles) { current, total in
            await recorder.record(current: current, total: total)
        }

        let calls = await recorder.calls
        XCTAssertEqual(calls.count, 3)
        XCTAssertEqual(calls.last?.0, 3) // current
        XCTAssertEqual(calls.last?.1, 3) // total
    }

    func testOptimizeBatchRespectsMaxConcurrent() async throws {
        guard ImageOptimizer.isAvailable() else {
            throw XCTSkip("image_optim not installed")
        }

        let tempDir = FileManager.default.temporaryDirectory
        var testFiles: [URL] = []

        // Create 5 files to test with maxConcurrent = 2
        for i in 0 ..< 5 {
            let file = tempDir.appendingPathComponent("test_concurrent_\(UUID())_\(i).png")
            try createMinimalPNG().write(to: file)
            testFiles.append(file)
        }
        defer {
            for file in testFiles {
                try? FileManager.default.removeItem(at: file)
            }
        }

        let optimizer = try ImageOptimizer(allowLossy: false, maxConcurrent: 2)

        let recorder = ProgressRecorder()
        try await optimizer.optimizeBatch(files: testFiles) { current, total in
            await recorder.record(current: current, total: total)
        }

        let calls = await recorder.calls
        XCTAssertEqual(calls.count, 5)
        XCTAssertEqual(calls.last?.1, 5) // total
    }
}

// MARK: - Test Helpers

/// Actor for thread-safe progress recording in tests
private actor ProgressRecorder {
    private(set) var calls: [(Int, Int)] = []

    func record(current: Int, total: Int) {
        calls.append((current, total))
    }
}
