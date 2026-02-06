// swiftlint:disable file_length

import ExFig_Android
import ExFig_Flutter
import ExFig_iOS
import ExFig_Web
import ExFigCore
import Foundation
import Logging

// MARK: - iOS Colors

extension PKLConfig.iOS.ColorsConfiguration {
    /// Returns plugin entries. For legacy format, source fields are empty (use common.variablesColors).
    var entries: [iOSColorsEntry] {
        switch self {
        case let .legacy(colors):
            [iOSColorsEntry(
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
                swiftuiColorSwift: colors.swiftuiColorSwift,
                syncCodeSyntax: colors.syncCodeSyntax,
                codeSyntaxTemplate: colors.codeSyntaxTemplate
            )]
        case let .multiple(entries):
            entries
        }
    }

    /// Converts to plugin entries, merging common.variablesColors for legacy format.
    func toPluginEntries(common: PKLConfig.Common?) -> [iOSColorsEntry] {
        switch self {
        case let .legacy(colors):
            guard let variablesColors = common?.variablesColors else {
                ExFigCommand.logger.warning("No variablesColors configuration found for iOS colors")
                return []
            }
            return [iOSColorsEntry(
                tokensFileId: variablesColors.tokensFileId,
                tokensCollectionName: variablesColors.tokensCollectionName,
                lightModeName: variablesColors.lightModeName,
                darkModeName: variablesColors.darkModeName,
                lightHCModeName: variablesColors.lightHCModeName,
                darkHCModeName: variablesColors.darkHCModeName,
                primitivesModeName: variablesColors.primitivesModeName,
                nameValidateRegexp: variablesColors.nameValidateRegexp,
                nameReplaceRegexp: variablesColors.nameReplaceRegexp,
                useColorAssets: colors.useColorAssets,
                assetsFolder: colors.assetsFolder,
                nameStyle: colors.nameStyle,
                groupUsingNamespace: colors.groupUsingNamespace,
                colorSwift: colors.colorSwift,
                swiftuiColorSwift: colors.swiftuiColorSwift,
                syncCodeSyntax: colors.syncCodeSyntax,
                codeSyntaxTemplate: colors.codeSyntaxTemplate
            )]
        case let .multiple(entries):
            return entries
        }
    }
}

// MARK: - iOS Icons

extension PKLConfig.iOS.IconsConfiguration {
    /// Returns plugin entries. For legacy format, source fields are nil.
    var entries: [iOSIconsEntry] {
        switch self {
        case let .legacy(icons):
            [iOSIconsEntry(
                figmaFrameName: nil,
                format: icons.format,
                nameValidateRegexp: nil,
                nameReplaceRegexp: nil,
                nameStyle: icons.nameStyle,
                assetsFolder: icons.assetsFolder,
                preservesVectorRepresentation: icons.preservesVectorRepresentation,
                imageSwift: icons.imageSwift,
                swiftUIImageSwift: icons.swiftUIImageSwift,
                codeConnectSwift: icons.codeConnectSwift,
                renderMode: icons.renderMode,
                renderModeDefaultSuffix: icons.renderModeDefaultSuffix,
                renderModeOriginalSuffix: icons.renderModeOriginalSuffix,
                renderModeTemplateSuffix: icons.renderModeTemplateSuffix
            )]
        case let .multiple(entries):
            entries
        }
    }

    /// Converts to plugin entries, merging common.icons fields for legacy format.
    func toPluginEntries(common: PKLConfig.Common?) -> [iOSIconsEntry] {
        switch self {
        case let .legacy(icons):
            [iOSIconsEntry(
                figmaFrameName: common?.icons?.figmaFrameName,
                format: icons.format,
                nameValidateRegexp: common?.icons?.nameValidateRegexp,
                nameReplaceRegexp: common?.icons?.nameReplaceRegexp,
                nameStyle: icons.nameStyle,
                assetsFolder: icons.assetsFolder,
                preservesVectorRepresentation: icons.preservesVectorRepresentation,
                imageSwift: icons.imageSwift,
                swiftUIImageSwift: icons.swiftUIImageSwift,
                codeConnectSwift: icons.codeConnectSwift,
                renderMode: icons.renderMode,
                renderModeDefaultSuffix: icons.renderModeDefaultSuffix,
                renderModeOriginalSuffix: icons.renderModeOriginalSuffix,
                renderModeTemplateSuffix: icons.renderModeTemplateSuffix
            )]
        case let .multiple(entries):
            entries
        }
    }
}

// MARK: - iOS Images

