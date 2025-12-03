# Design: Image Optimization via image_optim

## Context

ExFig exports images in PNG, JPEG, GIF, and SVG formats. Currently, there's no optimization step — files are written
as-is from Figma. The `image_optim` Ruby gem provides a unified CLI that orchestrates multiple optimization tools.

## Goals / Non-Goals

**Goals:**

- Add optional image optimization for all platforms (iOS, Android, Flutter)
- Support lossless (safe) and lossy (aggressive) modes
- Follow existing pattern from `WebpConverter`
- Graceful degradation when `image_optim` is not installed

**Non-Goals:**

- Bundle `image_optim` binaries (user installs separately)
- Optimize WebP files (already optimized by cwebp)
- Custom per-format configuration (v1 uses image_optim defaults)

## Decisions

### Decision: Use image_optim CLI

**Rationale:** Single tool that orchestrates oxipng, pngquant, jpegoptim, mozjpeg, gifsicle, svgo. No need to integrate
each tool separately.

**Alternatives considered:**

- Individual tools (oxipng, pngquant): More control but more complexity
- sharp-cli (Node.js): Requires Node.js runtime
- Squoosh CLI: No longer maintained

### Decision: Warning instead of error when not installed

**Rationale:** Optimization is optional enhancement. Users shouldn't be blocked from exporting if they don't have
image_optim installed.

______________________________________________________________________

## TDD Implementation Plan

### Phase 1: ImageOptimizer Core

#### Test 1.1: Error descriptions

```swift
// Tests/ExFigTests/ImageOptimizerTests.swift

func testImageOptimNotFoundErrorDescription() {
    let error = ImageOptimizerError.imageOptimNotFound(searchedPaths: ["/usr/local/bin/image_optim"])

    let description = error.errorDescription!

    XCTAssertTrue(description.contains("image_optim"))
    XCTAssertTrue(description.contains("gem install"))
    XCTAssertTrue(description.contains("/usr/local/bin/image_optim"))
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
```

#### Test 1.2: Standard search paths

```swift
func testStandardSearchPathsIncludesEnvVariable() {
    // When IMAGE_OPTIM_PATH is set, it should be first
    setenv("IMAGE_OPTIM_PATH", "/custom/path/image_optim", 1)
    defer { unsetenv("IMAGE_OPTIM_PATH") }

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

    XCTAssertTrue(paths.contains("/usr/local/bin/image_optim"))
}
```

#### Test 1.3: Binary discovery

```swift
func testFindImageOptimUsesWhichFirst() throws {
    // Create mock executable
    let tempDir = FileManager.default.temporaryDirectory
    let mockBin = tempDir.appendingPathComponent("image_optim")
    FileManager.default.createFile(atPath: mockBin.path, contents: nil)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: mockBin.path)
    defer { try? FileManager.default.removeItem(at: mockBin) }

    // Mock PATH to include temp dir
    let originalPath = ProcessInfo.processInfo.environment["PATH"] ?? ""
    setenv("PATH", "\(tempDir.path):\(originalPath)", 1)
    defer { setenv("PATH", originalPath, 1) }

    let found = try ImageOptimizer.findImageOptim()

    XCTAssertEqual(found.path, mockBin.path)
}

func testFindImageOptimThrowsWhenNotFound() {
    // Clear PATH and env
    setenv("PATH", "/nonexistent", 1)
    setenv("IMAGE_OPTIM_PATH", "", 1)

    XCTAssertThrowsError(try ImageOptimizer.findImageOptim()) { error in
        if case ImageOptimizerError.imageOptimNotFound = error {
            // Success
        } else {
            XCTFail("Expected imageOptimNotFound error")
        }
    }
}
```

#### Test 1.4: isAvailable

```swift
func testIsAvailableReturnsFalseWhenNotInstalled() {
    setenv("PATH", "/nonexistent", 1)
    setenv("IMAGE_OPTIM_PATH", "", 1)

    XCTAssertFalse(ImageOptimizer.isAvailable())
}
```

#### Test 1.5: Optimize single file (lossless)

