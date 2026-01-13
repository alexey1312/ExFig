import ExFigCore
import Foundation
import Logging
import SVGKit

/// Exports SVG icons as Jetpack Compose ImageVector Kotlin files
public final class AndroidImageVectorExporter: Sendable {
    /// Configuration for ImageVector export
    public struct Config: Sendable {
        public let packageName: String
        public let extensionTarget: String?
        public let generatePreview: Bool
        public let colorMappings: [String: String]
        public let normalize: Bool
        public let maxConcurrent: Int
        public let validatePathData: Bool
        public let strictPathValidation: Bool

        /// - Parameters:
        ///   - packageName: Kotlin package name for generated files
        ///   - extensionTarget: Optional extension receiver for icon properties
        ///   - generatePreview: If true, generates @Preview annotation
        ///   - colorMappings: Hex color to Compose Color mappings
        ///   - normalize: If true, normalizes SVG via usvg before parsing.
        ///                Default is false to preserve mask/clip-path structure from Figma.
        ///   - maxConcurrent: Maximum concurrent conversions
        ///   - validatePathData: If true, validates pathData length and logs warnings
        ///   - strictPathValidation: If true, throws error when pathData exceeds 32,767 bytes
        public init(
            packageName: String,
            extensionTarget: String? = nil,
            generatePreview: Bool = true,
            colorMappings: [String: String] = [:],
            normalize: Bool = false,
            maxConcurrent: Int = 4,
            validatePathData: Bool = true,
            strictPathValidation: Bool = false
        ) {
            self.packageName = packageName
            self.extensionTarget = extensionTarget
            self.generatePreview = generatePreview
            self.colorMappings = colorMappings
            self.normalize = normalize
            self.maxConcurrent = maxConcurrent
            self.validatePathData = validatePathData
            self.strictPathValidation = strictPathValidation
        }
    }

    private let outputDirectory: URL
    private let config: Config
    private let validator = PathDataValidator()
    private let logger = Logger(label: "com.alexey1312.exfig.imagevector-exporter")

    public init(outputDirectory: URL, config: Config) {
        self.outputDirectory = outputDirectory
        self.config = config
    }

    /// Exports SVG data as ImageVector Kotlin files (async, parallel)
    /// - Parameters:
    ///   - svgFiles: Dictionary of icon name to SVG data
    /// - Returns: Array of FileContents to be written
    public func exportAsync(svgFiles: [String: Data]) async throws -> [FileContents] {
        guard !svgFiles.isEmpty else { return [] }

        return try await withThrowingTaskGroup(of: FileContents?.self) { [self] group in
            var iterator = svgFiles.makeIterator()
            var results: [FileContents] = []
            results.reserveCapacity(svgFiles.count)

            // Start initial batch
            for _ in 0 ..< min(config.maxConcurrent, svgFiles.count) {
                if let (name, svgData) = iterator.next() {
                    group.addTask { [name, svgData] in
                        try? self.exportSingle(name: name, svgData: svgData)
                    }
                }
            }

            // Collect results and start new tasks
            for try await result in group {
                if let file = result {
                    results.append(file)
                }
                if let (name, svgData) = iterator.next() {
                    group.addTask { [name, svgData] in
                        try? self.exportSingle(name: name, svgData: svgData)
                    }
                }
            }

            return results
        }
    }

    /// Exports SVG data as ImageVector Kotlin files (sync)
    /// - Parameters:
    ///   - svgFiles: Dictionary of icon name to SVG data
    /// - Returns: Array of FileContents to be written
    public func export(svgFiles: [String: Data]) throws -> [FileContents] {
        let svgParser = SVGParser()
        let generator = ImageVectorGenerator(config: .init(
            packageName: config.packageName,
            extensionTarget: config.extensionTarget,
            generatePreview: config.generatePreview,
            colorMappings: config.colorMappings
        ))

        var files: [FileContents] = []

        for (name, svgData) in svgFiles {
            let svg = try svgParser.parse(svgData, normalize: config.normalize)
            let kotlinCode = generator.generate(name: name, svg: svg)

            let fileName = name.toPascalCase() + ".kt"
            guard let fileURL = URL(string: fileName) else {
                continue
            }

            let fileContents = FileContents(
                destination: Destination(directory: outputDirectory, file: fileURL),
                data: Data(kotlinCode.utf8)
            )
            files.append(fileContents)
        }

        return files
    }

    /// Exports a single SVG file as ImageVector
    /// - Parameters:
    ///   - name: Icon name
    ///   - svgData: SVG file data
    /// - Returns: FileContents for the generated Kotlin file
    public func exportSingle(name: String, svgData: Data) throws -> FileContents {
        let svg = try SVGParser().parse(svgData, normalize: config.normalize)

        // Validate pathData if enabled
        if config.validatePathData {
            let issues = validator.validate(svg: svg, iconName: name)
            validator.logIssues(issues, iconName: name)

            // Check for critical issues if strict mode enabled
            if config.strictPathValidation, let critical = issues.first(where: { $0.isCritical }) {
                throw ImageVectorExportError.pathDataExceedsCriticalLimit(
                    iconName: name,
                    byteLength: critical.result.byteLength
                )
            }
        }

        let generator = ImageVectorGenerator(config: .init(
            packageName: config.packageName,
            extensionTarget: config.extensionTarget,
            generatePreview: config.generatePreview,
            colorMappings: config.colorMappings
        ))

        let kotlinCode = generator.generate(name: name, svg: svg)

        let fileName = name.toPascalCase() + ".kt"
        guard let fileURL = URL(string: fileName) else {
            throw ImageVectorExportError.invalidFileName(name)
        }

        return FileContents(
            destination: Destination(directory: outputDirectory, file: fileURL),
            data: Data(kotlinCode.utf8)
        )
    }
}

// MARK: - Errors

public enum ImageVectorExportError: Error, LocalizedError {
    case invalidFileName(String)
    case svgParsingFailed(String, Error)
    case pathDataExceedsCriticalLimit(iconName: String, byteLength: Int)

    public var errorDescription: String? {
        switch self {
        case let .invalidFileName(name):
            "Invalid file name: \(name)"
        case let .svgParsingFailed(name, error):
            "SVG parsing failed: \(name) - \(error.localizedDescription)"
        case let .pathDataExceedsCriticalLimit(iconName, byteLength):
            """
            pathData exceeds 32,767 bytes (\(byteLength) bytes) in \(iconName). \
            This will cause STRING_TOO_LARGE error during Android build.
            """
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidFileName:
            "Use alphanumeric characters, underscores, and hyphens only"
        case .svgParsingFailed:
            "Re-export SVG from Figma or check SVG syntax"
        case .pathDataExceedsCriticalLimit:
            "Simplify the path in Figma or use raster format (PNG/WebP)"
        }
    }
}

// MARK: - String Extensions

private extension String {
    func toPascalCase() -> String {
        let components = split { !$0.isLetter && !$0.isNumber }
        return components.map { component in
            component.prefix(1).uppercased() + component.dropFirst().lowercased()
        }.joined()
    }
}