extension PKLConfig.iOS.ImagesConfiguration {
    /// Returns plugin entries. For legacy format, source fields are nil.
    var entries: [iOSImagesEntry] {
        switch self {
        case let .legacy(images):
            [iOSImagesEntry(
                figmaFrameName: nil,
                sourceFormat: nil,
                scales: images.scales,
                nameValidateRegexp: nil,
                nameReplaceRegexp: nil,
                nameStyle: images.nameStyle,
                assetsFolder: images.assetsFolder,
                outputFormat: nil,
                heicOptions: nil,
                imageSwift: images.imageSwift,
                swiftUIImageSwift: images.swiftUIImageSwift,
                codeConnectSwift: images.codeConnectSwift,
                renderMode: images.renderMode,
                renderModeDefaultSuffix: images.renderModeDefaultSuffix,
                renderModeOriginalSuffix: images.renderModeOriginalSuffix,
                renderModeTemplateSuffix: images.renderModeTemplateSuffix
            )]
        case let .multiple(entries):
            entries
        }
    }

    /// Converts to plugin entries, merging common.images fields for legacy format.
    func toPluginEntries(common: PKLConfig.Common?) -> [iOSImagesEntry] {
        switch self {
        case let .legacy(images):
            [iOSImagesEntry(
                figmaFrameName: common?.images?.figmaFrameName,
                sourceFormat: nil,
                scales: images.scales,
                nameValidateRegexp: common?.images?.nameValidateRegexp,
                nameReplaceRegexp: common?.images?.nameReplaceRegexp,
                nameStyle: images.nameStyle,
                assetsFolder: images.assetsFolder,
                outputFormat: nil,
                heicOptions: nil,
                imageSwift: images.imageSwift,
                swiftUIImageSwift: images.swiftUIImageSwift,
                codeConnectSwift: images.codeConnectSwift,
                renderMode: images.renderMode,
                renderModeDefaultSuffix: images.renderModeDefaultSuffix,
                renderModeOriginalSuffix: images.renderModeOriginalSuffix,
                renderModeTemplateSuffix: images.renderModeTemplateSuffix
            )]
        case let .multiple(entries):
            entries
        }
    }
}

// MARK: - Android Colors

extension PKLConfig.Android.ColorsConfiguration {
    /// Returns plugin entries. For legacy format, source fields are empty.
    var entries: [AndroidColorsEntry] {
        switch self {
        case let .legacy(colors):
            [AndroidColorsEntry(
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
                xmlDisabled: colors.xmlDisabled,
                composePackageName: colors.composePackageName,
                colorKotlin: colors.colorKotlin,
                themeAttributes: colors.themeAttributes
            )]
        case let .multiple(entries):
            entries
        }
    }

    /// Converts to plugin entries, merging common.variablesColors for legacy format.
    func toPluginEntries(common: PKLConfig.Common?) -> [AndroidColorsEntry] {
        switch self {
        case let .legacy(colors):
            guard let variablesColors = common?.variablesColors else {
                ExFigCommand.logger.warning("No variablesColors configuration found for Android colors")
                return []
            }
            return [AndroidColorsEntry(
                tokensFileId: variablesColors.tokensFileId,
                tokensCollectionName: variablesColors.tokensCollectionName,
                lightModeName: variablesColors.lightModeName,
                darkModeName: variablesColors.darkModeName,
                lightHCModeName: variablesColors.lightHCModeName,
                darkHCModeName: variablesColors.darkHCModeName,
                primitivesModeName: variablesColors.primitivesModeName,
                nameValidateRegexp: variablesColors.nameValidateRegexp,
                nameReplaceRegexp: variablesColors.nameReplaceRegexp,
                xmlOutputFileName: colors.xmlOutputFileName,
                xmlDisabled: colors.xmlDisabled,
                composePackageName: colors.composePackageName,
                colorKotlin: colors.colorKotlin,
                themeAttributes: colors.themeAttributes
            )]
        case let .multiple(entries):
            return entries
        }
    }
}

// MARK: - Android Icons

extension PKLConfig.Android.IconsConfiguration {
    /// Returns plugin entries. For legacy format, source fields are nil.
    var entries: [AndroidIconsEntry] {
        switch self {
        case let .legacy(icons):
            [AndroidIconsEntry(
                figmaFrameName: nil,
                nameValidateRegexp: nil,
                nameReplaceRegexp: nil,
                nameStyle: nil,
                output: icons.output,
                composePackageName: icons.composePackageName,
                composeFormat: icons.composeFormat,
                composeExtensionTarget: icons.composeExtensionTarget,
                pathPrecision: icons.pathPrecision,
                strictPathValidation: icons.strictPathValidation
            )]
        case let .multiple(entries):
            entries
        }
    }

