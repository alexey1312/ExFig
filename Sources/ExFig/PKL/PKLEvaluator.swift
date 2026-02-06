@_exported import ExFigConfig
import Foundation

/// Extension to PKLEvaluator for ExFig-specific config decoding.
extension PKLEvaluator {
    /// Evaluates a PKL configuration file directly to a PKLConfig struct.
    /// - Parameter configPath: Path to the .pkl configuration file
    /// - Returns: Decoded PKLConfig struct
    /// - Throws: `PKLError.evaluationFailed` on syntax/type errors, or decoding errors
    func evaluateToPKLConfig(configPath: URL) async throws -> PKLConfig {
        try await evaluate(configPath: configPath, as: PKLConfig.self)
    }
}
