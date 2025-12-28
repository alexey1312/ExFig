import ExFigCore
import Foundation

// swiftlint:disable nesting type_name type_body_length file_length
public struct Params: Decodable, Sendable {
    public struct Figma: Decodable, Sendable {
        public let lightFileId: String
        public let darkFileId: String?
        public let lightHighContrastFileId: String?
        public let darkHighContrastFileId: String?
        public let timeout: TimeInterval?
    }

    public struct Common: Decodable, Sendable {
        /// Cache configuration for tracking Figma file versions.
        /// When enabled, exports are skipped if the file version hasn't changed.
        public struct Cache: Decodable, Sendable {
            /// Enable version tracking cache. Default: false.
            public let enabled: Bool?

            /// Custom path to cache file. Default: .exfig-cache.json
            public let path: String?

            /// Whether cache is enabled (with default value).
            public var isEnabled: Bool { enabled ?? false }
        }

        public struct Colors: Decodable, Sendable {
            public let nameValidateRegexp: String?
            public let nameReplaceRegexp: String?
            public let useSingleFile: Bool?
            public let darkModeSuffix: String?
            public let lightHCModeSuffix: String?
            public let darkHCModeSuffix: String?
        }

        public struct VariablesColors: Decodable, Sendable {
            public let tokensFileId: String
            public let tokensCollectionName: String

            public let lightModeName: String
            public let darkModeName: String?
            public let lightHCModeName: String?
            public let darkHCModeName: String?

            public let primitivesModeName: String?

            public let nameValidateRegexp: String?
            public let nameReplaceRegexp: String?

            public init(
                tokensFileId: String,
                tokensCollectionName: String,
                lightModeName: String,
                darkModeName: String? = nil,
                lightHCModeName: String? = nil,
                darkHCModeName: String? = nil,
                primitivesModeName: String? = nil,
                nameValidateRegexp: String? = nil,
                nameReplaceRegexp: String? = nil
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

        public struct Icons: Decodable, Sendable {
            public let nameValidateRegexp: String?
            public let figmaFrameName: String?
            public let nameReplaceRegexp: String?
            public let useSingleFile: Bool?
            public let darkModeSuffix: String?
        }

        public struct Images: Decodable, Sendable {
            public let nameValidateRegexp: String?
            public let figmaFrameName: String?
            public let nameReplaceRegexp: String?
            public let useSingleFile: Bool?
            public let darkModeSuffix: String?
        }

        public struct Typography: Decodable, Sendable {
            public let nameValidateRegexp: String?
            public let nameReplaceRegexp: String?
        }

        public let cache: Cache?
        public let colors: Colors?
        public let variablesColors: VariablesColors?
        public let icons: Icons?
        public let images: Images?
        public let typography: Typography?
    }

    public enum VectorFormat: String, Decodable, Sendable {
        case pdf
        case svg
    }

    /// Source format for fetching images from Figma API.
    /// - `png`: Download raster PNG from Figma (default, legacy behavior)
    /// - `svg`: Download SVG and rasterize locally with resvg (higher quality)
    public enum SourceFormat: String, Decodable, Sendable {
        case png
        case svg
    }

    /// Output format for iOS images in asset catalogs.
    /// - `png`: Standard PNG format (default, maximum compatibility)
    /// - `heic`: HEIC format (~40-50% smaller, iOS 12+, macOS only for encoding)
    public enum ImageOutputFormat: String, Decodable, Sendable {
        case png
        case heic
    }

    /// HEIC encoding options for iOS images.
    public struct HeicOptions: Decodable, Sendable {
        /// Encoding mode: lossy (default) or lossless.
        public enum Encoding: String, Decodable, Sendable {
            case lossy
            case lossless
        }

        public let encoding: Encoding?
        public let quality: Int?

        /// Resolved encoding mode (default: lossy).
        public var resolvedEncoding: Encoding { encoding ?? .lossy }

        /// Resolved quality (default: 90).
        public var resolvedQuality: Int { quality ?? 90 }
    }

