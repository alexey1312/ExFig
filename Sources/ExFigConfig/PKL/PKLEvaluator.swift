import Foundation
import PklSwift

extension PklError: @retroactive LocalizedError {
    public var errorDescription: String? {
        message
    }
}

/// Evaluates PKL configuration files using pkl-swift's embedded evaluator.
///
/// Uses PklSwift's MessagePack-based evaluation instead of spawning a subprocess.
/// This eliminates the need for pkl CLI to be installed (PKLLocator is no longer used).
///
/// Usage:
/// ```swift
/// let config = try await PKLEvaluator.evaluate(configPath: configURL)
/// print(config.ios?.colors) // [iOS.ColorsEntry]?
/// ```
public enum PKLEvaluator {
    /// Evaluates a PKL configuration file and returns the typed ExFig module.
    /// - Parameter configPath: Path to the .pkl configuration file
    /// - Returns: Evaluated ExFig module with all platform configurations
    /// - Throws: `PKLError.configNotFound` if file doesn't exist,
    ///           or PklSwift evaluation errors on syntax/type issues
    public static func evaluate(configPath: URL) async throws -> ExFig.ModuleImpl {
        guard FileManager.default.fileExists(atPath: configPath.path) else {
            throw PKLError.configNotFound(path: configPath.path)
        }

        return try await PklSwift.withEvaluator { evaluator in
            try await evaluator.evaluateModule(
                source: .path(configPath.path),
                as: ExFig.ModuleImpl.self
            )
        }
    }
}
