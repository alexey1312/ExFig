import ExFigCore
import FigmaAPI
import Foundation
import XcodeExport

// MARK: - iOS Colors Export

extension ExFigCommand.ExportColors {
    /// Exports iOS colors using multiple entries format.
    func exportiOSColorsMultiple(
        entries: [Params.iOS.ColorsEntry],
        ios: Params.iOS,
        client: Client,
        ui: TerminalUI
    ) async throws -> Int {
        var totalCount = 0

        for entry in entries {
            let colors = try await ui.withSpinner(
                "Fetching colors from Figma (\(entry.tokensCollectionName))..."
            ) {
                let loader = ColorsVariablesLoader(
                    client: client,
                    figmaParams: options.params.figma,
                    variableParams: Params.Common.VariablesColors(
                        tokensFileId: entry.tokensFileId,
                        tokensCollectionName: entry.tokensCollectionName,
                        lightModeName: entry.lightModeName,
                        darkModeName: entry.darkModeName,
                        lightHCModeName: entry.lightHCModeName,
                        darkHCModeName: entry.darkHCModeName,
                        primitivesModeName: entry.primitivesModeName,
                        nameValidateRegexp: entry.nameValidateRegexp,
                        nameReplaceRegexp: entry.nameReplaceRegexp
                    ),
                    filter: filter
                )
                return try await loader.load()
            }

            let colorPairs = try await ui.withSpinner("Processing colors for iOS...") {
                let processor = ColorsProcessor(
                    platform: .ios,
                    nameValidateRegexp: entry.nameValidateRegexp,
                    nameReplaceRegexp: entry.nameReplaceRegexp,
                    nameStyle: entry.nameStyle
                )
                let result = processor.process(
                    light: colors.light,
                    dark: colors.dark,
                    lightHC: colors.lightHC,
                    darkHC: colors.darkHC
                )
                if let warning = result.warning {
                    ui.warning(warning)
                }
                return try result.get()
            }

            try await ui.withSpinner("Exporting colors to Xcode project...") {
                try exportXcodeColorsEntry(colorPairs: colorPairs, entry: entry, ios: ios, ui: ui)
            }

            totalCount += colorPairs.count
        }

        if BatchProgressViewStorage.progressView == nil {
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        ui.success("Done! Exported \(totalCount) colors to Xcode project.")
        return totalCount
    }

    /// Exports iOS colors using legacy format (common.variablesColors or common.colors).
    func exportiOSColorsLegacy(
        colorsConfig: Params.iOS.ColorsConfiguration,
        ios: Params.iOS,
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

        if BatchProgressViewStorage.progressView == nil {
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        config.ui.success("Done! Exported \(colorPairs.count) colors to Xcode project.")
        return colorPairs.count
    }

    // MARK: - Xcode Entry Export

    func exportXcodeColorsEntry(
        colorPairs: [AssetPair<Color>],
        entry: Params.iOS.ColorsEntry,
        ios: Params.iOS,
        ui: TerminalUI
    ) throws {
        var colorsURL: URL?
        if entry.useColorAssets {
            if let folder = entry.assetsFolder {
                colorsURL = ios.xcassetsPath.appendingPathComponent(folder)
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
            ui.warning(.xcodeProjectUpdateFailed)
        }
    }
}
