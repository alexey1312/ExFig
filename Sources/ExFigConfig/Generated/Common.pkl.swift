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

    var figmaFileId: String? { get }

    var rtlProperty: String? { get }
}

extension Common {
    /// WebP encoding mode.
    public enum WebpEncoding: String, CaseIterable, CodingKeyRepresentable, Decodable, Hashable, Sendable {
        case lossy = "lossy"
        case lossless = "lossless"
    }

    /// Naming style for generated code identifiers.
    public enum NameStyle: String, CaseIterable, CodingKeyRepresentable, Decodable, Hashable, Sendable {
        case camelCase = "camelCase"
        case snake_case = "snake_case"
        case pascalCase = "PascalCase"
        case flatCase = "flatCase"
        case kebabCase = "kebab-case"
        case sCREAMING_SNAKE_CASE = "SCREAMING_SNAKE_CASE"
    }

    /// Vector format for icons.
    public enum VectorFormat: String, CaseIterable, CodingKeyRepresentable, Decodable, Hashable, Sendable {
        case pdf = "pdf"
        case svg = "svg"
    }

    /// Source format for fetching images from Figma API.
    /// - `png`: Download raster PNG from Figma (default, legacy behavior)
    /// - `svg`: Download SVG and rasterize locally with resvg (higher quality)
    public enum SourceFormat: String, CaseIterable, CodingKeyRepresentable, Decodable, Hashable, Sendable {
        case png = "png"
        case svg = "svg"
    }

    public typealias VariablesSource = Common_VariablesSource

    /// Figma Variables source configuration.
    /// Used for colors that come from Figma Variables API.
    /// All fields are optional to support legacy format where source comes from common.variablesColors.
    public struct VariablesSourceImpl: VariablesSource {
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

    public typealias NameProcessing = Common_NameProcessing

    /// Name validation and transformation configuration.
    public struct NameProcessingImpl: NameProcessing {
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
    public struct Module: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "Common"

        public init() {}
    }

    /// WebP encoding options.
    public struct WebpOptions: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "Common#WebpOptions"

        /// Encoding mode.
        public var encoding: WebpEncoding

        /// Quality for lossy encoding (0-100).
        public var quality: Int?

        public init(encoding: WebpEncoding, quality: Int?) {
            self.encoding = encoding
            self.quality = quality
        }
    }

    /// Cache configuration for tracking Figma file versions.
    public struct Cache: PklRegisteredType, Decodable, Hashable, Sendable {
        public static let registeredIdentifier: String = "Common#Cache"

        /// Enable version tracking cache.
        public var enabled: Bool?

        /// Custom path to cache file.
        public var path: String?

        public init(enabled: Bool?, path: String?) {
            self.enabled = enabled
            self.path = path
        }
    }

    public typealias FrameSource = Common_FrameSource

    /// Figma Frame source configuration.
    /// Used for icons and images that come from Figma frames.
    public struct FrameSourceImpl: FrameSource {
        public static let registeredIdentifier: String = "Common#FrameSource"

        /// Figma frame name to export from.
        public var figmaFrameName: String?

        /// Override Figma file ID for this specific entry.
        /// When set, overrides the global `figma.lightFileId` for loading data.
        public var figmaFileId: String?

        /// Figma component property name for RTL variant detection.
        /// When set, components in a COMPONENT_SET with this variant property
        /// have their RTL=Off variant exported with RTL metadata (isRTL flag).
        /// RTL=On variants are automatically skipped — the base variant is
        /// mirrored at runtime by the platform (iOS languageDirection, Android autoMirrored).
        /// Set to null to disable variant-based RTL detection.
        public var rtlProperty: String?

        /// Regex pattern for validating/capturing names.
        public var nameValidateRegexp: String?

        /// Replacement pattern using captured groups.
        public var nameReplaceRegexp: String?

        public init(
            figmaFrameName: String?,
            figmaFileId: String?,
            rtlProperty: String?,
            nameValidateRegexp: String?,
            nameReplaceRegexp: String?
        ) {
            self.figmaFrameName = figmaFrameName
            self.figmaFileId = figmaFileId
            self.rtlProperty = rtlProperty
            self.nameValidateRegexp = nameValidateRegexp
            self.nameReplaceRegexp = nameReplaceRegexp
        }
    }

    /// Common colors settings shared across platforms.
    public struct Colors: NameProcessing {
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
    public struct Icons: NameProcessing {
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
    public struct Images: NameProcessing {
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
    public struct Typography: NameProcessing {
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
    public struct VariablesColors: NameProcessing {
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
    public struct CommonConfig: PklRegisteredType, Decodable, Hashable, Sendable {
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
    public static func loadFrom(source: ModuleSource) async throws -> Common.Module {
        try await PklSwift.withEvaluator { evaluator in
            try await loadFrom(evaluator: evaluator, source: source)
        }
    }

    /// Load the Pkl module at the given source and evaluate it with the given evaluator into
    /// `Common.Module`.
    ///
    /// - Parameter evaluator: The evaluator to use for evaluation.
    /// - Parameter source: The module to evaluate.
    public static func loadFrom(
        evaluator: PklSwift.Evaluator,
        source: PklSwift.ModuleSource
    ) async throws -> Common.Module {
        try await evaluator.evaluateModule(source: source, as: Module.self)
    }
}
