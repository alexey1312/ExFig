// swiftlint:disable file_length

import ExFig_Android
import ExFig_Flutter
import ExFig_iOS
import ExFig_Web
import ExFigCore
import Foundation

// MARK: - iOS Adapters

extension Params.iOS {
    /// Creates iOSPlatformConfig from Params.iOS.
    func platformConfig() -> iOSPlatformConfig {
        iOSPlatformConfig(
            xcodeprojPath: xcodeprojPath,
            target: target,
            xcassetsPath: xcassetsPath,
            xcassetsInMainBundle: xcassetsInMainBundle,
            xcassetsInSwiftPackage: xcassetsInSwiftPackage,
            resourceBundleNames: resourceBundleNames,
            addObjcAttribute: addObjcAttribute,
            templatesPath: templatesPath
        )
    }
}

extension Params.iOS.ColorsEntry {
    /// Converts Params.iOS.ColorsEntry to iOSColorsEntry.
    func toPluginEntry() -> iOSColorsEntry {
        iOSColorsEntry(
            tokensFileId: tokensFileId,
            tokensCollectionName: tokensCollectionName,
            lightModeName: lightModeName,
            darkModeName: darkModeName,
            lightHCModeName: lightHCModeName,
            darkHCModeName: darkHCModeName,
            primitivesModeName: primitivesModeName,
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp,
            useColorAssets: useColorAssets,
            assetsFolder: assetsFolder,
            nameStyle: nameStyle,
            groupUsingNamespace: groupUsingNamespace,
            colorSwift: colorSwift,
            swiftuiColorSwift: swiftuiColorSwift,
            syncCodeSyntax: syncCodeSyntax,
            codeSyntaxTemplate: codeSyntaxTemplate
        )
    }
}

extension Params.iOS.IconsEntry {
    /// Converts Params.iOS.IconsEntry to iOSIconsEntry.
    func toPluginEntry() -> iOSIconsEntry {
        iOSIconsEntry(
            figmaFrameName: figmaFrameName,
            format: ExFigCore.VectorFormat(rawValue: format.rawValue) ?? .svg,
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp,
            nameStyle: nameStyle,
            assetsFolder: assetsFolder,
            preservesVectorRepresentation: preservesVectorRepresentation,
            imageSwift: imageSwift,
            swiftUIImageSwift: swiftUIImageSwift,
            codeConnectSwift: codeConnectSwift,
            renderMode: renderMode,
            renderModeDefaultSuffix: renderModeDefaultSuffix,
            renderModeOriginalSuffix: renderModeOriginalSuffix,
            renderModeTemplateSuffix: renderModeTemplateSuffix
        )
    }
}

extension Params.iOS.IconsConfiguration {
    /// Converts legacy format entries to plugin entries.
    func toPluginEntries(common: Params.Common?) -> [iOSIconsEntry] {
        switch self {
        case let .single(icons):
            [Params.iOS.IconsEntry(
                figmaFrameName: common?.icons?.figmaFrameName,
                format: icons.format,
                assetsFolder: icons.assetsFolder,
                preservesVectorRepresentation: icons.preservesVectorRepresentation,
                nameStyle: icons.nameStyle,
                nameValidateRegexp: common?.icons?.nameValidateRegexp,
                nameReplaceRegexp: common?.icons?.nameReplaceRegexp,
                imageSwift: icons.imageSwift,
                swiftUIImageSwift: icons.swiftUIImageSwift,
                codeConnectSwift: icons.codeConnectSwift,
                renderMode: icons.renderMode,
                renderModeDefaultSuffix: icons.renderModeDefaultSuffix,
                renderModeOriginalSuffix: icons.renderModeOriginalSuffix,
                renderModeTemplateSuffix: icons.renderModeTemplateSuffix
            ).toPluginEntry()]
        case let .multiple(entries):
            entries.map { $0.toPluginEntry() }
        }
    }
}

