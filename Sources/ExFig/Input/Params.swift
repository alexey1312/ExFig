import ExFigCore
import Foundation

/// Options for image optimization via image_optim
struct OptimizeOptions: Decodable {
    /// Allow lossy compression (pngquant, mozjpeg). Default: false (lossless only).
    let allowLossy: Bool?
}

// swiftlint:disable:this nesting type_name
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
        struct Colors: Decodable {
            let useColorAssets: Bool
            let assetsFolder: String?
            let nameStyle: NameStyle
            let groupUsingNamespace: Bool?

            let colorSwift: URL?
            let swiftuiColorSwift: URL?
        }

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

        struct Images: Decodable {
            let assetsFolder: String
            let nameStyle: NameStyle
            let scales: [Double]?

            let imageSwift: URL?
            let swiftUIImageSwift: URL?

            /// Enable image optimization via image_optim
            let optimize: Bool?
            /// Options for image optimization
            let optimizeOptions: OptimizeOptions?
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

        let colors: Colors?
        let icons: Icons?
        let images: Images?
        let typography: Typography?
    }

    struct Android: Decodable {
        enum ComposeIconFormat: String, Decodable {
            /// Generates extension functions that use `painterResource(R.drawable.xxx)`
            case resourceReference
            /// Generates ImageVector code directly from SVG data
            case imageVector
        }

        struct Icons: Decodable {
            let output: String
            let composePackageName: String?
            let composeFormat: ComposeIconFormat?
            /// Extension target for ImageVector (e.g., "com.example.app.ui.AppIcons")
            let composeExtensionTarget: String?
        }

        struct Colors: Decodable {
            let xmlOutputFileName: String?
            let composePackageName: String?
        }

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

            /// Enable image optimization via image_optim
            let optimize: Bool?
            /// Options for image optimization
            let optimizeOptions: OptimizeOptions?
        }

        struct Typography: Decodable {
            let nameStyle: NameStyle
            let composePackageName: String?
        }

        let mainRes: URL
        let resourcePackage: String?
        let mainSrc: URL?
        let colors: Colors?
        let icons: Icons?
        let images: Images?
        let typography: Typography?
        let templatesPath: URL?
    }

    struct Flutter: Decodable {
        enum ImageFormat: String, Decodable {
            case svg
            case png
            case webp
        }

        struct Colors: Decodable {
            let output: String?
            let className: String?
        }

        struct Icons: Decodable {
            let output: String
            let dartFile: String?
            let className: String?
        }

        struct Images: Decodable {
            let output: String
            let dartFile: String?
            let className: String?
            let scales: [Double]?
            let format: ImageFormat?
            let webpOptions: Android.Images.FormatOptions?

            /// Enable image optimization via image_optim
            let optimize: Bool?
            /// Options for image optimization
            let optimizeOptions: OptimizeOptions?
        }

        let output: URL
        let colors: Colors?
        let icons: Icons?
        let images: Images?
        let templatesPath: URL?
    }

    let figma: Figma
    let common: Common?
    let ios: iOS?
    let android: Android?
    let flutter: Flutter?
}
