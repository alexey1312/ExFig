@_exported import ExFigConfig
import Foundation

/// Extension to PKLEvaluator for ExFig-specific Params decoding.
extension PKLEvaluator {
    /// Evaluates a PKL configuration file directly to a Params struct.
    /// - Parameter configPath: Path to the .pkl configuration file
    /// - Returns: Decoded Params struct
    /// - Throws: `PKLError.evaluationFailed` on syntax/type errors, or decoding errors
    func evaluateToParams(configPath: URL) async throws -> Params {
        try await evaluate(configPath: configPath, as: Params.self)
    }
}