```swift
func testOptimizeLosslessCallsCorrectCommand() throws {
    // This test requires image_optim to be installed
    // Skip if not available
    guard ImageOptimizer.isAvailable() else {
        throw XCTSkip("image_optim not installed")
    }

    let tempDir = FileManager.default.temporaryDirectory
    let testPNG = tempDir.appendingPathComponent("test_\(UUID()).png")

    // Create minimal valid PNG
    let pngData = createMinimalPNG()
    try pngData.write(to: testPNG)
    defer { try? FileManager.default.removeItem(at: testPNG) }

    let optimizer = try ImageOptimizer(allowLossy: false)

    XCTAssertNoThrow(try optimizer.optimize(file: testPNG))
    XCTAssertTrue(FileManager.default.fileExists(atPath: testPNG.path))
}
```

#### Test 1.6: Optimize single file (lossy)

```swift
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
}
```

#### Test 1.7: Error handling

```swift
func testOptimizeThrowsForNonexistentFile() throws {
    guard ImageOptimizer.isAvailable() else {
        throw XCTSkip("image_optim not installed")
    }

    let optimizer = try ImageOptimizer(allowLossy: false)
    let nonexistent = URL(fileURLWithPath: "/nonexistent/file.png")

    XCTAssertThrowsError(try optimizer.optimize(file: nonexistent)) { error in
        if case ImageOptimizerError.fileNotFound = error {
            // Success
        } else {
            XCTFail("Expected fileNotFound error")
        }
    }
}
```

#### Implementation 1: ImageOptimizer.swift

