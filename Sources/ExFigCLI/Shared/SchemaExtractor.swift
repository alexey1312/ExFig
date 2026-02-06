import Foundation

/// Extracts bundled PKL schemas to a local directory.
///
/// Used by `exfig init` and `exfig schemas` to provide local schema files
/// that enable `pkl eval` without a published PKL package.
enum SchemaExtractor {
    static let schemaFiles = [
        "ExFig.pkl", "Figma.pkl", "Common.pkl",
        "iOS.pkl", "Android.pkl", "Flutter.pkl", "Web.pkl",
        "PklProject",
    ]

    static let defaultOutputDir = ".exfig/schemas"

    /// Extracts all PKL schema files from the app bundle to the specified directory.
    ///
    /// - Parameters:
    ///   - directory: Target directory path (relative or absolute). Defaults to `.exfig/schemas`.
    ///   - force: If `true`, overwrites existing files. If `false`, skips files that already exist.
    /// - Returns: List of extracted file names.
    @discardableResult
    static func extract(to directory: String = defaultOutputDir, force: Bool = false) throws -> [String] {
        let fileManager = FileManager.default

        // Resolve relative paths against current working directory
        let outputURL = if directory.hasPrefix("/") {
            URL(fileURLWithPath: directory)
        } else {
            URL(fileURLWithPath: fileManager.currentDirectoryPath)
                .appendingPathComponent(directory)
        }

        // Create output directory if needed
        try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true)

        // Find bundled schemas
        guard let schemasURL = Bundle.module.url(forResource: "Schemas", withExtension: nil) else {
            throw ExFigError.custom(errorString: "PKL schemas not found in application bundle")
        }

        var extracted: [String] = []

        for fileName in schemaFiles {
            let sourceURL = schemasURL.appendingPathComponent(fileName)
            let destURL = outputURL.appendingPathComponent(fileName)

            guard fileManager.fileExists(atPath: sourceURL.path) else {
                throw ExFigError.custom(errorString: "Schema file missing from bundle: \(fileName)")
            }

            if fileManager.fileExists(atPath: destURL.path) {
                if force {
                    try fileManager.removeItem(at: destURL)
                } else {
                    continue
                }
            }

            try fileManager.copyItem(at: sourceURL, to: destURL)
            extracted.append(fileName)
        }

        return extracted
    }
}
