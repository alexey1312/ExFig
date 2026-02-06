import ExFig_iOS
import ExFigCore
import FigmaAPI
import Foundation
import XcodeExport

// MARK: - iOS Colors Export

extension ExFigCommand.ExportColors {
    /// Exports iOS colors using legacy format (common.variablesColors or common.colors).
    func exportiOSColorsLegacy(
        colorsConfig: PKLConfig.iOS.ColorsConfiguration,
        ios: PKLConfig.iOS,
        config: LegacyExportConfig
    ) async throws -> Int {
        try validateLegacyConfig(config.commonParams)

        let colors = try await loadLegacyColors(config: config)

        let (finalNameValidateRegexp, finalNameReplaceRegexp) = extractNameRegexps(
            from: config.commonParams
        )

        // Get the first entry for legacy format
        let entry = colorsConfig.entries[0]

        let colorPairs = try await config.ui.withSpinner("Processing colors for iOS...") {
            let processor = ColorsProcessor(
                platform: .ios,
                nameValidateRegexp: finalNameValidateRegexp,
                nameReplaceRegexp: finalNameReplaceRegexp,
                nameStyle: entry.nameStyle
            )
            let result = processor.process(
                light: colors.light,
                dark: colors.dark,
                lightHC: colors.lightHC,
                darkHC: colors.darkHC
            )
            if let warning = result.warning {
                config.ui.warning(warning)
            }
            return try result.get()
        }

        try await config.ui.withSpinner("Exporting colors to Xcode project...") {
            try exportXcodeColorsEntry(
                colorPairs: colorPairs, entry: entry, ios: ios, ui: config.ui
            )
        }

        // Sync codeSyntax back to Figma if configured (legacy format uses entry.syncCodeSyntax +
        // common.variablesColors)
        if entry.syncCodeSyntax == true,
           let template = entry.codeSyntaxTemplate,
           let variablesColors = config.commonParams?.variablesColors
        {
            let syncCount = try await config.ui.withSpinner("Syncing codeSyntax to Figma...") {
                let syncer = CodeSyntaxSyncer(client: config.client)
                return try await syncer.sync(
                    fileId: variablesColors.tokensFileId,
                    collectionName: variablesColors.tokensCollectionName,
                    template: template,
                    nameStyle: entry.nameStyle,
                    nameValidateRegexp: finalNameValidateRegexp,
                    nameReplaceRegexp: finalNameReplaceRegexp
                )
            }
            config.ui.info("Synced codeSyntax for \(syncCount) variables")
        }

        if BatchProgressViewStorage.progressView == nil {
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        config.ui.success("Done! Exported \(colorPairs.count) colors to Xcode project.")
        return colorPairs.count
    }

    // MARK: - Xcode Entry Export

    func exportXcodeColorsEntry(
        colorPairs: [AssetPair<Color>],
        entry: iOSColorsEntry,
        ios: PKLConfig.iOS,
        ui: TerminalUI
    ) throws {
        var colorsURL: URL?
        if entry.useColorAssets {
            if let folder = entry.assetsFolder {
                guard let xcassetsPath = ios.xcassetsPath else {
                    throw ExFigError
                        .configurationError("xcassetsPath is required for iOS colors export with useColorAssets")
                }
                colorsURL = xcassetsPath.appendingPathComponent(folder)
            } else {
                throw ExFigError.colorsAssetsFolderNotSpecified
            }
        }

        let output = XcodeColorsOutput(
            assetsColorsURL: colorsURL,
            assetsInMainBundle: ios.xcassetsInMainBundle,
            assetsInSwiftPackage: ios.xcassetsInSwiftPackage,
            resourceBundleNames: ios.resourceBundleNames,
            addObjcAttribute: ios.addObjcAttribute,
            colorSwiftURL: entry.colorSwift,
            swiftuiColorSwiftURL: entry.swiftuiColorSwift,
            groupUsingNamespace: entry.groupUsingNamespace,
            templatesPath: ios.templatesPath
        )

        let exporter = XcodeColorExporter(output: output)
        let files = try exporter.export(colorPairs: colorPairs)

        if entry.useColorAssets, let url = colorsURL {
            try? FileManager.default.removeItem(atPath: url.path)
        }

        try ExFigCommand.fileWriter.write(files: files)

        guard ios.xcassetsInSwiftPackage == false else {
            return
        }

        do {
            let xcodeProject = try XcodeProjectWriter(
                xcodeProjPath: ios.xcodeprojPath,
                target: ios.target
            )
            try files.forEach { file in
                if file.destination.file.pathExtension == "swift" {
                    try xcodeProject.addFileReferenceToXcodeProj(file.destination.url)
                }
            }
            try xcodeProject.save()
        } catch {
            ui.warning(.xcodeProjectUpdateFailed(detail: error.localizedDescription))
        }
    }
}