```swift
// Sources/ExFig/Output/ImageOptimizer.swift

import ExFigCore
import Foundation

/// Progress callback type for optimization operations
typealias OptimizationProgressCallback = @Sendable (Int, Int) async -> Void

/// Errors that can occur during image optimization
enum ImageOptimizerError: LocalizedError, Equatable {
    case imageOptimNotFound(searchedPaths: [String])
    case optimizationFailed(file: String, exitCode: Int32, stderr: String)
    case fileNotFound(path: String)

    var errorDescription: String? {
        switch self {
        case let .imageOptimNotFound(searchedPaths):
            return """
            'image_optim' tool not found.

            Image optimization requires the 'image_optim' Ruby gem.

            Install using one of these methods:
              • Via mise:  mise use -g gem:image_optim gem:image_optim_pack
              • Via gem:   gem install image_optim image_optim_pack

            Or specify a custom path via environment variable:
              export IMAGE_OPTIM_PATH=/path/to/image_optim

            Searched locations:
            \(searchedPaths.map { "  ✗ \($0)" }.joined(separator: "\n"))
            """
        case let .optimizationFailed(file, exitCode, stderr):
            let stderrInfo = stderr.isEmpty ? "" : "\nOutput: \(stderr)"
            return """
            Image optimization failed for '\(file)'.

            Exit code: \(exitCode)\(stderrInfo)
            """
        case let .fileNotFound(path):
            return "Input file not found: \(path)"
        }
    }
}

/// Image optimizer using image_optim CLI (PNG, JPEG, GIF, SVG)
final class ImageOptimizer: Sendable {
    /// Standard paths where image_optim might be installed
    static let standardSearchPaths: [String] = {
        var paths = [String]()

        // 1. Environment variable (highest priority)
        if let customPath = ProcessInfo.processInfo.environment["IMAGE_OPTIM_PATH"],
           !customPath.isEmpty
        {
            paths.append(customPath)
        }

        let home = FileManager.default.homeDirectoryForCurrentUser.path

        // 2. mise shims
        paths.append("\(home)/.local/share/mise/shims/image_optim")

        // 3. Ruby gem paths
        #if os(macOS)
            paths += [
                "/usr/local/bin/image_optim", // Homebrew gem install
                "/opt/homebrew/bin/image_optim", // Apple Silicon Homebrew
                "\(home)/.gem/ruby/3.0.0/bin/image_optim",
                "\(home)/.gem/ruby/3.1.0/bin/image_optim",
                "\(home)/.gem/ruby/3.2.0/bin/image_optim",
                "\(home)/.gem/ruby/3.3.0/bin/image_optim",
            ]
        #endif

        #if os(Linux)
            paths += [
                "/usr/local/bin/image_optim",
                "\(home)/.local/bin/image_optim",
                "/home/linuxbrew/.linuxbrew/bin/image_optim",
            ]
        #endif

        return paths
    }()

    private let allowLossy: Bool
    private let maxConcurrent: Int
    private let executableURL: URL

    /// Creates an ImageOptimizer
    /// - Parameters:
    ///   - allowLossy: Allow lossy compression (pngquant, mozjpeg)
    ///   - maxConcurrent: Maximum parallel optimizations (default: 4)
    /// - Throws: `ImageOptimizerError.imageOptimNotFound` if not installed
    init(allowLossy: Bool = false, maxConcurrent: Int = 4) throws {
        self.allowLossy = allowLossy
        self.maxConcurrent = maxConcurrent
        executableURL = try Self.findImageOptim()
    }

    /// Finds image_optim executable
    static func findImageOptim() throws -> URL {
        // First, try PATH via `which`
        if let pathResult = try? findInPath("image_optim") {
            return pathResult
        }

        // Then check standard paths
        let fileManager = FileManager.default
        for path in standardSearchPaths {
            let expandedPath = NSString(string: path).expandingTildeInPath
            if fileManager.isExecutableFile(atPath: expandedPath) {
                return URL(fileURLWithPath: expandedPath)
            }
        }

        throw ImageOptimizerError.imageOptimNotFound(searchedPaths: standardSearchPaths)
    }

    /// Checks if image_optim is available
    static func isAvailable() -> Bool {
        (try? findImageOptim()) != nil
    }

    /// Optimizes a single image file in-place
    func optimize(file url: URL) throws {
        try optimizeSync(file: url)
    }

    /// Optimizes multiple files in parallel
    func optimizeBatch(
        files: [URL],
        onProgress: OptimizationProgressCallback? = nil
    ) async throws {
        guard !files.isEmpty else { return }

        let totalCount = files.count

        try await withThrowingTaskGroup(of: Void.self) { [self] group in
            var iterator = files.makeIterator()
            var activeCount = 0
            var completedCount = 0

            // Start initial batch
            for _ in 0 ..< min(maxConcurrent, files.count) {
                if let file = iterator.next() {
                    group.addTask { [file] in
                        try self.optimizeSync(file: file)
                    }
                    activeCount += 1
                }
            }

            // Process completed and start new
            for try await _ in group {
                activeCount -= 1
                completedCount += 1

                if let onProgress {
                    await onProgress(completedCount, totalCount)
                }

                if let file = iterator.next() {
                    group.addTask { [file] in
                        try self.optimizeSync(file: file)
                    }
                    activeCount += 1
                }
            }
        }
    }

    // MARK: - Private

    private func optimizeSync(file url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ImageOptimizerError.fileNotFound(path: url.path)
        }

        let task = Process()
        task.executableURL = executableURL

        var arguments = [url.path]
        if allowLossy {
            arguments.insert("--allow-lossy", at: 0)
        }
        task.arguments = arguments

        let stderrPipe = Pipe()
        task.standardError = stderrPipe
        task.standardOutput = FileHandle.nullDevice

        try task.run()
        task.waitUntilExit()

        guard task.terminationStatus == 0 else {
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let stderr = String(data: stderrData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            throw ImageOptimizerError.optimizationFailed(
                file: url.lastPathComponent,
                exitCode: task.terminationStatus,
                stderr: stderr
            )
        }
    }

    private static func findInPath(_ executable: String) throws -> URL? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = [executable]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        try task.run()
        task.waitUntilExit()

        guard task.terminationStatus == 0 else { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let path = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !path.isEmpty
        else {
            return nil
        }

        return URL(fileURLWithPath: path)
    }
}
```

______________________________________________________________________

### Phase 2: Batch Processing Tests

#### Test 2.1-2.5: Batch operations

```swift
func testOptimizeBatchWithEmptyArray() async throws {
    guard ImageOptimizer.isAvailable() else {
        throw XCTSkip("image_optim not installed")
    }

    let optimizer = try ImageOptimizer(allowLossy: false)

    // Should not throw
    try await optimizer.optimizeBatch(files: [])
}

func testOptimizeBatchProgressCallback() async throws {
    guard ImageOptimizer.isAvailable() else {
        throw XCTSkip("image_optim not installed")
    }

    let tempDir = FileManager.default.temporaryDirectory
    var testFiles: [URL] = []

    for i in 0 ..< 3 {
        let file = tempDir.appendingPathComponent("test_\(UUID())_\(i).png")
        try createMinimalPNG().write(to: file)
        testFiles.append(file)
    }
    defer { testFiles.forEach { try? FileManager.default.removeItem(at: $0) } }

    let optimizer = try ImageOptimizer(allowLossy: false)

    var progressCalls: [(Int, Int)] = []
    try await optimizer.optimizeBatch(files: testFiles) { current, total in
        progressCalls.append((current, total))
    }

    XCTAssertEqual(progressCalls.count, 3)
    XCTAssertEqual(progressCalls.last?.0, 3) // current
    XCTAssertEqual(progressCalls.last?.1, 3) // total
}
```

