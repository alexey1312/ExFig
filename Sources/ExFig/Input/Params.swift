import ExFigCore
import Foundation

// swiftlint:disable nesting type_name type_body_length file_length
struct Params: Decodable {
    struct Figma: Decodable {
        let lightFileId: String
        let darkFileId: String?
        let lightHighContrastFileId: String?
        let darkHighContrastFileId: String?
        let timeout: TimeInterval?
    }

    struct Common: Decodable {
        /// Cache configuration for tracking Figma file versions.
        /// When enabled, exports are skipped if the file version hasn't changed.
        struct Cache: Decodable {
            /// Enable version tracking cache. Default: false.
            let enabled: Bool?

            /// Custom path to cache file. Default: .exfig-cache.json
            let path: String?

            /// Whether cache is enabled (with default value).
            var isEnabled: Bool { enabled ?? false }
        }

        struct Colors: Decodable {
            let nameValidateRegexp: String?
            let nameReplaceRegexp: String?
            let useSingleFile: Bool?
            let darkModeSuffix: String?
            let lightHCModeSuffix: String?
            let darkHCModeSuffix: String?
        }

        struct VariablesColors: Decodable {
            let tokensFileId: String
            let tokensCollectionName: String

            let lightModeName: String
            let darkModeName: String?
            let lightHCModeName: String?
            let darkHCModeName: String?

            let primitivesModeName: String?

            let nameValidateRegexp: String?
            let nameReplaceRegexp: String?
        }

        struct Icons: Decodable {
            let nameValidateRegexp: String?
            let figmaFrameName: String?
            let nameReplaceRegexp: String?
            let useSingleFile: Bool?
            let darkModeSuffix: String?
        }

        struct Images: Decodable {
            let nameValidateRegexp: String?
            let figmaFrameName: String?
            let nameReplaceRegexp: String?
            let useSingleFile: Bool?
            let darkModeSuffix: String?
        }

        struct Typography: Decodable {
            let nameValidateRegexp: String?
            let nameReplaceRegexp: String?
        }

        let cache: Cache?
        let colors: Colors?
        let variablesColors: VariablesColors?
        let icons: Icons?
        let images: Images?
        let typography: Typography?
    }

    enum VectorFormat: String, Decodable {
        case pdf
        case svg
    }

    struct iOS: Decodable {
        /// Single colors configuration (legacy format).
        /// Uses common.variablesColors for Figma Variables source.
        struct Colors: Decodable {
            let useColorAssets: Bool
            let assetsFolder: String?
            let nameStyle: NameStyle
            let groupUsingNamespace: Bool?

            let colorSwift: URL?
            let swiftuiColorSwift: URL?
        }

        /// Colors entry with Figma Variables source for multiple colors configuration.
        struct ColorsEntry: Decodable {
            // Source (Figma Variables)
            let tokensFileId: String
            let tokensCollectionName: String
            let lightModeName: String
            let darkModeName: String?
            let lightHCModeName: String?
            let darkHCModeName: String?
            let primitivesModeName: String?
            let nameValidateRegexp: String?
            let nameReplaceRegexp: String?

            // Output (iOS-specific)
            let useColorAssets: Bool
            let assetsFolder: String?
            let nameStyle: NameStyle
            let groupUsingNamespace: Bool?
            let colorSwift: URL?
            let swiftuiColorSwift: URL?
        }

        /// Colors configuration supporting both single object and array formats.
        enum ColorsConfiguration: Decodable {
            case single(Colors)
            case multiple([ColorsEntry])

