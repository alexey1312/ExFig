import ExFigCore
import Foundation

/// Progress callback type for conversion operations
typealias ConversionProgressCallback = @Sendable (Int, Int) async -> Void

/// Errors that can occur during WebP conversion
enum WebpConverterError: LocalizedError, Equatable {
    case cwebpNotFound(searchedPaths: [String])
    case conversionFailed(file: String, exitCode: Int32, stderr: String)
    case fileNotFound(path: String)

    var errorDescription: String? {
        switch self {
        case let .cwebpNotFound(searchedPaths):
            return """
            'cwebp' tool not found.

            WebP conversion requires the 'cwebp' command-line tool.

            Install using one of these methods:
              • macOS (Homebrew):  brew install webp
              • macOS (MacPorts):  port install webp
              • Linux (apt):       sudo apt install webp
              • Linux (dnf):       sudo dnf install libwebp-tools
              • Linux (pacman):    sudo pacman -S libwebp

            Or specify a custom path via environment variable:
              export CWEBP_PATH=/path/to/cwebp

            Searched locations:
            \(searchedPaths.map { "  ✗ \($0)" }.joined(separator: "\n"))
            """
        case let .conversionFailed(file, exitCode, stderr):
            let stderrInfo = stderr.isEmpty ? "" : "\nOutput: \(stderr)"
            return """
            WebP conversion failed for '\(file)'.

            Exit code: \(exitCode)\(stderrInfo)

            This may indicate:
              • Corrupted or invalid PNG file
              • Insufficient disk space
              • Incompatible cwebp version
            """
        case let .fileNotFound(path):
            return "Input file not found: \(path)"
        }
    }
}

/// PNG to WebP converter with parallel batch processing support
final class WebpConverter: Sendable {
    enum Encoding: Sendable {
        case lossy(quality: Int)
        case lossless
    }

    /// Standard paths where cwebp might be installed
    static let standardSearchPaths: [String] = {
        var paths = [String]()

        // 1. Environment variable (highest priority)
        if let customPath = ProcessInfo.processInfo.environment["CWEBP_PATH"] {
            paths.append(customPath)
        }

        // 2. Common installation paths
        #if os(macOS)
            paths += [
                "/opt/homebrew/bin/cwebp", // Homebrew on Apple Silicon
                "/usr/local/bin/cwebp", // Homebrew on Intel / manual install
                "/opt/local/bin/cwebp", // MacPorts
            ]
        #endif

        // 3. Linux paths
        #if os(Linux)
            paths += [
                "/usr/bin/cwebp", // apt/dnf/pacman
                "/usr/local/bin/cwebp", // manual install
                "/home/linuxbrew/.linuxbrew/bin/cwebp", // Linuxbrew
            ]
        #endif

        // 4. Cross-platform paths
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        paths += [
            "\(home)/.local/share/mise/shims/cwebp", // mise
            "\(home)/.local/bin/cwebp", // user local bin
        ]

        return paths
    }()

    private let encoding: Encoding
    private let maxConcurrent: Int
    private let executableURL: URL

    /// Creates a WebP converter
    /// - Parameters:
    ///   - encoding: WebP encoding type (lossy or lossless)
    ///   - maxConcurrent: Maximum number of parallel conversions (default: 4)
    /// - Throws: `WebpConverterError.cwebpNotFound` if cwebp is not installed
    init(encoding: Encoding, maxConcurrent: Int = 4) throws {
        self.encoding = encoding
        self.maxConcurrent = maxConcurrent
        executableURL = try Self.findCwebp()
    }

    /// Finds cwebp executable in standard paths
    /// - Returns: URL to cwebp executable
    /// - Throws: `WebpConverterError.cwebpNotFound` if not found
    static func findCwebp() throws -> URL {
        // First, try to find in PATH using `which`
        if let pathResult = try? findInPath("cwebp") {
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

        throw WebpConverterError.cwebpNotFound(searchedPaths: standardSearchPaths)
    }

    /// Checks if cwebp is available without throwing
    /// - Returns: true if cwebp is found
    static func isAvailable() -> Bool {
        (try? findCwebp()) != nil
    }

    /// Finds an executable in PATH using `which` command
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
        guard let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !path.isEmpty
        else {
            return nil
        }

        return URL(fileURLWithPath: path)
    }

    /// Converts a single PNG file to WebP (blocking)
    /// - Parameter url: Path to PNG file
    /// - Throws: `WebpConverterError` on failure
    func convert(file url: URL) throws {
        try convertSync(file: url)
    }

    /// Converts multiple PNG files to WebP in parallel (async, ~4x speedup)
    /// - Parameters:
    ///   - files: PNG files to convert
    ///   - onProgress: Optional callback called with (current, total) after each conversion
    /// - Throws: `WebpConverterError` on failure
    func convertBatch(
        files: [URL],
        onProgress: ConversionProgressCallback? = nil
    ) async throws {
        guard !files.isEmpty else { return }

        let totalCount = files.count

        try await withThrowingTaskGroup(of: Void.self) { [self] group in
            var iterator = files.makeIterator()
            var activeCount = 0
            var convertedCount = 0

            // Start initial batch
            for _ in 0 ..< min(maxConcurrent, files.count) {
                if let file = iterator.next() {
                    group.addTask { [file] in
                        try self.convertSync(file: file)
                    }
                    activeCount += 1
                }
            }

            // Process completed and start new ones
            for try await _ in group {
                activeCount -= 1
                convertedCount += 1

                // Report progress
                if let onProgress {
                    await onProgress(convertedCount, totalCount)
                }

                if let file = iterator.next() {
                    group.addTask { [file] in
                        try self.convertSync(file: file)
                    }
                    activeCount += 1
                }
            }
        }
    }

    /// Synchronous conversion (internal)
    private func convertSync(file url: URL) throws {
        // Verify input file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw WebpConverterError.fileNotFound(path: url.path)
        }

        let outputURL = url.deletingPathExtension().appendingPathExtension("webp")

        let task = Process()
        task.executableURL = executableURL

        switch encoding {
        case .lossless:
            task.arguments = ["-lossless", url.path, "-o", outputURL.path, "-short"]
        case let .lossy(quality):
            task.arguments = ["-q", String(quality), url.path, "-o", outputURL.path, "-short"]
        }

        // Capture stderr for error reporting
        let stderrPipe = Pipe()
        task.standardError = stderrPipe
        task.standardOutput = FileHandle.nullDevice

        try task.run()
        task.waitUntilExit()

        // Check exit code
        guard task.terminationStatus == 0 else {
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let stderr = String(data: stderrData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            throw WebpConverterError.conversionFailed(
                file: url.lastPathComponent,
                exitCode: task.terminationStatus,
                stderr: stderr
            )
        }
    }
}