    public struct iOS: Decodable, Sendable {
        /// Single colors configuration (legacy format).
        /// Uses common.variablesColors for Figma Variables source.
        public struct Colors: Decodable, Sendable {
            public let useColorAssets: Bool
            public let assetsFolder: String?
            public let nameStyle: NameStyle
            public let groupUsingNamespace: Bool?

            public let colorSwift: URL?
            public let swiftuiColorSwift: URL?
        }

        /// Colors entry with Figma Variables source for multiple colors configuration.
        public struct ColorsEntry: Decodable, Sendable {
            // Source (Figma Variables)
            public let tokensFileId: String
            public let tokensCollectionName: String
            public let lightModeName: String
            public let darkModeName: String?
            public let lightHCModeName: String?
            public let darkHCModeName: String?
            public let primitivesModeName: String?
            public let nameValidateRegexp: String?
            public let nameReplaceRegexp: String?

            // Output (iOS-specific)
            public let useColorAssets: Bool
            public let assetsFolder: String?
            public let nameStyle: NameStyle
            public let groupUsingNamespace: Bool?
            public let colorSwift: URL?
            public let swiftuiColorSwift: URL?
        }

        /// Colors configuration supporting both single object and array formats.
        public enum ColorsConfiguration: Decodable, Sendable {
            case single(Colors)
            case multiple([ColorsEntry])

