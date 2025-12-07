import ExFigCore
import Foundation
import SVGKit

/// Exports SVG icons as Jetpack Compose ImageVector Kotlin files
public final class AndroidImageVectorExporter: Sendable {
    /// Configuration for ImageVector export
    public struct Config: Sendable {
        public let packageName: String
        public let extensionTarget: String?
        public let generatePreview: Bool
        public let colorMappings: [String: String]

        public init(
            packageName: String,
            extensionTarget: String? = nil,
            generatePreview: Bool = true,
            colorMappings: [String: String] = [:]
        ) {
            self.packageName = packageName
            self.extensionTarget = extensionTarget
            self.generatePreview = generatePreview
            self.colorMappings = colorMappings
        }
    }

    private let outputDirectory: URL
    private let config: Config

    public init(outputDirectory: URL, config: Config) {
        self.outputDirectory = outputDirectory
        self.config = config
    }

    /// Exports SVG data as ImageVector Kotlin files
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
            let svg = try svgParser.parse(svgData)
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
        let svg = try SVGParser().parse(svgData)

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

    public var errorDescription: String? {
        switch self {
        case let .invalidFileName(name):
            "Invalid file name: \(name)"
        case let .svgParsingFailed(name, error):
            "SVG parsing failed: \(name) - \(error.localizedDescription)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidFileName:
            "Use alphanumeric characters, underscores, and hyphens only"
        case .svgParsingFailed:
            "Re-export SVG from Figma or check SVG syntax"
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