extension Params.iOS.ColorsConfiguration {
    /// Converts legacy format entries to plugin entries.
    ///
    /// For legacy format (.single), merges common.variablesColors into entries.
    /// For multiple format, converts directly.
    func toPluginEntries(common: Params.Common?) -> [iOSColorsEntry] {
        switch self {
        case let .single(colors):
            // Legacy format: source comes from common.variablesColors
            guard let variablesColors = common?.variablesColors else {
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
            return entries.map { $0.toPluginEntry() }
        }
    }
}

extension Params.iOS.ImagesEntry {
    /// Converts Params.iOS.ImagesEntry to iOSImagesEntry.
    func toPluginEntry(common: Params.Common?) -> iOSImagesEntry {
        iOSImagesEntry(
            figmaFrameName: figmaFrameName ?? common?.images?.figmaFrameName,
            sourceFormat: sourceFormat.map { ExFigCore.ImageSourceFormat(rawValue: $0.rawValue) ?? .png },
            scales: scales,
            nameValidateRegexp: common?.images?.nameValidateRegexp,
            nameReplaceRegexp: common?.images?.nameReplaceRegexp,
            nameStyle: nameStyle,
            assetsFolder: assetsFolder,
            outputFormat: outputFormat.map { ExFigCore.ImageOutputFormat(rawValue: $0.rawValue) ?? .png },
            heicOptions: heicOptions.map { ExFig_iOS.HeicOptions(quality: $0.quality.map { Double($0) }) },
            imageSwift: imageSwift,
            swiftUIImageSwift: swiftUIImageSwift,
            codeConnectSwift: codeConnectSwift,
            renderMode: renderMode,
            renderModeDefaultSuffix: renderModeDefaultSuffix,
            renderModeOriginalSuffix: renderModeOriginalSuffix,
            renderModeTemplateSuffix: renderModeTemplateSuffix
        )
    }
}

extension Params.iOS.ImagesConfiguration {
    /// Converts legacy format entries to plugin entries.
    func toPluginEntries(common: Params.Common?) -> [iOSImagesEntry] {
        switch self {
        case let .single(images):
            [Params.iOS.ImagesEntry(
                figmaFrameName: common?.images?.figmaFrameName,
                assetsFolder: images.assetsFolder,
                nameStyle: images.nameStyle,
                scales: images.scales,
                imageSwift: images.imageSwift,
                swiftUIImageSwift: images.swiftUIImageSwift,
                codeConnectSwift: images.codeConnectSwift,
                sourceFormat: nil,
                outputFormat: nil,
                heicOptions: nil,
                renderMode: images.renderMode,
                renderModeDefaultSuffix: images.renderModeDefaultSuffix,
                renderModeOriginalSuffix: images.renderModeOriginalSuffix,
                renderModeTemplateSuffix: images.renderModeTemplateSuffix
            ).toPluginEntry(common: common)]
        case let .multiple(entries):
            entries.map { $0.toPluginEntry(common: common) }
        }
    }
}

// MARK: - Android Adapters

extension Params.Android {
    /// Creates AndroidPlatformConfig from Params.Android.
    func platformConfig() -> AndroidPlatformConfig {
        AndroidPlatformConfig(
            mainRes: mainRes,
            resourcePackage: resourcePackage,
            mainSrc: mainSrc,
            templatesPath: templatesPath
        )
    }
}

extension Params.Android.IconsEntry {
    /// Converts Params.Android.IconsEntry to AndroidIconsEntry.
    func toPluginEntry() -> AndroidIconsEntry {
        AndroidIconsEntry(
            figmaFrameName: figmaFrameName,
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp,
            nameStyle: nameStyle,
            output: output,
            composePackageName: composePackageName,
            composeFormat: composeFormat
                .map { ExFig_Android.ComposeIconFormat(rawValue: $0.rawValue) ?? .resourceReference },
            composeExtensionTarget: composeExtensionTarget,
            pathPrecision: pathPrecision,
            strictPathValidation: strictPathValidation
        )
    }
}

extension Params.Android.IconsConfiguration {
    /// Converts legacy format entries to plugin entries.
    func toPluginEntries(common: Params.Common?) -> [AndroidIconsEntry] {
        switch self {
        case let .single(icons):
            [Params.Android.IconsEntry(
                figmaFrameName: common?.icons?.figmaFrameName,
                output: icons.output,
                composePackageName: icons.composePackageName,
                composeFormat: icons.composeFormat,
                composeExtensionTarget: icons.composeExtensionTarget,
                nameStyle: nil,
                nameValidateRegexp: common?.icons?.nameValidateRegexp,
                nameReplaceRegexp: common?.icons?.nameReplaceRegexp,
                pathPrecision: icons.pathPrecision,
                strictPathValidation: icons.strictPathValidation
            ).toPluginEntry()]
        case let .multiple(entries):
            entries.map { $0.toPluginEntry() }
        }
    }
}

extension Params.Android.ColorsEntry {
    /// Converts Params.Android.ColorsEntry to AndroidColorsEntry.
    func toPluginEntry() -> AndroidColorsEntry {
        AndroidColorsEntry(
            tokensFileId: tokensFileId,
            tokensCollectionName: tokensCollectionName,
            lightModeName: lightModeName,
            darkModeName: darkModeName,
            lightHCModeName: lightHCModeName,
            darkHCModeName: darkHCModeName,
            primitivesModeName: primitivesModeName,
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp,
            xmlOutputFileName: xmlOutputFileName,
            xmlDisabled: xmlDisabled,
            composePackageName: composePackageName,
            colorKotlin: colorKotlin,
            themeAttributes: themeAttributes?.toPluginThemeAttributes()
        )
    }
}

extension Params.Android.ThemeAttributes {
    /// Converts Params.Android.ThemeAttributes to plugin ThemeAttributes.
    func toPluginThemeAttributes() -> ExFig_Android.ThemeAttributes {
        ExFig_Android.ThemeAttributes(
            enabled: enabled,
            attrsFile: attrsFile,
            stylesFile: stylesFile,
            stylesNightFile: stylesNightFile,
            themeName: themeName,
            markerStart: markerStart,
            markerEnd: markerEnd,
            nameTransform: nameTransform?.toPluginNameTransform(),
            autoCreateMarkers: autoCreateMarkers
        )
    }
}

extension Params.Android.ThemeAttributes.NameTransform {
    /// Converts Params name transform to plugin NameTransform.
    func toPluginNameTransform() -> ExFig_Android.NameTransform {
        ExFig_Android.NameTransform(
            prefix: prefix,
            suffix: nil
        )
    }
}

extension Params.Android.ColorsConfiguration {
    /// Converts legacy format entries to plugin entries.
    func toPluginEntries(common: Params.Common?) -> [AndroidColorsEntry] {
        switch self {
        case let .single(colors):
            // Legacy format: source comes from common.variablesColors
            guard let variablesColors = common?.variablesColors else {
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
                themeAttributes: colors.themeAttributes?.toPluginThemeAttributes()
            )]
        case let .multiple(entries):
            return entries.map { $0.toPluginEntry() }
        }
    }
}

