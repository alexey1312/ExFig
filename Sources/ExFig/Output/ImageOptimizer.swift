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
    static var standardSearchPaths: [String] {
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
    }

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
