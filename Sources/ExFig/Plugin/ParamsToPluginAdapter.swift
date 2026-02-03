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
