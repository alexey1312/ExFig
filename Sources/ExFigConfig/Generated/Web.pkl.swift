// Code generated from Pkl module `Web`. DO NOT EDIT.
import PklSwift

public enum Web {}

public extension Web {
    /// Web platform configuration for ExFig.
    struct Module: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "Web"

        public init() {}
    }

    /// Web colors entry configuration.
    struct ColorsEntry: Common.VariablesSource {
        public static let registeredIdentifier: String = "Web#ColorsEntry"

        /// Output directory for generated color files.
        public var outputDirectory: String?

        /// CSS filename for CSS variables. Default: colors.css
        public var cssFileName: String?

        /// TypeScript filename for type definitions. Default: colors.ts
        public var tsFileName: String?

        /// JSON filename for color data. Default: colors.json
        public var jsonFileName: String?

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
            outputDirectory: String?,
            cssFileName: String?,
            tsFileName: String?,
            jsonFileName: String?,
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
            self.outputDirectory = outputDirectory
            self.cssFileName = cssFileName
            self.tsFileName = tsFileName
            self.jsonFileName = jsonFileName
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

    /// Web icons entry configuration.
    struct IconsEntry: Common.FrameSource {
        public static let registeredIdentifier: String = "Web#IconsEntry"

        /// Output directory for generated icon components.
        public var outputDirectory: String

        /// Directory for raw SVG files.
        public var svgDirectory: String?

        /// Generate React components for icons.
        public var generateReactComponents: Bool?

        /// Icon size in pixels for viewBox. Default: 24.
        public var iconSize: Int?

        /// Naming style for icon names.
        public var nameStyle: Common.NameStyle?

        /// Figma frame name to export from.
        public var figmaFrameName: String?

        /// Regex pattern for validating/capturing names.
        public var nameValidateRegexp: String?

        /// Replacement pattern using captured groups.
        public var nameReplaceRegexp: String?

        public init(
            outputDirectory: String,
            svgDirectory: String?,
            generateReactComponents: Bool?,
            iconSize: Int?,
            nameStyle: Common.NameStyle?,
            figmaFrameName: String?,
            nameValidateRegexp: String?,
            nameReplaceRegexp: String?
        ) {
            self.outputDirectory = outputDirectory
            self.svgDirectory = svgDirectory
            self.generateReactComponents = generateReactComponents
            self.iconSize = iconSize
            self.nameStyle = nameStyle
            self.figmaFrameName = figmaFrameName
            self.nameValidateRegexp = nameValidateRegexp
            self.nameReplaceRegexp = nameReplaceRegexp
        }
    }

    /// Web images entry configuration.
    struct ImagesEntry: Common.FrameSource {
        public static let registeredIdentifier: String = "Web#ImagesEntry"

        /// Output directory for generated image components.
        public var outputDirectory: String

        /// Directory for image asset files.
        public var assetsDirectory: String?

        /// Generate React components for images.
        public var generateReactComponents: Bool?

        /// Naming style for generated image names.
        public var nameStyle: Common.NameStyle?

        /// Figma frame name to export from.
        public var figmaFrameName: String?

        /// Regex pattern for validating/capturing names.
        public var nameValidateRegexp: String?

        /// Replacement pattern using captured groups.
        public var nameReplaceRegexp: String?

        public init(
            outputDirectory: String,
            assetsDirectory: String?,
            generateReactComponents: Bool?,
            nameStyle: Common.NameStyle?,
            figmaFrameName: String?,
            nameValidateRegexp: String?,
            nameReplaceRegexp: String?
        ) {
            self.outputDirectory = outputDirectory
            self.assetsDirectory = assetsDirectory
            self.generateReactComponents = generateReactComponents
            self.nameStyle = nameStyle
            self.figmaFrameName = figmaFrameName
            self.nameValidateRegexp = nameValidateRegexp
            self.nameReplaceRegexp = nameReplaceRegexp
        }
    }

    /// Root Web platform configuration.
    struct WebConfig: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "Web#WebConfig"

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

    /// Load the Pkl module at the given source and evaluate it into `Web.Module`.
    ///
    /// - Parameter source: The source of the Pkl module.
    static func loadFrom(source: ModuleSource) async throws -> Web.Module {
        try await PklSwift.withEvaluator { evaluator in
            try await loadFrom(evaluator: evaluator, source: source)
        }
    }

    /// Load the Pkl module at the given source and evaluate it with the given evaluator into
    /// `Web.Module`.
    ///
    /// - Parameter evaluator: The evaluator to use for evaluation.
    /// - Parameter source: The module to evaluate.
    static func loadFrom(
        evaluator: PklSwift.Evaluator,
        source: PklSwift.ModuleSource
    ) async throws -> Web.Module {
        try await evaluator.evaluateModule(source: source, as: Module.self)
    }
}
