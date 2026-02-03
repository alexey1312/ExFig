import ArgumentParser
import Foundation

/// Command-line options for ExFig commands.
///
/// This type is used with swift-argument-parser's `@OptionGroup` property wrapper.
/// The `accessToken` and `params` properties are populated during `validate()`,
/// which is called automatically by swift-argument-parser before `run()`.
///
/// - Important: Do not access `accessToken` or `params` before validation completes.
struct ExFigOptions: ParsableArguments {
    /// Default config filename for new projects.
    static let defaultConfigFilename = "exfig.pkl"

    /// Config file names in order of priority for auto-detection.
    static let defaultConfigFiles = [defaultConfigFilename]

    @Option(
        name: .shortAndLong,
        help: "Path to PKL config file. Auto-detects exfig.pkl if not specified."
    )
    var input: String?

    // MARK: - Validated Properties

    /// Figma personal access token from FIGMA_PERSONAL_TOKEN environment variable.
    /// Populated during `validate()`.
    private(set) var accessToken: String!

    /// Parsed configuration from the PKL input file.
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
        throw ExFigError.custom(
            errorString: """
            Config file not found. Create exfig.pkl, or specify path with -i option.

            Example exfig.pkl:
              amends "package://github.com/niceplaces/exfig@2.0.0#/ExFig.pkl"

              ios {
                xcodeprojPath = "MyApp.xcodeproj"
                ...
              }
            """
        )
    }

    private func readParams(at path: String) throws -> Params {
        let url = URL(fileURLWithPath: path)
        let evaluator = try PKLEvaluator()

        // PKLEvaluator is an actor, need to run async
        // Using blocking call since we're in validate() which is synchronous
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<Params, Error>!

        Task {
            do {
                result = try await .success(evaluator.evaluateToParams(configPath: url))
            } catch {
                result = .failure(error)
            }
            semaphore.signal()
        }

        semaphore.wait()

        switch result! {
        case let .success(params):
            return params
        case let .failure(error):
            throw error
        }
    }
}
