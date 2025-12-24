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
            try fixCaseMismatchIfNeeded(for: directory)
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
        try fixCaseMismatchIfNeeded(for: directoryURL)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        try writeFileData(file)
    }

    /// Fixes directory name case mismatch on case-insensitive file systems (macOS).
    ///
    /// On case-insensitive FS, `speech2text.imageset` and `speech2Text.imageset` are the same directory.
    /// When asset name casing changes, the old directory name persists. This method renames it.
    private func fixCaseMismatchIfNeeded(for targetURL: URL) throws {
        let fileManager = FileManager.default
        let parent = targetURL.deletingLastPathComponent()
        let targetName = targetURL.lastPathComponent

        // Parent must exist for enumeration
        guard fileManager.fileExists(atPath: parent.path) else { return }

        // Find existing directory with different case
        guard let contents = try? fileManager.contentsOfDirectory(
            at: parent,
            includingPropertiesForKeys: [.isDirectoryKey]
        ) else { return }

        for item in contents {
            let itemName = item.lastPathComponent
            // Case-insensitive match but different actual case
            if itemName.lowercased() == targetName.lowercased(), itemName != targetName {
                // Rename via temp directory (direct rename fails on case-insensitive FS)
                let tempURL = parent.appendingPathComponent(UUID().uuidString)
                try fileManager.moveItem(at: item, to: tempURL)
                try fileManager.moveItem(at: tempURL, to: targetURL)
                return
            }
        }
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