    /// Converts to plugin entries, merging common.icons fields for legacy format.
    func toPluginEntries(common: PKLConfig.Common?) -> [AndroidIconsEntry] {
        switch self {
        case let .legacy(icons):
            [AndroidIconsEntry(
                figmaFrameName: common?.icons?.figmaFrameName,
                nameValidateRegexp: common?.icons?.nameValidateRegexp,
                nameReplaceRegexp: common?.icons?.nameReplaceRegexp,
                nameStyle: nil,
                output: icons.output,
                composePackageName: icons.composePackageName,
                composeFormat: icons.composeFormat,
                composeExtensionTarget: icons.composeExtensionTarget,
                pathPrecision: icons.pathPrecision,
                strictPathValidation: icons.strictPathValidation
            )]
        case let .multiple(entries):
            entries
        }
    }
}

// MARK: - Android Images

extension PKLConfig.Android.ImagesConfiguration {
    /// Returns plugin entries. For legacy format, source fields are nil.
    var entries: [AndroidImagesEntry] {
        switch self {
        case let .legacy(images):
            [AndroidImagesEntry(
                figmaFrameName: nil,
                sourceFormat: images.sourceFormat
                    .map { convertEnum($0.rawValue, default: ExFigCore.ImageSourceFormat.png) },
                scales: images.scales,
                nameValidateRegexp: nil,
                nameReplaceRegexp: nil,
                nameStyle: nil,
                output: images.output,
                format: convertEnum(images.format.rawValue, default: ExFig_Android.AndroidImageFormat.png),
                webpOptions: images.webpOptions.map {
                    ExFig_Android.WebpOptions(lossless: $0.encoding == .lossless, quality: $0.quality)
                }
            )]
        case let .multiple(entries):
            entries
        }
    }

    /// Converts to plugin entries, merging common.images fields for legacy format.
    func toPluginEntries(common: PKLConfig.Common?) -> [AndroidImagesEntry] {
        switch self {
        case let .legacy(images):
            [AndroidImagesEntry(
                figmaFrameName: common?.images?.figmaFrameName,
                sourceFormat: images.sourceFormat
                    .map { convertEnum($0.rawValue, default: ExFigCore.ImageSourceFormat.png) },
                scales: images.scales,
                nameValidateRegexp: common?.images?.nameValidateRegexp,
                nameReplaceRegexp: common?.images?.nameReplaceRegexp,
                nameStyle: nil,
                output: images.output,
                format: convertEnum(images.format.rawValue, default: ExFig_Android.AndroidImageFormat.png),
                webpOptions: images.webpOptions.map {
                    ExFig_Android.WebpOptions(lossless: $0.encoding == .lossless, quality: $0.quality)
                }
            )]
        case let .multiple(entries):
            entries
        }
    }
}

// MARK: - Flutter Colors