extension Params.Android.ImagesEntry {
    /// Converts Params.Android.ImagesEntry to AndroidImagesEntry.
    func toPluginEntry(common: Params.Common?) -> AndroidImagesEntry {
        AndroidImagesEntry(
            figmaFrameName: figmaFrameName ?? common?.images?.figmaFrameName,
            sourceFormat: sourceFormat.map { ExFigCore.ImageSourceFormat(rawValue: $0.rawValue) ?? .png },
            scales: scales,
            nameValidateRegexp: common?.images?.nameValidateRegexp,
            nameReplaceRegexp: common?.images?.nameReplaceRegexp,
            nameStyle: nil,
            output: output,
            format: ExFig_Android.AndroidImageFormat(rawValue: format.rawValue) ?? .png,
            webpOptions: webpOptions.map { opts in
                ExFig_Android.WebpOptions(
                    lossless: opts.encoding == .lossless,
                    quality: opts.quality
                )
            }
        )
    }
}

extension Params.Android.ImagesConfiguration {
    /// Converts legacy format entries to plugin entries.
    func toPluginEntries(common: Params.Common?) -> [AndroidImagesEntry] {
        switch self {
        case let .single(images):
            [Params.Android.ImagesEntry(
                figmaFrameName: common?.images?.figmaFrameName,
                scales: images.scales,
                output: images.output,
                format: images.format,
                webpOptions: images.webpOptions,
                sourceFormat: images.sourceFormat
            ).toPluginEntry(common: common)]
        case let .multiple(entries):
            entries.map { $0.toPluginEntry(common: common) }
        }
    }
}

