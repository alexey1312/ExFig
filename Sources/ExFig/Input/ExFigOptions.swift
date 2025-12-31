import ArgumentParser
import ExFigKit
import Foundation
import Yams

/// Command-line options for ExFig commands.
///
/// This type is used with swift-argument-parser's `@OptionGroup` property wrapper.
/// The `accessToken` and `params` properties are populated during `validate()`,
/// which is called automatically by swift-argument-parser before `run()`.
///
/// - Important: Do not access `accessToken` or `params` before validation completes.
struct ExFigOptions: ParsableArguments {
    /// Default config filename for new projects.
    static let defaultConfigFilename = "exfig.yaml"

    /// Config file names in order of priority for auto-detection.
    /// exfig.yaml is preferred; figma-export.yaml is fallback for users migrating from figma-export.
    static let defaultConfigFiles = [defaultConfigFilename, "figma-export.yaml"]

    @Option(
        name: .shortAndLong,
        help: "Path to YAML config file. Auto-detects exfig.yaml or figma-export.yaml if not specified."
    )
    var input: String?

    // MARK: - Validated Properties

    /// Figma personal access token from FIGMA_PERSONAL_TOKEN environment variable.
    /// Populated during `validate()`.
    private(set) var accessToken: String!

    /// Parsed configuration from the YAML input file.
    /// Populated during `validate()`.
    private(set) var params: Params!

    // MARK: - Validation

    mutating func validate() throws {
        guard let token = ProcessInfo.processInfo.environment["FIGMA_PERSONAL_TOKEN"] else {
            throw ExFigError.accessTokenNotFound
        }
        accessToken = token

        let configPath = try resolveConfigPath()
        params = try readParams(at: configPath)
    }

    // MARK: - Private Helpers

    private func resolveConfigPath() throws -> String {
        // If user specified a path, use it directly
        if let userPath = input {
            return userPath
        }

        // Auto-detect config file from default names
        let fileManager = FileManager.default
        for filename in Self.defaultConfigFiles where fileManager.fileExists(atPath: filename) {
            return filename
        }

        // No config file found - throw error with helpful message
        let filenames = Self.defaultConfigFiles.joined(separator: " or ")
        throw ExFigError.custom(
            errorString: "Config file not found. Create \(filenames), or specify path with -i option."
        )
    }

    private func readParams(at path: String) throws -> Params {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        guard let string = String(bytes: data, encoding: .utf8) else {
            throw ExFigError.custom(errorString: "Unable to read file at \(path)")
        }
        let decoder = YAMLDecoder()
        return try decoder.decode(Params.self, from: string)
    }
}