            init(from decoder: Decoder) throws {
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
            var entries: [ColorsEntry] {
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
            var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        /// Single icons configuration (legacy format).
        struct Icons: Decodable {
            let format: VectorFormat
            let assetsFolder: String
            let preservesVectorRepresentation: [String]?
            let nameStyle: NameStyle

            let imageSwift: URL?
            let swiftUIImageSwift: URL?

            let renderMode: XcodeRenderMode?
            let renderModeDefaultSuffix: String?
            let renderModeOriginalSuffix: String?
            let renderModeTemplateSuffix: String?
        }

        /// Icons entry with figmaFrameName for multiple icons configuration.
        struct IconsEntry: Decodable {
            /// Figma frame name to export icons from. Overrides common.icons.figmaFrameName.
            let figmaFrameName: String?
            let format: VectorFormat
            let assetsFolder: String
            let preservesVectorRepresentation: [String]?
            let nameStyle: NameStyle

            let imageSwift: URL?
            let swiftUIImageSwift: URL?

            let renderMode: XcodeRenderMode?
            let renderModeDefaultSuffix: String?
            let renderModeOriginalSuffix: String?
            let renderModeTemplateSuffix: String?
        }

        /// Icons configuration supporting both single object and array formats.
        enum IconsConfiguration: Decodable {
            case single(Icons)
            case multiple([IconsEntry])

            init(from decoder: Decoder) throws {
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
            var entries: [IconsEntry] {
                switch self {
                case let .single(icons):
                    // Convert legacy format to entry
                    [IconsEntry(
                        figmaFrameName: nil,
                        format: icons.format,
                        assetsFolder: icons.assetsFolder,
                        preservesVectorRepresentation: icons.preservesVectorRepresentation,
                        nameStyle: icons.nameStyle,
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
            var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        /// Single images configuration (legacy format).
        struct Images: Decodable {
            let assetsFolder: String
            let nameStyle: NameStyle
            let scales: [Double]?

            let imageSwift: URL?
            let swiftUIImageSwift: URL?
        }

        /// Images entry with figmaFrameName for multiple images configuration.
        struct ImagesEntry: Decodable {
            /// Figma frame name to export images from. Overrides common.images.figmaFrameName.
            let figmaFrameName: String?
            let assetsFolder: String
            let nameStyle: NameStyle
            let scales: [Double]?
            let imageSwift: URL?
            let swiftUIImageSwift: URL?
        }

        /// Images configuration supporting both single object and array formats.
        enum ImagesConfiguration: Decodable {
            case single(Images)
            case multiple([ImagesEntry])

            init(from decoder: Decoder) throws {
                if let array = try? [ImagesEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let single = try Images(from: decoder)
                self = .single(single)
            }

            var entries: [ImagesEntry] {
                switch self {
                case let .single(images):
                    [ImagesEntry(
                        figmaFrameName: nil,
                        assetsFolder: images.assetsFolder,
                        nameStyle: images.nameStyle,
                        scales: images.scales,
                        imageSwift: images.imageSwift,
                        swiftUIImageSwift: images.swiftUIImageSwift
                    )]
                case let .multiple(entries):
                    entries
                }
            }

            var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        struct Typography: Decodable {
            let fontSwift: URL?
            let labelStyleSwift: URL?
            let swiftUIFontSwift: URL?
            let generateLabels: Bool
            let labelsDirectory: URL?
            let nameStyle: NameStyle
        }

        let xcodeprojPath: String
        let target: String
        let xcassetsPath: URL
        let xcassetsInMainBundle: Bool
        let xcassetsInSwiftPackage: Bool?
        let resourceBundleNames: [String]?
        let addObjcAttribute: Bool?
        let templatesPath: URL?

        let colors: ColorsConfiguration?
        let icons: IconsConfiguration?
        let images: ImagesConfiguration?
        let typography: Typography?
    }

    struct Android: Decodable {
        enum ComposeIconFormat: String, Decodable {
            /// Generates extension functions that use `painterResource(R.drawable.xxx)`
            case resourceReference
            /// Generates ImageVector code directly from SVG data
            case imageVector
        }

        /// Single icons configuration (legacy format).
        struct Icons: Decodable {
            let output: String
            let composePackageName: String?
            let composeFormat: ComposeIconFormat?
            /// Extension target for ImageVector (e.g., "com.example.app.ui.AppIcons")
            let composeExtensionTarget: String?
        }

        /// Icons entry with figmaFrameName for multiple icons configuration.
        struct IconsEntry: Decodable {
            /// Figma frame name to export icons from. Overrides common.icons.figmaFrameName.
            let figmaFrameName: String?
            let output: String
            let composePackageName: String?
            let composeFormat: ComposeIconFormat?
            let composeExtensionTarget: String?
        }

        /// Icons configuration supporting both single object and array formats.
        enum IconsConfiguration: Decodable {
            case single(Icons)
            case multiple([IconsEntry])

            init(from decoder: Decoder) throws {
                if let array = try? [IconsEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let single = try Icons(from: decoder)
                self = .single(single)
            }

            var entries: [IconsEntry] {
                switch self {
                case let .single(icons):
                    [IconsEntry(
                        figmaFrameName: nil,
                        output: icons.output,
                        composePackageName: icons.composePackageName,
                        composeFormat: icons.composeFormat,
                        composeExtensionTarget: icons.composeExtensionTarget
                    )]
                case let .multiple(entries):
                    entries
                }
            }

            var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        /// Single colors configuration (legacy format).
        /// Uses common.variablesColors for Figma Variables source.
        struct Colors: Decodable {
            let xmlOutputFileName: String?
            let composePackageName: String?
        }

        /// Colors entry with Figma Variables source for multiple colors configuration.
        struct ColorsEntry: Decodable {
            // Source (Figma Variables)
            let tokensFileId: String
            let tokensCollectionName: String
            let lightModeName: String
            let darkModeName: String?
            let lightHCModeName: String?
            let darkHCModeName: String?
            let primitivesModeName: String?
            let nameValidateRegexp: String?
            let nameReplaceRegexp: String?

            // Output (Android-specific)
            let xmlOutputFileName: String?
            let composePackageName: String?
        }

        /// Colors configuration supporting both single object and array formats.
        enum ColorsConfiguration: Decodable {
            case single(Colors)
            case multiple([ColorsEntry])

            init(from decoder: Decoder) throws {
                if let array = try? [ColorsEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let single = try Colors(from: decoder)
                self = .single(single)
            }

            var entries: [ColorsEntry] {
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
                        composePackageName: colors.composePackageName
                    )]
                case let .multiple(entries):
                    entries
                }
            }

            var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        /// Single images configuration (legacy format).
        struct Images: Decodable {
            enum Format: String, Decodable {
                case svg
                case png
                case webp
            }

            struct FormatOptions: Decodable {
                enum Encoding: String, Decodable {
                    case lossy
                    case lossless
                }

                let encoding: Encoding
                let quality: Int?
            }

            let scales: [Double]?
            let output: String
            let format: Format
            let webpOptions: FormatOptions?
        }

        /// Images entry with figmaFrameName for multiple images configuration.
        struct ImagesEntry: Decodable {
            /// Figma frame name to export images from. Overrides common.images.figmaFrameName.
            let figmaFrameName: String?
            let scales: [Double]?
            let output: String
            let format: Images.Format
            let webpOptions: Images.FormatOptions?
        }

        /// Images configuration supporting both single object and array formats.
        enum ImagesConfiguration: Decodable {
            case single(Images)
            case multiple([ImagesEntry])

            init(from decoder: Decoder) throws {
                if let array = try? [ImagesEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let single = try Images(from: decoder)
                self = .single(single)
            }

            var entries: [ImagesEntry] {
                switch self {
                case let .single(images):
                    [ImagesEntry(
                        figmaFrameName: nil,
                        scales: images.scales,
                        output: images.output,
                        format: images.format,
                        webpOptions: images.webpOptions
                    )]
                case let .multiple(entries):
                    entries
                }
            }

            var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        struct Typography: Decodable {
            let nameStyle: NameStyle
            let composePackageName: String?
        }

        let mainRes: URL
        let resourcePackage: String?
        let mainSrc: URL?
        let colors: ColorsConfiguration?
        let icons: IconsConfiguration?
        let images: ImagesConfiguration?
        let typography: Typography?
        let templatesPath: URL?
    }

    struct Flutter: Decodable {
        enum ImageFormat: String, Decodable {
            case svg
            case png
            case webp
        }

        /// Single colors configuration (legacy format).
        /// Uses common.variablesColors for Figma Variables source.
        struct Colors: Decodable {
            let output: String?
            let className: String?
        }

        /// Colors entry with Figma Variables source for multiple colors configuration.
        struct ColorsEntry: Decodable {
            // Source (Figma Variables)
            let tokensFileId: String
            let tokensCollectionName: String
            let lightModeName: String
            let darkModeName: String?
            let lightHCModeName: String?
            let darkHCModeName: String?
            let primitivesModeName: String?
            let nameValidateRegexp: String?
            let nameReplaceRegexp: String?

            // Output (Flutter-specific)
            let output: String?
            let className: String?
        }

        /// Colors configuration supporting both single object and array formats.
        enum ColorsConfiguration: Decodable {
            case single(Colors)
            case multiple([ColorsEntry])

            init(from decoder: Decoder) throws {
                if let array = try? [ColorsEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let single = try Colors(from: decoder)
                self = .single(single)
            }

            var entries: [ColorsEntry] {
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

            var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        /// Single icons configuration (legacy format).
        struct Icons: Decodable {
            let output: String
            let dartFile: String?
            let className: String?
        }

        /// Icons entry with figmaFrameName for multiple icons configuration.
        struct IconsEntry: Decodable {
            /// Figma frame name to export icons from. Overrides common.icons.figmaFrameName.
            let figmaFrameName: String?
            let output: String
            let dartFile: String?
            let className: String?
        }

        /// Icons configuration supporting both single object and array formats.
        enum IconsConfiguration: Decodable {
            case single(Icons)
            case multiple([IconsEntry])

            init(from decoder: Decoder) throws {
                if let array = try? [IconsEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let single = try Icons(from: decoder)
                self = .single(single)
            }

            var entries: [IconsEntry] {
                switch self {
                case let .single(icons):
                    [IconsEntry(
                        figmaFrameName: nil,
                        output: icons.output,
                        dartFile: icons.dartFile,
                        className: icons.className
                    )]
                case let .multiple(entries):
                    entries
                }
            }

            var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        /// Single images configuration (legacy format).
        struct Images: Decodable {
            let output: String
            let dartFile: String?
            let className: String?
            let scales: [Double]?
            let format: ImageFormat?
            let webpOptions: Android.Images.FormatOptions?
        }

        /// Images entry with figmaFrameName for multiple images configuration.
        struct ImagesEntry: Decodable {
            /// Figma frame name to export images from. Overrides common.images.figmaFrameName.
            let figmaFrameName: String?
            let output: String
            let dartFile: String?
            let className: String?
            let scales: [Double]?
            let format: ImageFormat?
            let webpOptions: Android.Images.FormatOptions?
        }

        /// Images configuration supporting both single object and array formats.
        enum ImagesConfiguration: Decodable {
            case single(Images)
            case multiple([ImagesEntry])

            init(from decoder: Decoder) throws {
                if let array = try? [ImagesEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let single = try Images(from: decoder)
                self = .single(single)
            }

            var entries: [ImagesEntry] {
                switch self {
                case let .single(images):
                    [ImagesEntry(
                        figmaFrameName: nil,
                        output: images.output,
                        dartFile: images.dartFile,
                        className: images.className,
                        scales: images.scales,
                        format: images.format,
                        webpOptions: images.webpOptions
                    )]
                case let .multiple(entries):
                    entries
                }
            }

            var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        let output: URL
        let colors: ColorsConfiguration?
        let icons: IconsConfiguration?
        let images: ImagesConfiguration?
        let templatesPath: URL?
    }

    let figma: Figma
    let common: Common?
    let ios: iOS?
    let android: Android?
    let flutter: Flutter?
}
