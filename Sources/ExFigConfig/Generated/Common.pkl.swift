// Code generated from Pkl module `Common`. DO NOT EDIT.
import PklSwift

public enum Common {}

public protocol Common_VariablesSource: Common_NameProcessing {
    var tokensFileId: String? { get }

    var tokensCollectionName: String? { get }

    var lightModeName: String? { get }

    var darkModeName: String? { get }

    var lightHCModeName: String? { get }

    var darkHCModeName: String? { get }

    var primitivesModeName: String? { get }
}

public protocol Common_NameProcessing: PklRegisteredType, DynamicallyEquatable, Hashable, Sendable {
    var nameValidateRegexp: String? { get }

    var nameReplaceRegexp: String? { get }
}

public protocol Common_FrameSource: Common_NameProcessing {
    var figmaFrameName: String? { get }
}

public extension Common {
    /// Naming style for generated code identifiers.
    enum NameStyle: String, CaseIterable, CodingKeyRepresentable, Decodable, Hashable, Sendable {
        case camelCase
        case snake_case
        case pascalCase = "PascalCase"
        case flatCase
        case kebab_case = "kebab-case"
        case sCREAMING_SNAKE_CASE = "SCREAMING_SNAKE_CASE"
    }

    /// Vector format for icons.
    enum VectorFormat: String, CaseIterable, CodingKeyRepresentable, Decodable, Hashable, Sendable {
        case pdf
        case svg
    }

    /// Source format for fetching images from Figma API.
    /// - `png`: Download raster PNG from Figma (default, legacy behavior)
    /// - `svg`: Download SVG and rasterize locally with resvg (higher quality)
    enum SourceFormat: String, CaseIterable, CodingKeyRepresentable, Decodable, Hashable, Sendable {
        case png
        case svg
    }

    typealias VariablesSource = Common_VariablesSource

    /// Figma Variables source configuration.
    /// Used for colors that come from Figma Variables API.
    /// All fields are optional to support legacy format where source comes from common.variablesColors.
    struct VariablesSourceImpl: VariablesSource {
        public static let registeredIdentifier: String = "Common#VariablesSource"

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

    typealias NameProcessing = Common_NameProcessing

    /// Name validation and transformation configuration.
    struct NameProcessingImpl: NameProcessing {
        public static let registeredIdentifier: String = "Common#NameProcessing"

        /// Regex pattern for validating/capturing names.
        public var nameValidateRegexp: String?

        /// Replacement pattern using captured groups.
        public var nameReplaceRegexp: String?

        public init(nameValidateRegexp: String?, nameReplaceRegexp: String?) {
            self.nameValidateRegexp = nameValidateRegexp
            self.nameReplaceRegexp = nameReplaceRegexp
        }
    }

    /// Common types and configurations shared across all platforms.
    struct Module: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "Common"

        public init() {}
    }

    /// Cache configuration for tracking Figma file versions.
    struct Cache: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "Common#Cache"

        /// Enable version tracking cache. Default: false.
        public var enabled: Bool?

        /// Custom path to cache file. Default: .exfig-cache.json
        public var path: String?

