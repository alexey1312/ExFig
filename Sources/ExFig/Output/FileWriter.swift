import ExFigCore
import Foundation
#if os(Linux)
    import FoundationXML
#endif

/// Progress callback type for write operations
typealias WriteProgressCallback = @Sendable (Int, Int) async -> Void

final class FileWriter: Sendable {
    private let maxConcurrentWrites: Int

    init(maxConcurrentWrites: Int = 8) {
        self.maxConcurrentWrites = maxConcurrentWrites
    }

    /// Writes files sequentially (original behavior)
    func write(files: [FileContents]) throws {
        try files.forEach { file in
            try writeFile(file)
        }
    }

    /// Writes files in parallel for ~2x speedup on large batches
    /// - Parameters:
    ///   - files: Files to write
    ///   - onProgress: Optional callback called with (current, total) after each write
    func writeParallel(
        files: [FileContents],
        onProgress: WriteProgressCallback? = nil
    ) async throws {
        guard !files.isEmpty else { return }

        let totalCount = files.count

        // 1. Collect unique directories and create them (sequential, fast)
        let directories = Set(files.map { URL(fileURLWithPath: $0.destination.directory.path) })
        for directory in directories {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }

        // 2. Write files in parallel
        try await withThrowingTaskGroup(of: Void.self) { [self] group in
            var iterator = files.makeIterator()
            var activeCount = 0
            var writtenCount = 0

            // Start initial batch
            for _ in 0 ..< min(maxConcurrentWrites, files.count) {
                if let file = iterator.next() {
                    group.addTask { [file] in
                        try self.writeFileData(file)
                    }
                    activeCount += 1
                }
            }

            // Process completed and start new ones
            for try await _ in group {
                activeCount -= 1
                writtenCount += 1

                // Report progress
                if let onProgress {
                    await onProgress(writtenCount, totalCount)
                }

                if let file = iterator.next() {
                    group.addTask { [file] in
                        try self.writeFileData(file)
                    }
                    activeCount += 1
                }
            }
        }
    }

    func write(xmlFile: XMLDocument, directory: URL) throws {
        let fileURL = URL(fileURLWithPath: directory.path)
        let options: XMLNode.Options = [.nodePrettyPrint, .nodeCompactEmptyElement]
        try xmlFile.xmlData(options: options).write(to: fileURL, options: .atomic)
    }

    // MARK: - Private

    private func writeFile(_ file: FileContents) throws {
        let directoryURL = URL(fileURLWithPath: file.destination.directory.path)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        try writeFileData(file)
    }

    private func writeFileData(_ file: FileContents) throws {
        let fileURL = URL(fileURLWithPath: file.destination.url.path)
        if let data = file.data {
            try data.write(to: fileURL, options: .atomic)
        } else if let localFileURL = file.dataFile {
            // Remove existing file if present (copyItem fails if destination exists)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            try FileManager.default.copyItem(at: localFileURL, to: fileURL)
        } else {
            fatalError("FileContents.data is nil. Use FileDownloader to download contents of the file.")
        }
    }
}
