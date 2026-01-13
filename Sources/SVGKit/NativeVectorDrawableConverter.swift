import Foundation
import Logging

/// Errors that can occur during SVG to Vector Drawable conversion
public enum VectorDrawableConverterError: Error, LocalizedError {
    case directoryNotFound(URL)
    case invalidSVG(URL, Error)
    case pathDataExceedsCriticalLimit(iconName: String, byteLength: Int)

    public var errorDescription: String? {
        switch self {
        case let .directoryNotFound(url):
            "Directory not found: \(url.path)"
        case let .invalidSVG(url, error):
            "Invalid SVG: \(url.lastPathComponent) - \(error.localizedDescription)"
        case let .pathDataExceedsCriticalLimit(iconName, byteLength):
            """
            pathData exceeds 32,767 bytes (\(byteLength) bytes) in \(iconName). \
            This will cause STRING_TOO_LARGE error during Android build.
            """
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .directoryNotFound:
            "Check the directory path exists"
        case .invalidSVG:
            "Re-export SVG from Figma or check SVG syntax"
        case .pathDataExceedsCriticalLimit:
            "Simplify the path in Figma or use raster format (PNG/WebP)"
        }
    }
}

/// Native SVG to Android Vector Drawable XML converter
/// Replaces the external vd-tool Java dependency with pure Swift implementation
public struct NativeVectorDrawableConverter: Sendable {
    private let autoMirrored: Bool
    private let normalize: Bool
    private let maxConcurrent: Int
    private let validatePathData: Bool
    private let strictPathValidation: Bool
    private let logger = Logger(label: "com.alexey1312.exfig.native-vector-drawable-converter")
    private let validator = PathDataValidator()

    /// - Parameters:
    ///   - autoMirrored: If true, generates autoMirrored attribute for RTL support
    ///   - normalize: If true, normalizes SVG via usvg before parsing.
    ///                Default is false to preserve mask/clip-path structure from Figma.
    ///   - maxConcurrent: Maximum concurrent conversions
    ///   - validatePathData: If true, validates pathData length and logs warnings for long paths.
    ///                       Default is true.
    ///   - strictPathValidation: If true, throws error when pathData exceeds 32,767 bytes (AAPT limit).
    ///                           Default is false (only logs warning).
    public init(
        autoMirrored: Bool = false,
        normalize: Bool = false,
        maxConcurrent: Int = 4,
        validatePathData: Bool = true,
        strictPathValidation: Bool = false
    ) {
        self.autoMirrored = autoMirrored
        self.normalize = normalize
        self.maxConcurrent = maxConcurrent
        self.validatePathData = validatePathData
        self.strictPathValidation = strictPathValidation
    }

    /// Finds all SVG files in a directory
    private func findSVGFiles(in directoryUrl: URL) throws -> [URL] {
        let fileManager = FileManager.default

        // Verify directory exists
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: directoryUrl.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            throw VectorDrawableConverterError.directoryNotFound(directoryUrl)
        }

        // Find all SVG files
        let enumerator = fileManager.enumerator(at: directoryUrl, includingPropertiesForKeys: nil)
        var svgFiles: [URL] = []

        while let file = enumerator?.nextObject() as? URL {
            if file.pathExtension.lowercased() == "svg" {
                svgFiles.append(file)
            }
        }

