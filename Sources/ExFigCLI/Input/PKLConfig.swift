// swiftlint:disable nesting type_name type_body_length file_length

import ExFig_Android
import ExFig_Flutter
import ExFig_iOS
import ExFig_Web
import ExFigCore
import Foundation

/// PKL configuration structure using plugin Entry types directly.
///
/// This replaces the legacy `Params` struct by using plugin-defined Entry types
/// for platform-specific configuration, eliminating type duplication.
///
/// ## Migration from Params
///
/// | Params type | PKLConfig type |
/// |-------------|----------------|
/// | Params.iOS.ColorsEntry | iOSColorsEntry |
/// | Params.Android.IconsEntry | AndroidIconsEntry |
/// | Params.Common.VariablesColors | PKLConfig.Common.VariablesColors |
///
struct PKLConfig: Decodable {
    // MARK: - Figma Configuration

    struct Figma: Decodable {
        /// Figma file ID for light mode colors, icons, images, and typography.
        /// Required for legacy Styles API exports (icons, images, typography).
        /// Optional when using only Variables API for colors.
        let lightFileId: String?
        let darkFileId: String?
        let lightHighContrastFileId: String?
        let darkHighContrastFileId: String?
        let timeout: TimeInterval?
    }

    // MARK: - Common Configuration

    struct Common: Decodable {
        struct Cache: Decodable {
            let enabled: Bool?
            let path: String?

            var isEnabled: Bool {
                enabled ?? false
            }
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
            let strictPathValidation: Bool?
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

    // MARK: - Shared Enums

    enum VectorFormat: String, Decodable {
        case pdf
        case svg
    }

    enum SourceFormat: String, Decodable {
        case png
        case svg
    }

    enum ImageOutputFormat: String, Decodable {
        case png
        case heic
    }

    struct HeicOptions: Decodable {
        enum Encoding: String, Decodable {
            case lossy
            case lossless
        }

        let encoding: Encoding?
        let quality: Int?

        var resolvedEncoding: Encoding {
            encoding ?? .lossy
        }

        var resolvedQuality: Int {
            quality ?? 90
        }
    }

    // MARK: - iOS Platform

    struct iOS: Decodable {
        /// Legacy single colors configuration (uses common.variablesColors for source).
        struct ColorsLegacy: Decodable {
            let useColorAssets: Bool
            let assetsFolder: String?
            let nameStyle: NameStyle
            let groupUsingNamespace: Bool?
            let colorSwift: URL?
            let swiftuiColorSwift: URL?
            let syncCodeSyntax: Bool?
            let codeSyntaxTemplate: String?
        }

        /// Colors configuration supporting both legacy and multi-entry formats.
        enum ColorsConfiguration: Decodable {
            case legacy(ColorsLegacy)
            case multiple([iOSColorsEntry])

