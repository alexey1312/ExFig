import ExFigCore
import Foundation

/// Progress callback type for conversion operations
typealias ConversionProgressCallback = @Sendable (Int, Int) async -> Void

/// PNG to WebP converter with parallel batch processing support
final class WebpConverter: Sendable {
    enum Encoding: Sendable {
        case lossy(quality: Int)
        case lossless
    }

    private let encoding: Encoding
    private let maxConcurrent: Int

    init(encoding: Encoding, maxConcurrent: Int = 4) {
        self.encoding = encoding
        self.maxConcurrent = maxConcurrent
    }

    /// Converts PNG files to WebP (single file, blocking)
    func convert(file url: URL) throws {
        try convertSync(file: url)
    }

    /// Converts multiple PNG files to WebP in parallel (async, ~4x speedup)
    /// - Parameters:
    ///   - files: PNG files to convert
    ///   - onProgress: Optional callback called with (current, total) after each conversion
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
        let outputURL = url.deletingPathExtension().appendingPathExtension("webp")

        var executableURLs = [
            URL(fileURLWithPath: "/usr/local/bin/cwebp"),
            URL(fileURLWithPath: "/opt/homebrew/bin/cwebp"),
        ]

        let task = Process()
        switch encoding {
        case .lossless:
            task.arguments = ["-lossless", url.path, "-o", outputURL.path, "-short"]
        case let .lossy(quality):
            task.arguments = ["-q", String(quality), url.path, "-o", outputURL.path, "-short"]
        }

        repeat {
            task.executableURL = executableURLs.removeFirst()
            do {
                try task.run()
                task.waitUntilExit()
                return
            } catch {
                continue
            }
        } while !executableURLs.isEmpty
    }
}