______________________________________________________________________

### Phase 3: Configuration Tests

#### Test 3.1-3.5: Params parsing

```swift
// Tests/ExFigTests/ParamsOptimizeTests.swift

func testOptimizeOptionsDecoding() throws {
    let yaml = """
    allowLossy: true
    """

    let options = try YAMLDecoder().decode(OptimizeOptions.self, from: yaml)

    XCTAssertEqual(options.allowLossy, true)
}

func testOptimizeOptionsDefaultAllowLossy() throws {
    let yaml = "{}"

    let options = try YAMLDecoder().decode(OptimizeOptions.self, from: yaml)

    XCTAssertNil(options.allowLossy)
}

func testIOSImagesWithOptimize() throws {
    let yaml = """
    output: "Assets.xcassets"
    optimize: true
    optimizeOptions:
      allowLossy: false
    """

    let images = try YAMLDecoder().decode(Params.iOS.Images.self, from: yaml)

    XCTAssertEqual(images.optimize, true)
    XCTAssertEqual(images.optimizeOptions?.allowLossy, false)
}

func testBackwardCompatibilityWithoutOptimize() throws {
    let yaml = """
    output: "Assets.xcassets"
    """

    let images = try YAMLDecoder().decode(Params.iOS.Images.self, from: yaml)

    XCTAssertNil(images.optimize)
    XCTAssertNil(images.optimizeOptions)
}
```

______________________________________________________________________

### Phase 4: Export Integration Tests

```swift
// Tests/ExFigTests/ExportImagesOptimizationTests.swift

func testIOSExportWithOptimizationEnabled() async throws {
    // Integration test - requires image_optim
    guard ImageOptimizer.isAvailable() else {
        throw XCTSkip("image_optim not installed")
    }

    // Setup test config with optimize: true
    // Run export
    // Verify images were optimized (file size reduced or metadata stripped)
}

func testExportSkipsOptimizationForWebP() async throws {
    // Verify optimization is not called when format is webp
}

func testExportWarnsWhenImageOptimNotInstalled() async throws {
    // Clear PATH, run export with optimize: true
    // Verify warning is logged but export succeeds
}
```

______________________________________________________________________

## Files to Modify

| File                                           | Changes                              |
| ---------------------------------------------- | ------------------------------------ |
| `Sources/ExFig/Output/ImageOptimizer.swift`    | New file - optimizer implementation  |
| `Sources/ExFig/Input/Params.swift`             | Add OptimizeOptions, optimize fields |
| `Sources/ExFig/Subcommands/ExportImages.swift` | Integrate optimization step          |
| `CLAUDE.md`                                    | Document IMAGE_OPTIM_PATH            |
| `CONFIG.md`                                    | Document optimize/optimizeOptions    |
| `Tests/ExFigTests/ImageOptimizerTests.swift`   | New file - unit tests                |
| `Tests/ExFigTests/ParamsOptimizeTests.swift`   | New file - config tests              |

## Test Helpers

```swift
/// Creates minimal valid PNG data for testing
func createMinimalPNG() -> Data {
    // 1x1 red pixel PNG
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
```

## Execution Order (TDD)

1. Write `ImageOptimizerTests.swift` → Run (fail) → Implement `ImageOptimizer` → Run (pass)
2. Write `ParamsOptimizeTests.swift` → Run (fail) → Add config fields → Run (pass)
3. Write `ExportImagesOptimizationTests.swift` → Run (fail) → Integrate → Run (pass)
4. Update documentation

## Risks / Trade-offs

| Risk                            | Mitigation                                            |
| ------------------------------- | ----------------------------------------------------- |
| Ruby dependency                 | Clear installation docs, warn don't error             |
| Slow optimization               | Parallel processing, progress indicator               |
| image_optim version differences | Test with specific version (0.31.4)                   |
| Large files timeout             | image_optim has internal timeouts, document in errors |

## References

- [image_optim GitHub](https://github.com/toy/image_optim)
- [image_optim_pack](https://github.com/toy/image_optim_pack) - precompiled binaries
- [WebpConverter](Sources/ExFig/Output/WebpConverter.swift) - existing pattern