// MARK: - Flutter Adapters

extension Params.Flutter {
    /// Creates FlutterPlatformConfig from Params.Flutter.
    func platformConfig() -> FlutterPlatformConfig {
        FlutterPlatformConfig(
            output: output,
            templatesPath: templatesPath
        )
    }
}

extension Params.Flutter.IconsEntry {
    /// Converts Params.Flutter.IconsEntry to FlutterIconsEntry.
    func toPluginEntry() -> FlutterIconsEntry {
        FlutterIconsEntry(
            figmaFrameName: figmaFrameName,
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp,
            nameStyle: nameStyle,
            output: output,
            dartFile: dartFile,
            className: className
        )
    }
}

extension Params.Flutter.IconsConfiguration {
    /// Converts legacy format entries to plugin entries.
    func toPluginEntries(common: Params.Common?) -> [FlutterIconsEntry] {
        switch self {
        case let .single(icons):
            [Params.Flutter.IconsEntry(
                figmaFrameName: common?.icons?.figmaFrameName,
                output: icons.output,
                dartFile: icons.dartFile,
                className: icons.className,
                nameStyle: nil,
                nameValidateRegexp: common?.icons?.nameValidateRegexp,
                nameReplaceRegexp: common?.icons?.nameReplaceRegexp
            ).toPluginEntry()]
        case let .multiple(entries):
            entries.map { $0.toPluginEntry() }
        }
    }
}

extension Params.Flutter.ColorsEntry {
    /// Converts Params.Flutter.ColorsEntry to FlutterColorsEntry.
    func toPluginEntry() -> FlutterColorsEntry {
        FlutterColorsEntry(
            tokensFileId: tokensFileId,
            tokensCollectionName: tokensCollectionName,
            lightModeName: lightModeName,
            darkModeName: darkModeName,
            lightHCModeName: lightHCModeName,
            darkHCModeName: darkHCModeName,
            primitivesModeName: primitivesModeName,
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp,
            output: output,
            className: className
        )
    }
}

