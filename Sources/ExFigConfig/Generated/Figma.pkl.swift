// Code generated from Pkl module `Figma`. DO NOT EDIT.
import PklSwift

public enum Figma {}

public extension Figma {
    /// Figma file configuration for legacy Styles API.
    /// Required for icons, images, typography, or legacy Styles API colors.
    /// Optional when using only Variables API for colors.
    struct FigmaConfig: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "Figma#FigmaConfig"

        /// Figma file ID for light mode colors, icons, images, and typography.
        public var lightFileId: String?

        /// Figma file ID for dark mode.
        public var darkFileId: String?

        /// Figma file ID for light high contrast mode.
        public var lightHighContrastFileId: String?

        /// Figma file ID for dark high contrast mode.
        public var darkHighContrastFileId: String?

        /// Request timeout in seconds.
        public var timeout: Float64?

        public init(
            lightFileId: String?,
            darkFileId: String?,
            lightHighContrastFileId: String?,
            darkHighContrastFileId: String?,
            timeout: Float64?
        ) {
            self.lightFileId = lightFileId
            self.darkFileId = darkFileId
            self.lightHighContrastFileId = lightHighContrastFileId
            self.darkHighContrastFileId = darkHighContrastFileId
            self.timeout = timeout
        }
    }

    /// Figma API configuration.
    struct Module: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "Figma"

        public init() {}
    }

    /// Load the Pkl module at the given source and evaluate it into `Figma.Module`.
    ///
    /// - Parameter source: The source of the Pkl module.
    static func loadFrom(source: ModuleSource) async throws -> Figma.Module {
        try await PklSwift.withEvaluator { evaluator in
            try await loadFrom(evaluator: evaluator, source: source)
        }
    }

    /// Load the Pkl module at the given source and evaluate it with the given evaluator into
    /// `Figma.Module`.
    ///
    /// - Parameter evaluator: The evaluator to use for evaluation.
    /// - Parameter source: The module to evaluate.
    static func loadFrom(
        evaluator: PklSwift.Evaluator,
        source: PklSwift.ModuleSource
    ) async throws -> Figma.Module {
        try await evaluator.evaluateModule(source: source, as: Module.self)
    }
}