            init(from decoder: Decoder) throws {
                if let array = try? [iOSColorsEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let legacy = try ColorsLegacy(from: decoder)
                self = .legacy(legacy)
            }

            var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        /// Legacy single icons configuration.
        struct IconsLegacy: Decodable {
            let format: VectorFormat
            let assetsFolder: String
            let preservesVectorRepresentation: [String]?
            let nameStyle: NameStyle
            let imageSwift: URL?
            let swiftUIImageSwift: URL?
            let codeConnectSwift: URL?
            let renderMode: XcodeRenderMode?
            let renderModeDefaultSuffix: String?
            let renderModeOriginalSuffix: String?
            let renderModeTemplateSuffix: String?
        }

        /// Icons configuration supporting both legacy and multi-entry formats.
        enum IconsConfiguration: Decodable {
            case legacy(IconsLegacy)
            case multiple([iOSIconsEntry])

            init(from decoder: Decoder) throws {
                if let array = try? [iOSIconsEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let legacy = try IconsLegacy(from: decoder)
                self = .legacy(legacy)
            }

            var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        /// Legacy single images configuration.
        struct ImagesLegacy: Decodable {
            let assetsFolder: String
            let nameStyle: NameStyle
            let scales: [Double]?
            let imageSwift: URL?
            let swiftUIImageSwift: URL?
            let codeConnectSwift: URL?
            let renderMode: XcodeRenderMode?
            let renderModeDefaultSuffix: String?
            let renderModeOriginalSuffix: String?
            let renderModeTemplateSuffix: String?
        }

        /// Images configuration supporting both legacy and multi-entry formats.
        enum ImagesConfiguration: Decodable {
            case legacy(ImagesLegacy)
            case multiple([iOSImagesEntry])

            init(from decoder: Decoder) throws {
                if let array = try? [iOSImagesEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let legacy = try ImagesLegacy(from: decoder)
                self = .legacy(legacy)
            }

            var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
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
        let typography: iOSTypographyEntry?
    }

    // MARK: - Android Platform

    struct Android: Decodable {
        /// Legacy single colors configuration.
        struct ColorsLegacy: Decodable {
            let xmlOutputFileName: String?
            let xmlDisabled: Bool?
            let composePackageName: String?
            let colorKotlin: URL?
            let themeAttributes: ExFig_Android.ThemeAttributes?
        }

        /// Colors configuration supporting both legacy and multi-entry formats.
        enum ColorsConfiguration: Decodable {
            case legacy(ColorsLegacy)
            case multiple([AndroidColorsEntry])

            init(from decoder: Decoder) throws {
                if let array = try? [AndroidColorsEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let legacy = try ColorsLegacy(from: decoder)
                self = .legacy(legacy)
            }

            var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        /// Legacy single icons configuration.
        struct IconsLegacy: Decodable {
            let output: String
            let composePackageName: String?
            let composeFormat: ExFig_Android.ComposeIconFormat?
            let composeExtensionTarget: String?
            let pathPrecision: Int?
            let strictPathValidation: Bool?
        }

        /// Icons configuration supporting both legacy and multi-entry formats.
        enum IconsConfiguration: Decodable {
            case legacy(IconsLegacy)
            case multiple([AndroidIconsEntry])

            init(from decoder: Decoder) throws {
                if let array = try? [AndroidIconsEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let legacy = try IconsLegacy(from: decoder)
                self = .legacy(legacy)
            }

            var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        enum ImagesFormat: String, Decodable {
            case svg
            case png
            case webp
        }

        struct WebpOptions: Decodable {
            enum Encoding: String, Decodable {
                case lossy
                case lossless
            }

            let encoding: Encoding
            let quality: Int?
        }

        /// Legacy single images configuration.
        struct ImagesLegacy: Decodable {
            let scales: [Double]?
            let output: String
            let format: ImagesFormat
            let webpOptions: WebpOptions?
            let sourceFormat: SourceFormat?
        }

        /// Images configuration supporting both legacy and multi-entry formats.
        enum ImagesConfiguration: Decodable {
            case legacy(ImagesLegacy)
            case multiple([AndroidImagesEntry])

            init(from decoder: Decoder) throws {
                if let array = try? [AndroidImagesEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let legacy = try ImagesLegacy(from: decoder)
                self = .legacy(legacy)
            }

            var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        let mainRes: URL
        let resourcePackage: String?
        let mainSrc: URL?
        let colors: ColorsConfiguration?
        let icons: IconsConfiguration?
        let images: ImagesConfiguration?
        let typography: AndroidTypographyEntry?
        let templatesPath: URL?
    }

    // MARK: - Flutter Platform

    struct Flutter: Decodable {
        /// Legacy single colors configuration.
        struct ColorsLegacy: Decodable {
            let output: String?
            let className: String?
        }

        /// Colors configuration supporting both legacy and multi-entry formats.
        enum ColorsConfiguration: Decodable {
            case legacy(ColorsLegacy)
            case multiple([FlutterColorsEntry])

            init(from decoder: Decoder) throws {
                if let array = try? [FlutterColorsEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let legacy = try ColorsLegacy(from: decoder)
                self = .legacy(legacy)
            }

            var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        /// Legacy single icons configuration.
        struct IconsLegacy: Decodable {
            let output: String
            let dartFile: String?
            let className: String?
        }

        /// Icons configuration supporting both legacy and multi-entry formats.
        enum IconsConfiguration: Decodable {
            case legacy(IconsLegacy)
            case multiple([FlutterIconsEntry])

            init(from decoder: Decoder) throws {
                if let array = try? [FlutterIconsEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let legacy = try IconsLegacy(from: decoder)
                self = .legacy(legacy)
            }

            var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        enum ImageFormat: String, Decodable {
            case svg
            case png
            case webp
        }

        struct WebpOptions: Decodable {
            enum Encoding: String, Decodable {
                case lossy
                case lossless
            }

            let encoding: Encoding
            let quality: Int?
        }

        /// Legacy single images configuration.
        struct ImagesLegacy: Decodable {
            let output: String
            let dartFile: String?
            let className: String?
            let scales: [Double]?
            let format: ImageFormat?
            let webpOptions: Android.WebpOptions?
            let sourceFormat: SourceFormat?
            let nameStyle: NameStyle?
        }

        /// Images configuration supporting both legacy and multi-entry formats.
        enum ImagesConfiguration: Decodable {
            case legacy(ImagesLegacy)
            case multiple([FlutterImagesEntry])

            init(from decoder: Decoder) throws {
                if let array = try? [FlutterImagesEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let legacy = try ImagesLegacy(from: decoder)
                self = .legacy(legacy)
            }

            var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        let output: URL
        let templatesPath: URL?

        let colors: ColorsConfiguration?
        let icons: IconsConfiguration?
        let images: ImagesConfiguration?
    }

    // MARK: - Web Platform

    struct Web: Decodable {
        /// Legacy single colors configuration.
        struct ColorsLegacy: Decodable {
            let outputDirectory: String?
            let cssFileName: String?
            let tsFileName: String?
            let jsonFileName: String?
        }

        /// Colors configuration supporting both legacy and multi-entry formats.
        enum ColorsConfiguration: Decodable {
            case legacy(ColorsLegacy)
            case multiple([WebColorsEntry])

            init(from decoder: Decoder) throws {
                if let array = try? [WebColorsEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let legacy = try ColorsLegacy(from: decoder)
                self = .legacy(legacy)
            }

            var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        /// Legacy single icons configuration.
        struct IconsLegacy: Decodable {
            let outputDirectory: String
            let svgDirectory: String?
            let generateReactComponents: Bool?
            let iconSize: Int?
        }

        /// Icons configuration supporting both legacy and multi-entry formats.
        enum IconsConfiguration: Decodable {
            case legacy(IconsLegacy)
            case multiple([WebIconsEntry])

            init(from decoder: Decoder) throws {
                if let array = try? [WebIconsEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let legacy = try IconsLegacy(from: decoder)
                self = .legacy(legacy)
            }

            var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        /// Legacy single images configuration.
        struct ImagesLegacy: Decodable {
            let outputDirectory: String
            let assetsDirectory: String?
            let generateReactComponents: Bool?
        }

        /// Images configuration supporting both legacy and multi-entry formats.
        enum ImagesConfiguration: Decodable {
            case legacy(ImagesLegacy)
            case multiple([WebImagesEntry])

            init(from decoder: Decoder) throws {
                if let array = try? [WebImagesEntry](from: decoder) {
                    self = .multiple(array)
                    return
                }
                let legacy = try ImagesLegacy(from: decoder)
                self = .legacy(legacy)
            }

            var isMultiple: Bool {
                if case .multiple = self { return true }
                return false
            }
        }

        let output: URL
        let templatesPath: URL?

        let colors: ColorsConfiguration?
        let icons: IconsConfiguration?
        let images: ImagesConfiguration?
    }

    // MARK: - Root Properties

    let figma: Figma?
    let common: Common?
    let ios: iOS?
    let android: Android?
    let flutter: Flutter?
    let web: Web?
}

// swiftlint:enable nesting type_name type_body_length file_length
