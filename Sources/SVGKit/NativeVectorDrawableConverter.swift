import Foundation
import Logging

/// Errors that can occur during SVG to Vector Drawable conversion
public enum VectorDrawableConverterError: Error, LocalizedError {
    case directoryNotFound(URL)
    case invalidSVG(URL, Error)

    public var errorDescription: String? {
        switch self {
        case let .directoryNotFound(url):
            "Directory not found: \(url.path)"
        case let .invalidSVG(url, error):
            "Invalid SVG: \(url.lastPathComponent) - \(error.localizedDescription)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .directoryNotFound:
            "Check the directory path exists"
        case .invalidSVG:
            "Re-export SVG from Figma or check SVG syntax"
        }
    }
}

/// Native SVG to Android Vector Drawable XML converter
/// Replaces the external vd-tool Java dependency with pure Swift implementation
public struct NativeVectorDrawableConverter: Sendable {
    private let autoMirrored: Bool
    private let normalize: Bool
    private let maxConcurrent: Int
    private let logger = Logger(label: "com.alexey1312.exfig.native-vector-drawable-converter")

    public init(autoMirrored: Bool = false, normalize: Bool = true, maxConcurrent: Int = 4) {
        self.autoMirrored = autoMirrored
        self.normalize = normalize
        self.maxConcurrent = maxConcurrent
    }

    /// Converts all SVG files in a directory to Android Vector Drawable XML format (async, parallel)
    /// - Parameters:
    ///   - inputDirectoryUrl: URL to directory containing SVG files
    ///   - rtlFiles: Set of file names (without extension) that should have autoMirrored=true
    /// - Throws: `VectorDrawableConverterError.directoryNotFound` if directory doesn't exist
    public func convertAsync(inputDirectoryUrl: URL, rtlFiles: Set<String> = []) async throws {
        let fileManager = FileManager.default

        // Verify directory exists
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: inputDirectoryUrl.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            throw VectorDrawableConverterError.directoryNotFound(inputDirectoryUrl)
        }

        // Find all SVG files
        let enumerator = fileManager.enumerator(at: inputDirectoryUrl, includingPropertiesForKeys: nil)
        var svgFiles: [URL] = []

        while let file = enumerator?.nextObject() as? URL {
            if file.pathExtension.lowercased() == "svg" {
                svgFiles.append(file)
            }
        }

        guard !svgFiles.isEmpty else {
            logger.info("No SVG files found in \(inputDirectoryUrl.path)")
            return
        }

        logger.info("Converting \(svgFiles.count) SVG file(s) to Vector Drawable XML")

        let successCount = Lock(0)
        let failCount = Lock(0)

        try await withThrowingTaskGroup(of: Void.self) { [self] group in
            var iterator = svgFiles.makeIterator()

            // Start initial batch
            for _ in 0 ..< min(maxConcurrent, svgFiles.count) {
                if let svgFile = iterator.next() {
                    group.addTask { [svgFile] in
                        do {
                            try convertFileSync(svgFile, rtlFiles: rtlFiles)
                            successCount.withLock { $0 += 1 }
                        } catch {
                            logger.warning(
                                "Failed to convert \(svgFile.lastPathComponent): \(error.localizedDescription)"
                            )
                            failCount.withLock { $0 += 1 }
                        }
                    }
                }
            }

            // Process completed and start new ones
            for try await _ in group {
                if let svgFile = iterator.next() {
                    group.addTask { [svgFile] in
                        do {
                            try convertFileSync(svgFile, rtlFiles: rtlFiles)
                            successCount.withLock { $0 += 1 }
                        } catch {
                            logger.warning(
                                "Failed to convert \(svgFile.lastPathComponent): \(error.localizedDescription)"
                            )
                            failCount.withLock { $0 += 1 }
                        }
                    }
                }
            }
        }

        logger.info("Conversion complete: \(successCount.value) succeeded, \(failCount.value) failed")
    }

    /// Converts all SVG files in a directory to Android Vector Drawable XML format (sync)
    /// - Parameters:
    ///   - inputDirectoryUrl: URL to directory containing SVG files
    ///   - rtlFiles: Set of file names (without extension) that should have autoMirrored=true
    /// - Throws: `VectorDrawableConverterError.directoryNotFound` if directory doesn't exist
    public func convert(inputDirectoryUrl: URL, rtlFiles: Set<String> = []) throws {
        let fileManager = FileManager.default

        // Verify directory exists
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: inputDirectoryUrl.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            throw VectorDrawableConverterError.directoryNotFound(inputDirectoryUrl)
        }

        // Find all SVG files
        let enumerator = fileManager.enumerator(at: inputDirectoryUrl, includingPropertiesForKeys: nil)
        var svgFiles: [URL] = []

        while let file = enumerator?.nextObject() as? URL {
            if file.pathExtension.lowercased() == "svg" {
                svgFiles.append(file)
            }
        }

        guard !svgFiles.isEmpty else {
            logger.info("No SVG files found in \(inputDirectoryUrl.path)")
            return
        }

        logger.info("Converting \(svgFiles.count) SVG file(s) to Vector Drawable XML")

        var successCount = 0
        var failCount = 0

        for svgFile in svgFiles {
            do {
                try convertFileSync(svgFile, rtlFiles: rtlFiles)
                successCount += 1
            } catch {
                logger.warning("Failed to convert \(svgFile.lastPathComponent): \(error.localizedDescription)")
                failCount += 1
            }
        }

        logger.info("Conversion complete: \(successCount) succeeded, \(failCount) failed")
    }

    private func convertFileSync(_ svgFile: URL, rtlFiles: Set<String>) throws {
        let fileManager = FileManager.default
        let parser = SVGParser()

        // Check if this file should be auto-mirrored
        let fileName = svgFile.deletingPathExtension().lastPathComponent
        let shouldAutoMirror = autoMirrored || rtlFiles.contains(fileName)
        let generator = VectorDrawableXMLGenerator(autoMirrored: shouldAutoMirror)

        // Read SVG data
        let svgData = try Data(contentsOf: svgFile)

        // Parse SVG
        let parsedSVG = try parser.parse(svgData, normalize: normalize)

        // Generate Vector Drawable XML
        let xmlContent = generator.generate(from: parsedSVG)

        // Write XML file (same name, .xml extension)
        let xmlFile = svgFile.deletingPathExtension().appendingPathExtension("xml")
        try xmlContent.write(to: xmlFile, atomically: true, encoding: .utf8)

        // Remove original SVG file
        try fileManager.removeItem(at: svgFile)
    }
}

// MARK: - Thread-safe counter

private final class Lock<Value: Sendable>: @unchecked Sendable {
    private var _value: Value
    private let lock = NSLock()

    init(_ value: Value) {
        _value = value
    }

    var value: Value {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    func withLock<T>(_ body: (inout Value) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body(&_value)
    }
}
