import Foundation

/// Evaluates PKL configuration files to JSON.
///
/// Uses the PKL CLI via subprocess to evaluate `.pkl` files and output JSON
/// that can be decoded into Swift types.
///
/// Usage:
/// ```swift
/// let evaluator = try PKLEvaluator()
/// let json = try await evaluator.evaluate(configPath: configURL)
/// let params = try await evaluator.evaluateToParams(configPath: configURL)
/// ```
public actor PKLEvaluator {
    private let pklPath: URL

    /// Creates a new PKL evaluator.
    /// - Throws: `PKLError.notFound` if pkl CLI is not installed
    public init() throws {
        let locator = PKLLocator()
        pklPath = try locator.findPKL()
    }

    /// Creates a PKL evaluator with a specific pkl path.
    /// - Parameter pklPath: Path to the pkl executable
    public init(pklPath: URL) {
        self.pklPath = pklPath
    }

    /// Evaluates a PKL configuration file to JSON string.
    /// - Parameter configPath: Path to the .pkl configuration file
    /// - Returns: JSON string representation of the configuration
    /// - Throws: `PKLError.evaluationFailed` on syntax or type errors
    public func evaluate(configPath: URL) async throws -> String {
        guard FileManager.default.fileExists(atPath: configPath.path) else {
            throw PKLError.configNotFound(path: configPath.path)
        }

        let process = Process()
        process.executableURL = pklPath
        process.arguments = ["eval", "--format", "json", configPath.path]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorData = stderr.fileHandleForReading.readDataToEndOfFile()

        let exitCode = process.terminationStatus

        if exitCode != 0 {
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw PKLError.evaluationFailed(message: errorMessage, exitCode: exitCode)
        }

        guard let output = String(data: outputData, encoding: .utf8) else {
            throw PKLError.evaluationFailed(
                message: "Failed to decode PKL output as UTF-8",
                exitCode: exitCode
            )
        }

        return output
    }

    /// Evaluates a PKL configuration file and decodes to a Decodable type.
    /// - Parameters:
    ///   - configPath: Path to the .pkl configuration file
    ///   - type: The type to decode into
    /// - Returns: Decoded value
    /// - Throws: `PKLError.evaluationFailed` on syntax/type errors, or decoding errors
    public func evaluate<T: Decodable>(configPath: URL, as type: T.Type) async throws -> T {
        let json = try await evaluate(configPath: configPath)
        let data = Data(json.utf8)

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}