            public init(from decoder: Decoder) throws {
                // Try decoding as array first (new format)
                if let array = try? [ColorsEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                // Fallback to single object (legacy format)
                let single = try Colors(from: decoder)
                self = .single(single)
            }

            /// Returns all color entries for iteration.
            /// For legacy format, returns single entry with nil source fields (uses common.variablesColors).
            public var entries: [ColorsEntry] {
                switch self {
                case let .single(colors):
                    // Legacy format: source fields are nil, use common.variablesColors
                    [ColorsEntry(
                        tokensFileId: "",
                        tokensCollectionName: "",
                        lightModeName: "",
                        darkModeName: nil,
                        lightHCModeName: nil,
                        darkHCModeName: nil,
                        primitivesModeName: nil,
                        nameValidateRegexp: nil,
                        nameReplaceRegexp: nil,
                        useColorAssets: colors.useColorAssets,
                        assetsFolder: colors.assetsFolder,
                        nameStyle: colors.nameStyle,
                        groupUsingNamespace: colors.groupUsingNamespace,
                        colorSwift: colors.colorSwift,
                        swiftuiColorSwift: colors.swiftuiColorSwift
                    )]
                case let .multiple(entries):
                    entries
                }
            }

            /// Returns true if using new multi-entry format.
            public var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        /// Single icons configuration (legacy format).
        public struct Icons: Decodable, Sendable {
            public let format: VectorFormat
            public let assetsFolder: String
            public let preservesVectorRepresentation: [String]?
            public let nameStyle: NameStyle

            public let imageSwift: URL?
            public let swiftUIImageSwift: URL?

            public let renderMode: XcodeRenderMode?
            public let renderModeDefaultSuffix: String?
            public let renderModeOriginalSuffix: String?
            public let renderModeTemplateSuffix: String?
        }

        /// Icons entry with figmaFrameName for multiple icons configuration.
        public struct IconsEntry: Decodable, Sendable {
            /// Figma frame name to export icons from. Overrides common.icons.figmaFrameName.
            public let figmaFrameName: String?
            public let format: VectorFormat
            public let assetsFolder: String
            public let preservesVectorRepresentation: [String]?
            public let nameStyle: NameStyle
            /// Regex pattern for validating/capturing icon names. Overrides common.icons.nameValidateRegexp.
            public let nameValidateRegexp: String?
            /// Replacement pattern using captured groups. Overrides common.icons.nameReplaceRegexp.
            public let nameReplaceRegexp: String?

            public let imageSwift: URL?
            public let swiftUIImageSwift: URL?

            public let renderMode: XcodeRenderMode?
            public let renderModeDefaultSuffix: String?
            public let renderModeOriginalSuffix: String?
            public let renderModeTemplateSuffix: String?
        }

        /// Icons configuration supporting both single object and array formats.
        public enum IconsConfiguration: Decodable, Sendable {
            case single(Icons)
            case multiple([IconsEntry])

            public init(from decoder: Decoder) throws {
                // Try decoding as array first (new format)
                if let array = try? [IconsEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                // Fallback to single object (legacy format)
                let single = try Icons(from: decoder)
                self = .single(single)
            }

            /// Returns all icon entries for iteration.
            public var entries: [IconsEntry] {
                switch self {
                case let .single(icons):
                    // Convert legacy format to entry
                    [IconsEntry(
                        figmaFrameName: nil,
                        format: icons.format,
                        assetsFolder: icons.assetsFolder,
                        preservesVectorRepresentation: icons.preservesVectorRepresentation,
                        nameStyle: icons.nameStyle,
                        nameValidateRegexp: nil,
                        nameReplaceRegexp: nil,
                        imageSwift: icons.imageSwift,
                        swiftUIImageSwift: icons.swiftUIImageSwift,
                        renderMode: icons.renderMode,
                        renderModeDefaultSuffix: icons.renderModeDefaultSuffix,
                        renderModeOriginalSuffix: icons.renderModeOriginalSuffix,
                        renderModeTemplateSuffix: icons.renderModeTemplateSuffix
                    )]
                case let .multiple(entries):
                    entries
                }
            }

            /// Returns true if using new multi-entry format.
            public var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        /// Single images configuration (legacy format).
        public struct Images: Decodable, Sendable {
            public let assetsFolder: String
            public let nameStyle: NameStyle
            public let scales: [Double]?

            public let imageSwift: URL?
            public let swiftUIImageSwift: URL?

            public let renderMode: XcodeRenderMode?
            public let renderModeDefaultSuffix: String?
            public let renderModeOriginalSuffix: String?
            public let renderModeTemplateSuffix: String?
        }

        /// Images entry with figmaFrameName for multiple images configuration.
        public struct ImagesEntry: Decodable, Sendable {
            /// Figma frame name to export images from. Overrides common.images.figmaFrameName.
            public let figmaFrameName: String?
            public let assetsFolder: String
            public let nameStyle: NameStyle
            public let scales: [Double]?
            public let imageSwift: URL?
            public let swiftUIImageSwift: URL?
            /// Source format for fetching from Figma API. Default: png
            public let sourceFormat: SourceFormat?
            /// Output format for asset catalog. Default: png
            /// HEIC provides ~40-50% smaller files but requires iOS 12+ and macOS for encoding.
            public let outputFormat: ImageOutputFormat?
            /// HEIC encoding options. Only used when outputFormat is heic.
            public let heicOptions: HeicOptions?

            public let renderMode: XcodeRenderMode?
            public let renderModeDefaultSuffix: String?
            public let renderModeOriginalSuffix: String?
            public let renderModeTemplateSuffix: String?
        }

        /// Images configuration supporting both single object and array formats.
        public enum ImagesConfiguration: Decodable, Sendable {
            case single(Images)
            case multiple([ImagesEntry])

            public init(from decoder: Decoder) throws {
                if let array = try? [ImagesEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let single = try Images(from: decoder)
                self = .single(single)
            }

            public var entries: [ImagesEntry] {
                switch self {
                case let .single(images):
                    [ImagesEntry(
                        figmaFrameName: nil,
                        assetsFolder: images.assetsFolder,
                        nameStyle: images.nameStyle,
                        scales: images.scales,
                        imageSwift: images.imageSwift,
                        swiftUIImageSwift: images.swiftUIImageSwift,
                        sourceFormat: nil,
                        outputFormat: nil,
                        heicOptions: nil,
                        renderMode: images.renderMode,
                        renderModeDefaultSuffix: images.renderModeDefaultSuffix,
                        renderModeOriginalSuffix: images.renderModeOriginalSuffix,
                        renderModeTemplateSuffix: images.renderModeTemplateSuffix
                    )]
                case let .multiple(entries):
                    entries
                }
            }

            public var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        public struct Typography: Decodable, Sendable {
            public let fontSwift: URL?
            public let labelStyleSwift: URL?
            public let swiftUIFontSwift: URL?
            public let generateLabels: Bool
            public let labelsDirectory: URL?
            public let nameStyle: NameStyle
        }

        public let xcodeprojPath: String
        public let target: String
        public let xcassetsPath: URL
        public let xcassetsInMainBundle: Bool
        public let xcassetsInSwiftPackage: Bool?
        public let resourceBundleNames: [String]?
        public let addObjcAttribute: Bool?
        public let templatesPath: URL?

        public let colors: ColorsConfiguration?
        public let icons: IconsConfiguration?
        public let images: ImagesConfiguration?
        public let typography: Typography?
    }

    public struct Android: Decodable, Sendable {
        public enum ComposeIconFormat: String, Decodable, Sendable {
            /// Generates extension functions that use `painterResource(R.drawable.xxx)`
            case resourceReference
            /// Generates ImageVector code directly from SVG data
            case imageVector
        }

        /// Single icons configuration (legacy format).
        public struct Icons: Decodable, Sendable {
            public let output: String
            public let composePackageName: String?
            public let composeFormat: ComposeIconFormat?
            /// Extension target for ImageVector (e.g., "com.example.app.ui.AppIcons")
            public let composeExtensionTarget: String?
        }

        /// Icons entry with figmaFrameName for multiple icons configuration.
        public struct IconsEntry: Decodable, Sendable {
            /// Figma frame name to export icons from. Overrides common.icons.figmaFrameName.
            public let figmaFrameName: String?
            public let output: String
            public let composePackageName: String?
            public let composeFormat: ComposeIconFormat?
            public let composeExtensionTarget: String?
            /// Name style for icon names. Overrides default snake_case.
            public let nameStyle: NameStyle?
            /// Regex pattern for validating/capturing icon names. Overrides common.icons.nameValidateRegexp.
            public let nameValidateRegexp: String?
            /// Replacement pattern using captured groups. Overrides common.icons.nameReplaceRegexp.
            public let nameReplaceRegexp: String?
        }

        /// Icons configuration supporting both single object and array formats.
        public enum IconsConfiguration: Decodable, Sendable {
            case single(Icons)
            case multiple([IconsEntry])

            public init(from decoder: Decoder) throws {
                if let array = try? [IconsEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let single = try Icons(from: decoder)
                self = .single(single)
            }

            public var entries: [IconsEntry] {
                switch self {
                case let .single(icons):
                    [IconsEntry(
                        figmaFrameName: nil,
                        output: icons.output,
                        composePackageName: icons.composePackageName,
                        composeFormat: icons.composeFormat,
                        composeExtensionTarget: icons.composeExtensionTarget,
                        nameStyle: nil,
                        nameValidateRegexp: nil,
                        nameReplaceRegexp: nil
                    )]
                case let .multiple(entries):
                    entries
                }
            }

            public var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        /// Theme attributes configuration for generating attrs.xml and styles.xml.
        public struct ThemeAttributes: Decodable, Sendable {
            /// Whether theme attributes generation is enabled.
            public let enabled: Bool?

            /// Path to attrs.xml relative to mainRes (e.g., "../../../values/attrs.xml").
            public let attrsFile: String?

            /// Path to styles.xml relative to mainRes (e.g., "../../../values/styles.xml").
            public let stylesFile: String?

            /// Path to styles-night.xml relative to mainRes.
            public let stylesNightFile: String?

            /// Theme name used in markers (e.g., "Theme.MyApp.Main").
            public let themeName: String

            /// Custom marker start text (default: "FIGMA COLORS MARKER START").
            public let markerStart: String?

            /// Custom marker end text (default: "FIGMA COLORS MARKER END").
            public let markerEnd: String?

            /// Name transformation configuration.
            public let nameTransform: NameTransform?

            /// If true, create file with markers if missing.
            public let autoCreateMarkers: Bool?

            public var isEnabled: Bool { enabled ?? false }
            public var resolvedMarkerStart: String { markerStart ?? "FIGMA COLORS MARKER START" }
            public var resolvedMarkerEnd: String { markerEnd ?? "FIGMA COLORS MARKER END" }
            public var shouldAutoCreateMarkers: Bool { autoCreateMarkers ?? false }
            public var resolvedAttrsFile: String { attrsFile ?? "values/attrs.xml" }
            public var resolvedStylesFile: String { stylesFile ?? "values/styles.xml" }
            public var resolvedStylesNightFile: String { stylesNightFile ?? "values-night/styles.xml" }

            /// Name transformation options.
            public struct NameTransform: Decodable, Sendable {
                /// Target case style for attribute names (default: PascalCase).
                public let style: NameStyle?

                /// Prefix to add to attribute names (default: "color").
                public let prefix: String?

                /// Prefixes to strip from color names before transformation.
                public let stripPrefixes: [String]?

                public var resolvedStyle: NameStyle { style ?? .pascalCase }
                public var resolvedPrefix: String { prefix ?? "color" }
                public var resolvedStripPrefixes: [String] { stripPrefixes ?? [] }
            }
        }

        /// Single colors configuration (legacy format).
        /// Uses common.variablesColors for Figma Variables source.
        public struct Colors: Decodable, Sendable {
            public let xmlOutputFileName: String?
            public let composePackageName: String?
            public let themeAttributes: ThemeAttributes?
        }

        /// Colors entry with Figma Variables source for multiple colors configuration.
        public struct ColorsEntry: Decodable, Sendable {
            // Source (Figma Variables)
            public let tokensFileId: String
            public let tokensCollectionName: String
            public let lightModeName: String
            public let darkModeName: String?
            public let lightHCModeName: String?
            public let darkHCModeName: String?
            public let primitivesModeName: String?
            public let nameValidateRegexp: String?
            public let nameReplaceRegexp: String?

            // Output (Android-specific)
            public let xmlOutputFileName: String?
            public let composePackageName: String?

            // Theme attributes
            public let themeAttributes: ThemeAttributes?
        }

        /// Colors configuration supporting both single object and array formats.
        public enum ColorsConfiguration: Decodable, Sendable {
            case single(Colors)
            case multiple([ColorsEntry])

            public init(from decoder: Decoder) throws {
                if let array = try? [ColorsEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let single = try Colors(from: decoder)
                self = .single(single)
            }

            public var entries: [ColorsEntry] {
                switch self {
                case let .single(colors):
                    [ColorsEntry(
                        tokensFileId: "",
                        tokensCollectionName: "",
                        lightModeName: "",
                        darkModeName: nil,
                        lightHCModeName: nil,
                        darkHCModeName: nil,
                        primitivesModeName: nil,
                        nameValidateRegexp: nil,
                        nameReplaceRegexp: nil,
                        xmlOutputFileName: colors.xmlOutputFileName,
                        composePackageName: colors.composePackageName,
                        themeAttributes: colors.themeAttributes
                    )]
                case let .multiple(entries):
                    entries
                }
            }

            public var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        /// Single images configuration (legacy format).
        public struct Images: Decodable, Sendable {
            public enum Format: String, Decodable, Sendable {
                case svg
                case png
                case webp
            }

            public struct FormatOptions: Decodable, Sendable {
                public enum Encoding: String, Decodable, Sendable {
                    case lossy
                    case lossless
                }

                public let encoding: Encoding
                public let quality: Int?
            }

            public let scales: [Double]?
            public let output: String
            public let format: Format
            public let webpOptions: FormatOptions?
            /// Source format for fetching from Figma API. Default: png
            public let sourceFormat: SourceFormat?
        }

        /// Images entry with figmaFrameName for multiple images configuration.
        public struct ImagesEntry: Decodable, Sendable {
            /// Figma frame name to export images from. Overrides common.images.figmaFrameName.
            public let figmaFrameName: String?
            public let scales: [Double]?
            public let output: String
            public let format: Images.Format
            public let webpOptions: Images.FormatOptions?
            /// Source format for fetching from Figma API. Default: png
            public let sourceFormat: SourceFormat?
        }

        /// Images configuration supporting both single object and array formats.
        public enum ImagesConfiguration: Decodable, Sendable {
            case single(Images)
            case multiple([ImagesEntry])

            public init(from decoder: Decoder) throws {
                if let array = try? [ImagesEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let single = try Images(from: decoder)
                self = .single(single)
            }

            public var entries: [ImagesEntry] {
                switch self {
                case let .single(images):
                    [ImagesEntry(
                        figmaFrameName: nil,
                        scales: images.scales,
                        output: images.output,
                        format: images.format,
                        webpOptions: images.webpOptions,
                        sourceFormat: images.sourceFormat
                    )]
                case let .multiple(entries):
                    entries
                }
            }

            public var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        public struct Typography: Decodable, Sendable {
            public let nameStyle: NameStyle
            public let composePackageName: String?
        }

        public let mainRes: URL
        public let resourcePackage: String?
        public let mainSrc: URL?
        public let colors: ColorsConfiguration?
        public let icons: IconsConfiguration?
        public let images: ImagesConfiguration?
        public let typography: Typography?
        public let templatesPath: URL?
    }

    public struct Flutter: Decodable, Sendable {
        public enum ImageFormat: String, Decodable, Sendable {
            case svg
            case png
            case webp
        }

        /// Single colors configuration (legacy format).
        /// Uses common.variablesColors for Figma Variables source.
        public struct Colors: Decodable, Sendable {
            public let output: String?
            public let className: String?
        }

        /// Colors entry with Figma Variables source for multiple colors configuration.
        public struct ColorsEntry: Decodable, Sendable {
            // Source (Figma Variables)
            public let tokensFileId: String
            public let tokensCollectionName: String
            public let lightModeName: String
            public let darkModeName: String?
            public let lightHCModeName: String?
            public let darkHCModeName: String?
            public let primitivesModeName: String?
            public let nameValidateRegexp: String?
            public let nameReplaceRegexp: String?

            // Output (Flutter-specific)
            public let output: String?
            public let className: String?
        }

        /// Colors configuration supporting both single object and array formats.
        public enum ColorsConfiguration: Decodable, Sendable {
            case single(Colors)
            case multiple([ColorsEntry])

            public init(from decoder: Decoder) throws {
                if let array = try? [ColorsEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let single = try Colors(from: decoder)
                self = .single(single)
            }

            public var entries: [ColorsEntry] {
                switch self {
                case let .single(colors):
                    [ColorsEntry(
                        tokensFileId: "",
                        tokensCollectionName: "",
                        lightModeName: "",
                        darkModeName: nil,
                        lightHCModeName: nil,
                        darkHCModeName: nil,
                        primitivesModeName: nil,
                        nameValidateRegexp: nil,
                        nameReplaceRegexp: nil,
                        output: colors.output,
                        className: colors.className
                    )]
                case let .multiple(entries):
                    entries
                }
            }

            public var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        /// Single icons configuration (legacy format).
        public struct Icons: Decodable, Sendable {
            public let output: String
            public let dartFile: String?
            public let className: String?
        }

        /// Icons entry with figmaFrameName for multiple icons configuration.
        public struct IconsEntry: Decodable, Sendable {
            /// Figma frame name to export icons from. Overrides common.icons.figmaFrameName.
            public let figmaFrameName: String?
            public let output: String
            public let dartFile: String?
            public let className: String?
            /// Name style for icon names. Overrides default snake_case.
            public let nameStyle: NameStyle?
            /// Regex pattern for validating/capturing icon names. Overrides common.icons.nameValidateRegexp.
            public let nameValidateRegexp: String?
            /// Replacement pattern using captured groups. Overrides common.icons.nameReplaceRegexp.
            public let nameReplaceRegexp: String?
        }

        /// Icons configuration supporting both single object and array formats.
        public enum IconsConfiguration: Decodable, Sendable {
            case single(Icons)
            case multiple([IconsEntry])

            public init(from decoder: Decoder) throws {
                if let array = try? [IconsEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let single = try Icons(from: decoder)
                self = .single(single)
            }

            public var entries: [IconsEntry] {
                switch self {
                case let .single(icons):
                    [IconsEntry(
                        figmaFrameName: nil,
                        output: icons.output,
                        dartFile: icons.dartFile,
                        className: icons.className,
                        nameStyle: nil,
                        nameValidateRegexp: nil,
                        nameReplaceRegexp: nil
                    )]
                case let .multiple(entries):
                    entries
                }
            }

            public var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        /// Single images configuration (legacy format).
        public struct Images: Decodable, Sendable {
            public let output: String
            public let dartFile: String?
            public let className: String?
            public let scales: [Double]?
            public let format: ImageFormat?
            public let webpOptions: Android.Images.FormatOptions?
            /// Source format for fetching from Figma API. Default: png
            public let sourceFormat: SourceFormat?
        }

        /// Images entry with figmaFrameName for multiple images configuration.
        public struct ImagesEntry: Decodable, Sendable {
            /// Figma frame name to export images from. Overrides common.images.figmaFrameName.
            public let figmaFrameName: String?
            public let output: String
            public let dartFile: String?
            public let className: String?
            public let scales: [Double]?
            public let format: ImageFormat?
            public let webpOptions: Android.Images.FormatOptions?
            /// Source format for fetching from Figma API. Default: png
            public let sourceFormat: SourceFormat?
        }

        /// Images configuration supporting both single object and array formats.
        public enum ImagesConfiguration: Decodable, Sendable {
            case single(Images)
            case multiple([ImagesEntry])

            public init(from decoder: Decoder) throws {
                if let array = try? [ImagesEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let single = try Images(from: decoder)
                self = .single(single)
            }

            public var entries: [ImagesEntry] {
                switch self {
                case let .single(images):
                    [ImagesEntry(
                        figmaFrameName: nil,
                        output: images.output,
                        dartFile: images.dartFile,
                        className: images.className,
                        scales: images.scales,
                        format: images.format,
                        webpOptions: images.webpOptions,
                        sourceFormat: images.sourceFormat
                    )]
                case let .multiple(entries):
                    entries
                }
            }

            public var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        public let output: URL
        public let colors: ColorsConfiguration?
        public let icons: IconsConfiguration?
        public let images: ImagesConfiguration?
        public let templatesPath: URL?
    }

    // MARK: - Web

    public struct Web: Decodable, Sendable {
        /// Single colors configuration (legacy format).
        /// Uses common.variablesColors for Figma Variables source.
        public struct Colors: Decodable, Sendable {
            public let outputDirectory: String?
            public let cssFileName: String?
            public let tsFileName: String?
            public let jsonFileName: String?
        }

        /// Colors entry with Figma Variables source for multiple colors configuration.
        public struct ColorsEntry: Decodable, Sendable {
            // Source (Figma Variables)
            public let tokensFileId: String
            public let tokensCollectionName: String
            public let lightModeName: String
            public let darkModeName: String?
            public let lightHCModeName: String?
            public let darkHCModeName: String?
            public let primitivesModeName: String?
            public let nameValidateRegexp: String?
            public let nameReplaceRegexp: String?

            // Output (Web-specific)
            public let outputDirectory: String?
            public let cssFileName: String?
            public let tsFileName: String?
            public let jsonFileName: String?
        }

        /// Colors configuration supporting both single object and array formats.
        public enum ColorsConfiguration: Decodable, Sendable {
            case single(Colors)
            case multiple([ColorsEntry])

            public init(from decoder: Decoder) throws {
                if let array = try? [ColorsEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let single = try Colors(from: decoder)
                self = .single(single)
            }

            public var entries: [ColorsEntry] {
                switch self {
                case let .single(colors):
                    [ColorsEntry(
                        tokensFileId: "",
                        tokensCollectionName: "",
                        lightModeName: "",
                        darkModeName: nil,
                        lightHCModeName: nil,
                        darkHCModeName: nil,
                        primitivesModeName: nil,
                        nameValidateRegexp: nil,
                        nameReplaceRegexp: nil,
                        outputDirectory: colors.outputDirectory,
                        cssFileName: colors.cssFileName,
                        tsFileName: colors.tsFileName,
                        jsonFileName: colors.jsonFileName
                    )]
                case let .multiple(entries):
                    entries
                }
            }

            public var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        /// Single icons configuration (legacy format).
        public struct Icons: Decodable, Sendable {
            public let outputDirectory: String
            public let svgDirectory: String?
            public let generateReactComponents: Bool?
            /// Icon size in pixels for viewBox. Defaults to 24.
            public let iconSize: Int?
        }

        /// Icons entry with figmaFrameName for multiple icons configuration.
        public struct IconsEntry: Decodable, Sendable {
            /// Figma frame name to export icons from. Overrides common.icons.figmaFrameName.
            public let figmaFrameName: String?
            public let outputDirectory: String
            public let svgDirectory: String?
            public let generateReactComponents: Bool?
            /// Icon size in pixels for viewBox. Defaults to 24.
            public let iconSize: Int?
            /// Name style for icon names. Overrides default snake_case.
            public let nameStyle: NameStyle?
            /// Regex pattern for validating/capturing icon names. Overrides common.icons.nameValidateRegexp.
            public let nameValidateRegexp: String?
            /// Replacement pattern using captured groups. Overrides common.icons.nameReplaceRegexp.
            public let nameReplaceRegexp: String?
        }

        /// Icons configuration supporting both single object and array formats.
        public enum IconsConfiguration: Decodable, Sendable {
            case single(Icons)
            case multiple([IconsEntry])

            public init(from decoder: Decoder) throws {
                if let array = try? [IconsEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let single = try Icons(from: decoder)
                self = .single(single)
            }

            public var entries: [IconsEntry] {
                switch self {
                case let .single(icons):
                    [IconsEntry(
                        figmaFrameName: nil,
                        outputDirectory: icons.outputDirectory,
                        svgDirectory: icons.svgDirectory,
                        generateReactComponents: icons.generateReactComponents,
                        iconSize: icons.iconSize,
                        nameStyle: nil,
                        nameValidateRegexp: nil,
                        nameReplaceRegexp: nil
                    )]
                case let .multiple(entries):
                    entries
                }
            }

            public var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        /// Single images configuration (legacy format).
        public struct Images: Decodable, Sendable {
            public let outputDirectory: String
            public let assetsDirectory: String?
            public let generateReactComponents: Bool?
        }

        /// Images entry with figmaFrameName for multiple images configuration.
        public struct ImagesEntry: Decodable, Sendable {
            /// Figma frame name to export images from. Overrides common.images.figmaFrameName.
            public let figmaFrameName: String?
            public let outputDirectory: String
            public let assetsDirectory: String?
            public let generateReactComponents: Bool?
        }

        /// Images configuration supporting both single object and array formats.
        public enum ImagesConfiguration: Decodable, Sendable {
            case single(Images)
            case multiple([ImagesEntry])

            public init(from decoder: Decoder) throws {
                if let array = try? [ImagesEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let single = try Images(from: decoder)
                self = .single(single)
            }

            public var entries: [ImagesEntry] {
                switch self {
                case let .single(images):
                    [ImagesEntry(
                        figmaFrameName: nil,
                        outputDirectory: images.outputDirectory,
                        assetsDirectory: images.assetsDirectory,
                        generateReactComponents: images.generateReactComponents
                    )]
                case let .multiple(entries):
                    entries
                }
            }

            public var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        public let output: URL
        public let colors: ColorsConfiguration?
        public let icons: IconsConfiguration?
        public let images: ImagesConfiguration?
        public let templatesPath: URL?
    }

    public let figma: Figma
    public let common: Common?
    public let ios: iOS?
    public let android: Android?
    public let flutter: Flutter?
    public let web: Web?
}