extension Params.Flutter.ColorsConfiguration {
    /// Converts legacy format entries to plugin entries.
    func toPluginEntries(common: Params.Common?) -> [FlutterColorsEntry] {
        switch self {
        case let .single(colors):
            // Legacy format: source comes from common.variablesColors
            guard let variablesColors = common?.variablesColors else {
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
            return entries.map { $0.toPluginEntry() }
        }
    }
}

extension Params.Flutter.ImagesEntry {
    /// Converts Params.Flutter.ImagesEntry to FlutterImagesEntry.
    func toPluginEntry(common: Params.Common?) -> FlutterImagesEntry {
        FlutterImagesEntry(
            figmaFrameName: figmaFrameName ?? common?.images?.figmaFrameName,
            sourceFormat: sourceFormat.map { ExFigCore.ImageSourceFormat(rawValue: $0.rawValue) ?? .png },
            scales: scales,
            nameValidateRegexp: common?.images?.nameValidateRegexp,
            nameReplaceRegexp: common?.images?.nameReplaceRegexp,
            nameStyle: nameStyle,
            output: output,
            dartFile: dartFile,
            className: className,
            format: format.map { ExFig_Flutter.FlutterImageFormat(rawValue: $0.rawValue) ?? .png },
            webpOptions: webpOptions.map { opts in
                ExFig_Flutter.WebpOptions(
                    lossless: opts.encoding == .lossless,
                    quality: opts.quality
                )
            }
        )
    }
}

extension Params.Flutter.ImagesConfiguration {
    /// Converts legacy format entries to plugin entries.
    func toPluginEntries(common: Params.Common?) -> [FlutterImagesEntry] {
        switch self {
        case let .single(images):
            [Params.Flutter.ImagesEntry(
                figmaFrameName: common?.images?.figmaFrameName,
                output: images.output,
                dartFile: images.dartFile,
                className: images.className,
                scales: images.scales,
                format: images.format,
                webpOptions: images.webpOptions,
                sourceFormat: images.sourceFormat,
                nameStyle: images.nameStyle
            ).toPluginEntry(common: common)]
        case let .multiple(entries):
            entries.map { $0.toPluginEntry(common: common) }
        }
    }
}

// MARK: - Web Adapters

extension Params.Web {
    /// Creates WebPlatformConfig from Params.Web.
    func platformConfig() -> WebPlatformConfig {
        WebPlatformConfig(
            output: output,
            templatesPath: templatesPath
        )
    }
}

extension Params.Web.IconsEntry {
    /// Converts Params.Web.IconsEntry to WebIconsEntry.
    func toPluginEntry() -> WebIconsEntry {
        WebIconsEntry(
            figmaFrameName: figmaFrameName,
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp,
            nameStyle: nameStyle,
            outputDirectory: outputDirectory,
            svgDirectory: svgDirectory,
            generateReactComponents: generateReactComponents,
            iconSize: iconSize
        )
    }
}

extension Params.Web.IconsConfiguration {
    /// Converts legacy format entries to plugin entries.
    func toPluginEntries(common: Params.Common?) -> [WebIconsEntry] {
        switch self {
        case let .single(icons):
            [Params.Web.IconsEntry(
                figmaFrameName: common?.icons?.figmaFrameName,
                outputDirectory: icons.outputDirectory,
                svgDirectory: icons.svgDirectory,
                generateReactComponents: icons.generateReactComponents,
                iconSize: icons.iconSize,
                nameStyle: nil,
                nameValidateRegexp: common?.icons?.nameValidateRegexp,
                nameReplaceRegexp: common?.icons?.nameReplaceRegexp
            ).toPluginEntry()]
        case let .multiple(entries):
            entries.map { $0.toPluginEntry() }
        }
    }
}

extension Params.Web.ColorsEntry {
    /// Converts Params.Web.ColorsEntry to WebColorsEntry.
    func toPluginEntry() -> WebColorsEntry {
        WebColorsEntry(
            tokensFileId: tokensFileId,
            tokensCollectionName: tokensCollectionName,
            lightModeName: lightModeName,
            darkModeName: darkModeName,
            lightHCModeName: lightHCModeName,
            darkHCModeName: darkHCModeName,
            primitivesModeName: primitivesModeName,
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp,
            outputDirectory: outputDirectory,
            cssFileName: cssFileName,
            tsFileName: tsFileName,
            jsonFileName: jsonFileName
        )
    }
}

extension Params.Web.ColorsConfiguration {
    /// Converts legacy format entries to plugin entries.
    func toPluginEntries(common: Params.Common?) -> [WebColorsEntry] {
        switch self {
        case let .single(colors):
            // Legacy format: source comes from common.variablesColors
            guard let variablesColors = common?.variablesColors else {
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
            return entries.map { $0.toPluginEntry() }
        }
    }
}

extension Params.Web.ImagesEntry {
    /// Converts Params.Web.ImagesEntry to WebImagesEntry.
    func toPluginEntry(common: Params.Common?) -> WebImagesEntry {
        WebImagesEntry(
            figmaFrameName: figmaFrameName ?? common?.images?.figmaFrameName,
            nameValidateRegexp: common?.images?.nameValidateRegexp,
            nameReplaceRegexp: common?.images?.nameReplaceRegexp,
            nameStyle: nil,
            outputDirectory: outputDirectory,
            assetsDirectory: assetsDirectory,
            generateReactComponents: generateReactComponents
        )
    }
}

extension Params.Web.ImagesConfiguration {
    /// Converts legacy format entries to plugin entries.
    func toPluginEntries(common: Params.Common?) -> [WebImagesEntry] {
        switch self {
        case let .single(images):
            [Params.Web.ImagesEntry(
                figmaFrameName: common?.images?.figmaFrameName,
                outputDirectory: images.outputDirectory,
                assetsDirectory: images.assetsDirectory,
                generateReactComponents: images.generateReactComponents
            ).toPluginEntry(common: common)]
        case let .multiple(entries):
            entries.map { $0.toPluginEntry(common: common) }
        }
    }
}
