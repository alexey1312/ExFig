// Code generated from Pkl module `Batch`. DO NOT EDIT.
import PklSwift

public enum Batch {}

extension Batch {
    /// Batch execution settings — only meaningful for `exfig batch`.
    public struct BatchConfig: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "Batch#BatchConfig"

        /// Maximum configs to process in parallel. CLI --parallel overrides.
        public var parallel: Int?

        /// Stop processing on first error. CLI --fail-fast overrides.
        public var failFast: Bool?

        /// Resume from previous checkpoint if available. CLI --resume overrides.
        public var resume: Bool?

        public init(parallel: Int?, failFast: Bool?, resume: Bool?) {
            self.parallel = parallel
            self.failFast = failFast
            self.resume = resume
        }
    }

    /// Batch orchestration configuration.
    ///
    /// These settings only apply when running `exfig batch` and are read
    /// from the FIRST config in the argument list. Per-target `batch:` blocks
    /// in subsequent configs are ignored (logged under -v).
    public struct Module: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "Batch"

        public init() {}
    }

    /// Load the Pkl module at the given source and evaluate it into `Batch.Module`.
    ///
    /// - Parameter source: The source of the Pkl module.
    public static func loadFrom(source: ModuleSource) async throws -> Batch.Module {
        try await PklSwift.withEvaluator { evaluator in
            try await loadFrom(evaluator: evaluator, source: source)
        }
    }

    /// Load the Pkl module at the given source and evaluate it with the given evaluator into
    /// `Batch.Module`.
    ///
    /// - Parameter evaluator: The evaluator to use for evaluation.
    /// - Parameter source: The module to evaluate.
    public static func loadFrom(
        evaluator: PklSwift.Evaluator,
        source: PklSwift.ModuleSource
    ) async throws -> Batch.Module {
        try await evaluator.evaluateModule(source: source, as: Module.self)
    }
}