        public init(enabled: Bool?, path: String?) {
            self.enabled = enabled
            self.path = path
        }
    }

    typealias FrameSource = Common_FrameSource

    /// Figma Frame source configuration.
    /// Used for icons and images that come from Figma frames.
    struct FrameSourceImpl: FrameSource {
        public static let registeredIdentifier: String = "Common#FrameSource"

        /// Figma frame name to export from.
        public var figmaFrameName: String?

        /// Regex pattern for validating/capturing names.
        public var nameValidateRegexp: String?

        /// Replacement pattern using captured groups.
        public var nameReplaceRegexp: String?

        public init(
            figmaFrameName: String?,
            nameValidateRegexp: String?,
            nameReplaceRegexp: String?
        ) {
            self.figmaFrameName = figmaFrameName
            self.nameValidateRegexp = nameValidateRegexp
            self.nameReplaceRegexp = nameReplaceRegexp
        }
    }

    /// Common colors settings shared across platforms.
    struct Colors: NameProcessing {
        public static let registeredIdentifier: String = "Common#Colors"

        /// Use single file for all color modes.
        public var useSingleFile: Bool?

        /// Suffix for dark mode colors.
        public var darkModeSuffix: String?

        /// Suffix for light high contrast colors.
        public var lightHCModeSuffix: String?

        /// Suffix for dark high contrast colors.
        public var darkHCModeSuffix: String?

        /// Regex pattern for validating/capturing names.
        public var nameValidateRegexp: String?

        /// Replacement pattern using captured groups.
        public var nameReplaceRegexp: String?

        public init(
            useSingleFile: Bool?,
            darkModeSuffix: String?,
            lightHCModeSuffix: String?,
            darkHCModeSuffix: String?,
            nameValidateRegexp: String?,
            nameReplaceRegexp: String?
        ) {
            self.useSingleFile = useSingleFile
            self.darkModeSuffix = darkModeSuffix
            self.lightHCModeSuffix = lightHCModeSuffix
            self.darkHCModeSuffix = darkHCModeSuffix
            self.nameValidateRegexp = nameValidateRegexp
            self.nameReplaceRegexp = nameReplaceRegexp
        }
    }

    /// Common icons settings shared across platforms.
    struct Icons: NameProcessing {
        public static let registeredIdentifier: String = "Common#Icons"

        /// Figma frame name containing icons.
        public var figmaFrameName: String?

        /// Use single file for all icon modes.
        public var useSingleFile: Bool?

        /// Suffix for dark mode icons.
        public var darkModeSuffix: String?

        /// If true, exit with error when pathData exceeds 32,767 bytes (AAPT limit).
        public var strictPathValidation: Bool?

        /// Regex pattern for validating/capturing names.
        public var nameValidateRegexp: String?

        /// Replacement pattern using captured groups.
        public var nameReplaceRegexp: String?

        public init(
            figmaFrameName: String?,
            useSingleFile: Bool?,
            darkModeSuffix: String?,
            strictPathValidation: Bool?,
            nameValidateRegexp: String?,
            nameReplaceRegexp: String?
        ) {
            self.figmaFrameName = figmaFrameName
            self.useSingleFile = useSingleFile
            self.darkModeSuffix = darkModeSuffix
            self.strictPathValidation = strictPathValidation
            self.nameValidateRegexp = nameValidateRegexp
            self.nameReplaceRegexp = nameReplaceRegexp
        }
    }

    /// Common images settings shared across platforms.
    struct Images: NameProcessing {
        public static let registeredIdentifier: String = "Common#Images"

        /// Figma frame name containing images.
        public var figmaFrameName: String?

        /// Use single file for all image modes.
        public var useSingleFile: Bool?

        /// Suffix for dark mode images.
        public var darkModeSuffix: String?

        /// Regex pattern for validating/capturing names.
        public var nameValidateRegexp: String?

        /// Replacement pattern using captured groups.
        public var nameReplaceRegexp: String?

        public init(
            figmaFrameName: String?,
            useSingleFile: Bool?,
            darkModeSuffix: String?,
            nameValidateRegexp: String?,
            nameReplaceRegexp: String?
        ) {
            self.figmaFrameName = figmaFrameName
            self.useSingleFile = useSingleFile
            self.darkModeSuffix = darkModeSuffix
            self.nameValidateRegexp = nameValidateRegexp
            self.nameReplaceRegexp = nameReplaceRegexp
        }
    }

    /// Common typography settings shared across platforms.
    struct Typography: NameProcessing {
        public static let registeredIdentifier: String = "Common#Typography"

        /// Regex pattern for validating/capturing names.
        public var nameValidateRegexp: String?

        /// Replacement pattern using captured groups.
        public var nameReplaceRegexp: String?

        public init(nameValidateRegexp: String?, nameReplaceRegexp: String?) {
            self.nameValidateRegexp = nameValidateRegexp
            self.nameReplaceRegexp = nameReplaceRegexp
        }
    }

    /// Common Figma Variables colors source (required fields version).
    /// Used when all platforms share the same color source via common.variablesColors.
    struct VariablesColors: NameProcessing {
        public static let registeredIdentifier: String = "Common#VariablesColors"

        /// Figma file ID containing the variables (required).
        public var tokensFileId: String

        /// Name of the variable collection (required).
        public var tokensCollectionName: String

        /// Mode name for light theme (required).
        public var lightModeName: String

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
            tokensFileId: String,
            tokensCollectionName: String,
            lightModeName: String,
            darkModeName: String?,
            lightHCModeName: String?,
            darkHCModeName: String?,
            primitivesModeName: String?,
            nameValidateRegexp: String?,
            nameReplaceRegexp: String?
        ) {
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

    /// Root common configuration.
    struct CommonConfig: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "Common#CommonConfig"

        /// Cache configuration.
        public var cache: Cache?

        /// Common colors settings.
        public var colors: Colors?

        /// Shared Figma Variables source for colors.
        /// Used when all platforms use the same color source.
        public var variablesColors: VariablesColors?

        /// Common icons settings.
        public var icons: Icons?

        /// Common images settings.
        public var images: Images?

        /// Common typography settings.
        public var typography: Typography?

        public init(
            cache: Cache?,
            colors: Colors?,
            variablesColors: VariablesColors?,
            icons: Icons?,
            images: Images?,
            typography: Typography?
        ) {
            self.cache = cache
            self.colors = colors
            self.variablesColors = variablesColors
            self.icons = icons
            self.images = images
            self.typography = typography
        }
    }

    /// Load the Pkl module at the given source and evaluate it into `Common.Module`.
    ///
    /// - Parameter source: The source of the Pkl module.
    static func loadFrom(source: ModuleSource) async throws -> Common.Module {
        try await PklSwift.withEvaluator { evaluator in
            try await loadFrom(evaluator: evaluator, source: source)
        }
    }

    /// Load the Pkl module at the given source and evaluate it with the given evaluator into
    /// `Common.Module`.
    ///
    /// - Parameter evaluator: The evaluator to use for evaluation.
    /// - Parameter source: The module to evaluate.
    static func loadFrom(
        evaluator: PklSwift.Evaluator,
        source: PklSwift.ModuleSource
    ) async throws -> Common.Module {
        try await evaluator.evaluateModule(source: source, as: Module.self)
    }
}
