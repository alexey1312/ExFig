// Code generated from Pkl module `Flutter`. DO NOT EDIT.
import PklSwift

public enum Flutter {}

public extension Flutter {
    /// Flutter image format.
    enum ImageFormat: String, CaseIterable, CodingKeyRepresentable, Decodable, Hashable, Sendable {
        case svg
        case png
        case webp
    }

    /// Root Flutter platform configuration.
    struct FlutterConfig: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "Flutter#FlutterConfig"

        /// Base output directory for all generated files.
        public var output: String

        /// Path to custom Stencil templates.
        public var templatesPath: String?

        /// Colors configuration entries.
        public var colors: [ColorsEntry]?

        /// Icons configuration entries.
        public var icons: [IconsEntry]?

        /// Images configuration entries.
        public var images: [ImagesEntry]?

        public init(
            output: String,
            templatesPath: String?,
            colors: [ColorsEntry]?,
            icons: [IconsEntry]?,
            images: [ImagesEntry]?
        ) {
            self.output = output
            self.templatesPath = templatesPath
            self.colors = colors
            self.icons = icons
            self.images = images
        }
    }

    /// Flutter colors entry configuration.
    struct ColorsEntry: Common.VariablesSource {
        public static let registeredIdentifier: String = "Flutter#ColorsEntry"

        /// Override path to custom Stencil templates for this entry.
        /// When set, overrides `FlutterConfig.templatesPath`.
        public var templatesPath: String?

        /// Output path for generated Dart colors file.
        public var output: String?

        /// Class name for generated colors.
        public var className: String?

        /// Figma file ID containing the variables.
        public var tokensFileId: String?

        /// Name of the variable collection.
        public var tokensCollectionName: String?

        /// Mode name for light theme.
        public var lightModeName: String?

        /// Mode name for dark theme.
        public var darkModeName: String?

        /// Mode name for light high contrast theme.
        public var lightHCModeName: String?

        /// Mode name for dark high contrast theme.
        public var darkHCModeName: String?

        /// Mode name for primitives/aliases layer.
        public var primitivesModeName: String?

        /// Regex pattern for validating/capturing names.
        public var nameValidateRegexp: String?

        /// Replacement pattern using captured groups.
        public var nameReplaceRegexp: String?

        public init(
            templatesPath: String?,
            output: String?,
            className: String?,
            tokensFileId: String?,
            tokensCollectionName: String?,
            lightModeName: String?,
            darkModeName: String?,
            lightHCModeName: String?,
            darkHCModeName: String?,
            primitivesModeName: String?,
            nameValidateRegexp: String?,
            nameReplaceRegexp: String?
        ) {
            self.templatesPath = templatesPath
            self.output = output
            self.className = className
            self.tokensFileId = tokensFileId
            self.tokensCollectionName = tokensCollectionName
            self.lightModeName = lightModeName
            self.darkModeName = darkModeName
            self.lightHCModeName = lightHCModeName
            self.darkHCModeName = darkHCModeName
            self.primitivesModeName = primitivesModeName
            self.nameValidateRegexp = nameValidateRegexp
            self.nameReplaceRegexp = nameReplaceRegexp
        }
    }

    /// Flutter platform configuration for ExFig.
    struct Module: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "Flutter"

        public init() {}
    }

    /// Flutter icons entry configuration.
    struct IconsEntry: Common.FrameSource {
        public static let registeredIdentifier: String = "Flutter#IconsEntry"

        /// Override path to custom Stencil templates for this entry.
        /// When set, overrides `FlutterConfig.templatesPath`.
        public var templatesPath: String?

        /// Output directory for icon SVG files.
        public var output: String

        /// Dart file path for icon class generation.
        public var dartFile: String?

        /// Class name for generated icons.
        public var className: String?

        /// Naming style for icon names.
        public var nameStyle: Common.NameStyle?

        /// Figma frame name to export from.
        public var figmaFrameName: String?

        /// Override Figma file ID for this specific entry.
        /// When set, overrides the global `figma.lightFileId` for loading data.
        public var figmaFileId: String?

        /// Regex pattern for validating/capturing names.
        public var nameValidateRegexp: String?

        /// Replacement pattern using captured groups.
        public var nameReplaceRegexp: String?

        public init(
            templatesPath: String?,
            output: String,
            dartFile: String?,
            className: String?,
            nameStyle: Common.NameStyle?,
            figmaFrameName: String?,
            figmaFileId: String?,
            nameValidateRegexp: String?,
            nameReplaceRegexp: String?
        ) {
            self.templatesPath = templatesPath
            self.output = output
            self.dartFile = dartFile
            self.className = className
            self.nameStyle = nameStyle
            self.figmaFrameName = figmaFrameName
            self.figmaFileId = figmaFileId
            self.nameValidateRegexp = nameValidateRegexp
            self.nameReplaceRegexp = nameReplaceRegexp
        }
    }

    /// Flutter images entry configuration.
    struct ImagesEntry: Common.FrameSource {
        public static let registeredIdentifier: String = "Flutter#ImagesEntry"

        /// Override path to custom Stencil templates for this entry.
        /// When set, overrides `FlutterConfig.templatesPath`.
        public var templatesPath: String?

        /// Output directory for image files.
        public var output: String

        /// Dart file path for image class generation.
        public var dartFile: String?

        /// Class name for generated images.
        public var className: String?

        /// Scale factors to generate (e.g., [1, 2, 3]).
        public var scales: [Float64]?

        /// Output format for images.
        public var format: ImageFormat?

        /// WebP encoding options.
        public var webpOptions: Android.WebpOptions?

        /// Source format for fetching from Figma API.
        public var sourceFormat: Common.SourceFormat?

        /// Naming style for generated assets.
        public var nameStyle: Common.NameStyle?

        /// Figma frame name to export from.
        public var figmaFrameName: String?

        /// Override Figma file ID for this specific entry.
        /// When set, overrides the global `figma.lightFileId` for loading data.
        public var figmaFileId: String?

        /// Regex pattern for validating/capturing names.
        public var nameValidateRegexp: String?

        /// Replacement pattern using captured groups.
        public var nameReplaceRegexp: String?

        public init(
            templatesPath: String?,
            output: String,
            dartFile: String?,
            className: String?,
            scales: [Float64]?,
            format: ImageFormat?,
            webpOptions: Android.WebpOptions?,
            sourceFormat: Common.SourceFormat?,
            nameStyle: Common.NameStyle?,
            figmaFrameName: String?,
            figmaFileId: String?,
            nameValidateRegexp: String?,
            nameReplaceRegexp: String?
        ) {
            self.templatesPath = templatesPath
            self.output = output
            self.dartFile = dartFile
            self.className = className
            self.scales = scales
            self.format = format
            self.webpOptions = webpOptions
            self.sourceFormat = sourceFormat
            self.nameStyle = nameStyle
            self.figmaFrameName = figmaFrameName
            self.figmaFileId = figmaFileId
            self.nameValidateRegexp = nameValidateRegexp
            self.nameReplaceRegexp = nameReplaceRegexp
        }
    }

    /// Load the Pkl module at the given source and evaluate it into `Flutter.Module`.
    ///
    /// - Parameter source: The source of the Pkl module.
    static func loadFrom(source: ModuleSource) async throws -> Flutter.Module {
        try await PklSwift.withEvaluator { evaluator in
            try await loadFrom(evaluator: evaluator, source: source)
        }
    }

    /// Load the Pkl module at the given source and evaluate it with the given evaluator into
    /// `Flutter.Module`.
    ///
    /// - Parameter evaluator: The evaluator to use for evaluation.
    /// - Parameter source: The module to evaluate.
    static func loadFrom(
        evaluator: PklSwift.Evaluator,
        source: PklSwift.ModuleSource
    ) async throws -> Flutter.Module {
        try await evaluator.evaluateModule(source: source, as: Module.self)
    }
}