        return svgFiles
    }

    /// Converts all SVG files in a directory to Android Vector Drawable XML format (async, parallel)
    /// - Parameters:
    ///   - inputDirectoryUrl: URL to directory containing SVG files
    ///   - rtlFiles: Set of file names (without extension) that should have autoMirrored=true
    /// - Throws: `VectorDrawableConverterError.directoryNotFound` if directory doesn't exist
    public func convertAsync(inputDirectoryUrl: URL, rtlFiles: Set<String> = []) async throws {
        let svgFiles = try findSVGFiles(in: inputDirectoryUrl)

        guard !svgFiles.isEmpty else {
            logger.info("No SVG files found in \(inputDirectoryUrl.path)")
            return
        }

        logger.info("Converting \(svgFiles.count) SVG file(s) to Vector Drawable XML")

        let successCount = Lock(0)
        let failCount = Lock(0)
        let criticalErrors = Lock<[VectorDrawableConverterError]>([])

        // Helper to process a single file with error tracking
        let processFile: @Sendable (URL) -> Void = { [self] svgFile in
            do {
                try convertFileSync(svgFile, rtlFiles: rtlFiles)
                successCount.withLock { $0 += 1 }
            } catch let error as VectorDrawableConverterError {
                logger.warning("Failed to convert \(svgFile.lastPathComponent): \(error.localizedDescription)")
                failCount.withLock { $0 += 1 }
                if case .pathDataExceedsCriticalLimit = error {
                    criticalErrors.withLock { $0.append(error) }
                }
            } catch {
                logger.warning("Failed to convert \(svgFile.lastPathComponent): \(error.localizedDescription)")
                failCount.withLock { $0 += 1 }
            }
        }

        try await withThrowingTaskGroup(of: Void.self) { group in
            var iterator = svgFiles.makeIterator()

            // Start initial batch
            for _ in 0 ..< min(maxConcurrent, svgFiles.count) {
                if let svgFile = iterator.next() {
                    group.addTask { [svgFile] in processFile(svgFile) }
                }
            }

            // Process completed and start new ones
            for try await _ in group {
                if let svgFile = iterator.next() {
                    group.addTask { [svgFile] in processFile(svgFile) }
                }
            }
        }

        logger.info("Conversion complete: \(successCount.value) succeeded, \(failCount.value) failed")

        // If strict validation is enabled and there were critical errors, throw the first one
        if strictPathValidation, let firstCritical = criticalErrors.value.first {
            throw firstCritical
        }
    }

    /// Converts all SVG files in a directory to Android Vector Drawable XML format (sync)
    /// - Parameters:
    ///   - inputDirectoryUrl: URL to directory containing SVG files
    ///   - rtlFiles: Set of file names (without extension) that should have autoMirrored=true
    /// - Throws: `VectorDrawableConverterError.directoryNotFound` if directory doesn't exist
    public func convert(inputDirectoryUrl: URL, rtlFiles: Set<String> = []) throws {
        let svgFiles = try findSVGFiles(in: inputDirectoryUrl)

        guard !svgFiles.isEmpty else {
            logger.info("No SVG files found in \(inputDirectoryUrl.path)")
            return
        }

        logger.info("Converting \(svgFiles.count) SVG file(s) to Vector Drawable XML")

        var successCount = 0
        var failCount = 0
        var criticalErrors: [VectorDrawableConverterError] = []

        for svgFile in svgFiles {
            do {
                try convertFileSync(svgFile, rtlFiles: rtlFiles)
                successCount += 1
            } catch let error as VectorDrawableConverterError {
                logger.warning("Failed to convert \(svgFile.lastPathComponent): \(error.localizedDescription)")
                failCount += 1
                // Track critical errors for later
                if case .pathDataExceedsCriticalLimit = error {
                    criticalErrors.append(error)
                }
            } catch {
                logger.warning("Failed to convert \(svgFile.lastPathComponent): \(error.localizedDescription)")
                failCount += 1
            }
        }

        logger.info("Conversion complete: \(successCount) succeeded, \(failCount) failed")

        // If strict validation is enabled and there were critical errors, throw the first one
        if strictPathValidation, let firstCritical = criticalErrors.first {
            throw firstCritical
        }
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

        // Validate pathData if enabled
        if validatePathData {
            let issues = validator.validate(svg: parsedSVG, iconName: fileName)
            validator.logIssues(issues, iconName: fileName)

            // Check for critical issues if strict mode enabled
            if strictPathValidation, let critical = issues.first(where: { $0.isCritical }) {
                throw VectorDrawableConverterError.pathDataExceedsCriticalLimit(
                    iconName: fileName,
                    byteLength: critical.result.byteLength
                )
            }
        }

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
