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
    /// Allowed module schemes (no http/https to prevent network imports).
    private static let allowedModules = [
        "pkl:", "repl:", "file:", "modulepath:", "package:", "projectpackage:",
    ]

    /// Allowed resource schemes (no http/https to prevent network reads).
    private static let allowedResources = [
        "file:", "env:", "prop:", "modulepath:", "package:", "projectpackage:",
    ]

    public static func evaluate(configPath: URL) async throws -> ExFig.ModuleImpl {
        guard FileManager.default.fileExists(atPath: configPath.path) else {
            throw PKLError.configNotFound(path: configPath.path)
        }

        var options = EvaluatorOptions.preconfigured
        options.allowedModules = allowedModules
        options.allowedResources = allowedResources

        return try await PklSwift.withEvaluator(options: options) { evaluator in
            try await evaluator.evaluateModule(
                source: .path(configPath.path),
                as: ExFig.ModuleImpl.self
            )
        }
    }
}