extension PKLConfig.Flutter.ColorsConfiguration {
    /// Returns plugin entries. For legacy format, source fields are empty.
    var entries: [FlutterColorsEntry] {
        switch self {
        case let .legacy(colors):
            [FlutterColorsEntry(
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

    /// Converts to plugin entries, merging common.variablesColors for legacy format.
    func toPluginEntries(common: PKLConfig.Common?) -> [FlutterColorsEntry] {
        switch self {
        case let .legacy(colors):
            guard let variablesColors = common?.variablesColors else {
                ExFigCommand.logger.warning("No variablesColors configuration found for Flutter colors")
                return []
            }
            return [FlutterColorsEntry(
                tokensFileId: variablesColors.tokensFileId,
                tokensCollectionName: variablesColors.tokensCollectionName,
                lightModeName: variablesColors.lightModeName,
                darkModeName: variablesColors.darkModeName,
                lightHCModeName: variablesColors.lightHCModeName,
                darkHCModeName: variablesColors.darkHCModeName,
                primitivesModeName: variablesColors.primitivesModeName,
                nameValidateRegexp: variablesColors.nameValidateRegexp,
                nameReplaceRegexp: variablesColors.nameReplaceRegexp,
                output: colors.output,
                className: colors.className
            )]
        case let .multiple(entries):
            return entries
        }
    }
}

// MARK: - Flutter Icons

extension PKLConfig.Flutter.IconsConfiguration {
    /// Returns plugin entries. For legacy format, source fields are nil.
    var entries: [FlutterIconsEntry] {
        switch self {
        case let .legacy(icons):
            [FlutterIconsEntry(
                figmaFrameName: nil,
                nameValidateRegexp: nil,
                nameReplaceRegexp: nil,
                nameStyle: nil,
                output: icons.output,
                dartFile: icons.dartFile,
                className: icons.className
            )]
        case let .multiple(entries):
            entries
        }
    }

    /// Converts to plugin entries, merging common.icons fields for legacy format.
    func toPluginEntries(common: PKLConfig.Common?) -> [FlutterIconsEntry] {
        switch self {
        case let .legacy(icons):
            [FlutterIconsEntry(
                figmaFrameName: common?.icons?.figmaFrameName,
                nameValidateRegexp: common?.icons?.nameValidateRegexp,
                nameReplaceRegexp: common?.icons?.nameReplaceRegexp,
                nameStyle: nil,
                output: icons.output,
                dartFile: icons.dartFile,
                className: icons.className
            )]
        case let .multiple(entries):
            entries
        }
    }
}

// MARK: - Flutter Images

extension PKLConfig.Flutter.ImagesConfiguration {
    /// Returns plugin entries. For legacy format, source fields are nil.
    var entries: [FlutterImagesEntry] {
        switch self {
        case let .legacy(images):
            [FlutterImagesEntry(
                figmaFrameName: nil,
                sourceFormat: images.sourceFormat
                    .map { convertEnum($0.rawValue, default: ExFigCore.ImageSourceFormat.png) },
                scales: images.scales,
                nameValidateRegexp: nil,
                nameReplaceRegexp: nil,
                nameStyle: images.nameStyle,
                output: images.output,
                dartFile: images.dartFile,
                className: images.className,
                format: images.format
                    .map { convertEnum($0.rawValue, default: ExFig_Flutter.FlutterImageFormat.png) },
                webpOptions: images.webpOptions.map {
                    ExFig_Flutter.WebpOptions(lossless: $0.encoding == .lossless, quality: $0.quality)
                }
            )]
        case let .multiple(entries):
            entries
        }
    }

    /// Converts to plugin entries, merging common.images fields for legacy format.
    func toPluginEntries(common: PKLConfig.Common?) -> [FlutterImagesEntry] {
        switch self {
        case let .legacy(images):
            [FlutterImagesEntry(
                figmaFrameName: common?.images?.figmaFrameName,
                sourceFormat: images.sourceFormat
                    .map { convertEnum($0.rawValue, default: ExFigCore.ImageSourceFormat.png) },
                scales: images.scales,
                nameValidateRegexp: common?.images?.nameValidateRegexp,
                nameReplaceRegexp: common?.images?.nameReplaceRegexp,
                nameStyle: images.nameStyle,
                output: images.output,
                dartFile: images.dartFile,
                className: images.className,
                format: images.format
                    .map { convertEnum($0.rawValue, default: ExFig_Flutter.FlutterImageFormat.png) },
                webpOptions: images.webpOptions.map {
                    ExFig_Flutter.WebpOptions(lossless: $0.encoding == .lossless, quality: $0.quality)
                }
            )]
        case let .multiple(entries):
            entries
        }
    }
}

// MARK: - Web Colors

extension PKLConfig.Web.ColorsConfiguration {
    /// Returns plugin entries. For legacy format, source fields are empty.
    var entries: [WebColorsEntry] {
        switch self {
        case let .legacy(colors):
            [WebColorsEntry(
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

    /// Converts to plugin entries, merging common.variablesColors for legacy format.
    func toPluginEntries(common: PKLConfig.Common?) -> [WebColorsEntry] {
        switch self {
        case let .legacy(colors):
            guard let variablesColors = common?.variablesColors else {
                ExFigCommand.logger.warning("No variablesColors configuration found for Web colors")
                return []
            }
            return [WebColorsEntry(
                tokensFileId: variablesColors.tokensFileId,
                tokensCollectionName: variablesColors.tokensCollectionName,
                lightModeName: variablesColors.lightModeName,
                darkModeName: variablesColors.darkModeName,
                lightHCModeName: variablesColors.lightHCModeName,
                darkHCModeName: variablesColors.darkHCModeName,
                primitivesModeName: variablesColors.primitivesModeName,
                nameValidateRegexp: variablesColors.nameValidateRegexp,
                nameReplaceRegexp: variablesColors.nameReplaceRegexp,
                outputDirectory: colors.outputDirectory,
                cssFileName: colors.cssFileName,
                tsFileName: colors.tsFileName,
                jsonFileName: colors.jsonFileName
            )]
        case let .multiple(entries):
            return entries
        }
    }
}

// MARK: - Web Icons

extension PKLConfig.Web.IconsConfiguration {
    /// Returns plugin entries. For legacy format, source fields are nil.
    var entries: [WebIconsEntry] {
        switch self {
        case let .legacy(icons):
            [WebIconsEntry(
                figmaFrameName: nil,
                nameValidateRegexp: nil,
                nameReplaceRegexp: nil,
                nameStyle: nil,
                outputDirectory: icons.outputDirectory,
                svgDirectory: icons.svgDirectory,
                generateReactComponents: icons.generateReactComponents,
                iconSize: icons.iconSize
            )]
        case let .multiple(entries):
            entries
        }
    }

    /// Converts to plugin entries, merging common.icons fields for legacy format.
    func toPluginEntries(common: PKLConfig.Common?) -> [WebIconsEntry] {
        switch self {
        case let .legacy(icons):
            [WebIconsEntry(
                figmaFrameName: common?.icons?.figmaFrameName,
                nameValidateRegexp: common?.icons?.nameValidateRegexp,
                nameReplaceRegexp: common?.icons?.nameReplaceRegexp,
                nameStyle: nil,
                outputDirectory: icons.outputDirectory,
                svgDirectory: icons.svgDirectory,
                generateReactComponents: icons.generateReactComponents,
                iconSize: icons.iconSize
            )]
        case let .multiple(entries):
            entries
        }
    }
}

// MARK: - Web Images

extension PKLConfig.Web.ImagesConfiguration {
    /// Returns plugin entries. For legacy format, source fields are nil.
    var entries: [WebImagesEntry] {
        switch self {
        case let .legacy(images):
            [WebImagesEntry(
                figmaFrameName: nil,
                nameValidateRegexp: nil,
                nameReplaceRegexp: nil,
                nameStyle: nil,
                outputDirectory: images.outputDirectory,
                assetsDirectory: images.assetsDirectory,
                generateReactComponents: images.generateReactComponents
            )]
        case let .multiple(entries):
            entries
        }
    }

    /// Converts to plugin entries, merging common.images fields for legacy format.
    func toPluginEntries(common: PKLConfig.Common?) -> [WebImagesEntry] {
        switch self {
        case let .legacy(images):
            [WebImagesEntry(
                figmaFrameName: common?.images?.figmaFrameName,
                nameValidateRegexp: common?.images?.nameValidateRegexp,
                nameReplaceRegexp: common?.images?.nameReplaceRegexp,
                nameStyle: nil,
                outputDirectory: images.outputDirectory,
                assetsDirectory: images.assetsDirectory,
                generateReactComponents: images.generateReactComponents
            )]
        case let .multiple(entries):
            entries
        }
    }
}

// MARK: - Typography

extension iOSTypographyEntry {
    /// Creates an iOSTypographyEntry from PKLConfig, merging common typography fields.
    static func fromLegacy(
        _ entry: iOSTypographyEntry,
        common: PKLConfig.Common?
    ) -> iOSTypographyEntry {
        iOSTypographyEntry(
            fileId: entry.fileId,
            nameValidateRegexp: entry.nameValidateRegexp ?? common?.typography?.nameValidateRegexp,
            nameReplaceRegexp: entry.nameReplaceRegexp ?? common?.typography?.nameReplaceRegexp,
            nameStyle: entry.nameStyle,
            fontSwift: entry.fontSwift,
            swiftUIFontSwift: entry.swiftUIFontSwift,
            generateLabels: entry.generateLabels,
            labelsDirectory: entry.labelsDirectory,
            labelStyleSwift: entry.labelStyleSwift
        )
    }
}

extension AndroidTypographyEntry {
    /// Creates an AndroidTypographyEntry from PKLConfig, merging common typography fields.
    static func fromLegacy(
        _ entry: AndroidTypographyEntry,
        common: PKLConfig.Common?
    ) -> AndroidTypographyEntry {
        AndroidTypographyEntry(
            fileId: entry.fileId,
            nameValidateRegexp: entry.nameValidateRegexp ?? common?.typography?.nameValidateRegexp,
            nameReplaceRegexp: entry.nameReplaceRegexp ?? common?.typography?.nameReplaceRegexp,
            nameStyle: entry.nameStyle,
            composePackageName: entry.composePackageName
        )
    }
}

// MARK: - Helpers

private func convertEnum<T: RawRepresentable>(
    _ rawValue: String, default fallback: T
) -> T where T.RawValue == String {
    guard let value = T(rawValue: rawValue) else {
        ExFigCommand.logger.warning("Unknown \(T.self) value '\(rawValue)', defaulting to '\(fallback.rawValue)'")
        return fallback
    }
    return value
}

// swiftlint:enable file_length
