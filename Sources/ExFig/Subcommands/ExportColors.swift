import AndroidExport
import ArgumentParser
import ExFigCore
import FigmaAPI
import FlutterExport
import Foundation
import WebExport
import XcodeExport

// swiftlint:disable file_length type_body_length
extension ExFigCommand {
    struct ExportColors: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "colors",
            abstract: "Exports colors from Figma",
            discussion:
            "Exports light and dark color palette from Figma to Xcode / Android Studio project"
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @OptionGroup
        var options: ExFigOptions

        @OptionGroup
        var cacheOptions: CacheOptions

        @OptionGroup
        var faultToleranceOptions: FaultToleranceOptions

        @Argument(
            help: """
            [Optional] Name of the colors to export. For example \"background/default\" \
            to export single color, \"background/default, background/secondary\" to export several colors and \
            \"background/*\" to export all colors from the folder.
            """)
        var filter: String?

        func run() async throws {
            ExFigCommand.initializeTerminalUI(
                verbose: globalOptions.verbose, quiet: globalOptions.quiet
            )
            let ui = ExFigCommand.terminalUI!

            let client = resolveClient(
                accessToken: options.accessToken,
                timeout: options.params.figma.timeout,
                options: faultToleranceOptions,
                ui: ui
            )

            _ = try await performExport(client: client, ui: ui)
        }

        // swiftlint:disable:next function_body_length cyclomatic_complexity
        func performExport(client: Client, ui: TerminalUI) async throws -> Int {
            // Check for version changes if cache is enabled
            let versionCheck = try await VersionTrackingHelper.checkForChanges(
                config: VersionTrackingConfig(
                    client: client,
                    params: options.params,
                    cacheOptions: cacheOptions,
                    configCacheEnabled: options.params.common?.cache?.isEnabled ?? false,
                    configCachePath: options.params.common?.cache?.path,
                    assetType: "Colors",
                    ui: ui,
                    logger: logger
                )
            )

            guard case let .proceed(trackingManager, fileVersions) = versionCheck else {
                return 0
            }

            // Suppress version message in batch mode
            if BatchProgressViewStorage.progressView == nil {
                ui.info("Using ExFig \(ExFigCommand.version) to export colors.")
            }
            let commonParams = options.params.common
            let figmaParams = options.params.figma
            var totalCount = 0

            // iOS export
            if let ios = options.params.ios, let colorsConfig = ios.colors {
                if colorsConfig.isMultiple {
                    // New format: multiple entries with self-contained source data
                    totalCount += try await exportiOSColorsMultiple(
                        entries: colorsConfig.entries,
                        ios: ios,
                        client: client,
                        ui: ui
                    )
                } else {
                    // Legacy format: use common.variablesColors or common.colors
                    let config = LegacyExportConfig(
                        commonParams: commonParams,
                        figmaParams: figmaParams,
                        client: client,
                        ui: ui
                    )
                    totalCount += try await exportiOSColorsLegacy(
                        colorsConfig: colorsConfig,
                        ios: ios,
                        config: config
                    )
                }
            }

            // Android export
            if let android = options.params.android, let colorsConfig = android.colors {
                if colorsConfig.isMultiple {
                    totalCount += try await exportAndroidColorsMultiple(
                        entries: colorsConfig.entries,
                        android: android,
                        client: client,
                        ui: ui
                    )
                } else {
                    let config = LegacyExportConfig(
                        commonParams: commonParams,
                        figmaParams: figmaParams,
                        client: client,
                        ui: ui
                    )
                    totalCount += try await exportAndroidColorsLegacy(
                        colorsConfig: colorsConfig,
                        android: android,
                        config: config
                    )
                }
            }

            // Flutter export
            if let flutter = options.params.flutter, let colorsConfig = flutter.colors {
                if colorsConfig.isMultiple {
                    totalCount += try await exportFlutterColorsMultiple(
                        entries: colorsConfig.entries,
                        flutter: flutter,
                        client: client,
                        ui: ui
                    )
                } else {
                    let config = LegacyExportConfig(
                        commonParams: commonParams,
                        figmaParams: figmaParams,
                        client: client,
                        ui: ui
                    )
                    totalCount += try await exportFlutterColorsLegacy(
                        colorsConfig: colorsConfig,
                        flutter: flutter,
                        config: config
                    )
                }
            }

            // Web export
            if let web = options.params.web, let colorsConfig = web.colors {
                if colorsConfig.isMultiple {
                    totalCount += try await exportWebColorsMultiple(
                        entries: colorsConfig.entries,
                        web: web,
                        client: client,
                        ui: ui
                    )
                } else {
                    let config = LegacyExportConfig(
                        commonParams: commonParams,
                        figmaParams: figmaParams,
                        client: client,
                        ui: ui
                    )
                    totalCount += try await exportWebColorsLegacy(
                        colorsConfig: colorsConfig,
                        web: web,
                        config: config
                    )
                }
            }

            // Update cache after successful export
            try VersionTrackingHelper.updateCacheIfNeeded(
                manager: trackingManager, versions: fileVersions
            )

            return totalCount
        }

        // MARK: - Legacy Export Configuration

        /// Configuration for legacy colors export (using common.variablesColors or common.colors).
        private struct LegacyExportConfig {
            let commonParams: Params.Common?
            let figmaParams: Params.Figma
            let client: Client
            let ui: TerminalUI
        }

        // MARK: - iOS Colors Export

        private func exportiOSColorsMultiple(
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
                await checkForUpdate(logger: logger)
            }

            ui.success("Done! Exported \(totalCount) colors to Xcode project.")
            return totalCount
        }

        // swiftlint:disable:next function_body_length
        private func exportiOSColorsLegacy(
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
                await checkForUpdate(logger: logger)
            }

            config.ui.success("Done! Exported \(colorPairs.count) colors to Xcode project.")
            return colorPairs.count
        }

        // MARK: - Android Colors Export

        private func exportAndroidColorsMultiple(
            entries: [Params.Android.ColorsEntry],
            android: Params.Android,
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

                let colorPairs = try await ui.withSpinner("Processing colors for Android...") {
                    let processor = ColorsProcessor(
                        platform: .android,
                        nameValidateRegexp: entry.nameValidateRegexp,
                        nameReplaceRegexp: entry.nameReplaceRegexp,
                        nameStyle: .snakeCase
                    )
                    let result = processor.process(light: colors.light, dark: colors.dark)
                    if let warning = result.warning {
                        ui.warning(warning)
                    }
                    return try result.get()
                }

                try await ui.withSpinner("Exporting colors to Android Studio project...") {
                    try await exportAndroidColorsEntry(colorPairs: colorPairs, entry: entry, android: android, ui: ui)
                }

                totalCount += colorPairs.count
            }

            if BatchProgressViewStorage.progressView == nil {
                await checkForUpdate(logger: logger)
            }

            ui.success("Done! Exported \(totalCount) colors to Android project.")
            return totalCount
        }

        private func exportAndroidColorsLegacy(
            colorsConfig: Params.Android.ColorsConfiguration,
            android: Params.Android,
            config: LegacyExportConfig
        ) async throws -> Int {
            try validateLegacyConfig(config.commonParams)

            let colors = try await loadLegacyColors(config: config)

            let (finalNameValidateRegexp, finalNameReplaceRegexp) = extractNameRegexps(
                from: config.commonParams
            )

            let entry = colorsConfig.entries[0]

            let colorPairs = try await config.ui.withSpinner("Processing colors for Android...") {
                let processor = ColorsProcessor(
                    platform: .android,
                    nameValidateRegexp: finalNameValidateRegexp,
                    nameReplaceRegexp: finalNameReplaceRegexp,
                    nameStyle: .snakeCase
                )
                let result = processor.process(light: colors.light, dark: colors.dark)
                if let warning = result.warning {
                    config.ui.warning(warning)
                }
                return try result.get()
            }

            try await config.ui.withSpinner("Exporting colors to Android Studio project...") {
                try await exportAndroidColorsEntry(
                    colorPairs: colorPairs, entry: entry, android: android, ui: config.ui
                )
            }

            if BatchProgressViewStorage.progressView == nil {
                await checkForUpdate(logger: logger)
            }

            config.ui.success("Done! Exported \(colorPairs.count) colors to Android project.")
            return colorPairs.count
        }

        // MARK: - Flutter Colors Export

        private func exportFlutterColorsMultiple(
            entries: [Params.Flutter.ColorsEntry],
            flutter: Params.Flutter,
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

                let colorPairs = try await ui.withSpinner("Processing colors for Flutter...") {
                    let processor = ColorsProcessor(
                        platform: .flutter,
                        nameValidateRegexp: entry.nameValidateRegexp,
                        nameReplaceRegexp: entry.nameReplaceRegexp,
                        nameStyle: .camelCase
                    )
                    let result = processor.process(light: colors.light, dark: colors.dark)
                    if let warning = result.warning {
                        ui.warning(warning)
                    }
                    return try result.get()
                }

                try await ui.withSpinner("Exporting colors to Flutter project...") {
                    try exportFlutterColorsEntry(colorPairs: colorPairs, entry: entry, flutter: flutter)
                }

                totalCount += colorPairs.count
            }

            if BatchProgressViewStorage.progressView == nil {
                await checkForUpdate(logger: logger)
            }

            ui.success("Done! Exported \(totalCount) colors to Flutter project.")
            return totalCount
        }

        private func exportFlutterColorsLegacy(
            colorsConfig: Params.Flutter.ColorsConfiguration,
            flutter: Params.Flutter,
            config: LegacyExportConfig
        ) async throws -> Int {
            try validateLegacyConfig(config.commonParams)

            let colors = try await loadLegacyColors(config: config)

            let (finalNameValidateRegexp, finalNameReplaceRegexp) = extractNameRegexps(
                from: config.commonParams
            )

            let entry = colorsConfig.entries[0]

            let colorPairs = try await config.ui.withSpinner("Processing colors for Flutter...") {
                let processor = ColorsProcessor(
                    platform: .flutter,
                    nameValidateRegexp: finalNameValidateRegexp,
                    nameReplaceRegexp: finalNameReplaceRegexp,
                    nameStyle: .camelCase
                )
                let result = processor.process(light: colors.light, dark: colors.dark)
                if let warning = result.warning {
                    config.ui.warning(warning)
                }
                return try result.get()
            }

            try await config.ui.withSpinner("Exporting colors to Flutter project...") {
                try exportFlutterColorsEntry(colorPairs: colorPairs, entry: entry, flutter: flutter)
            }

            if BatchProgressViewStorage.progressView == nil {
                await checkForUpdate(logger: logger)
            }

            config.ui.success("Done! Exported \(colorPairs.count) colors to Flutter project.")
            return colorPairs.count
        }

        // MARK: - Legacy Helper Methods

        /// Validates that both common.colors and common.variablesColors are not set at the same time.
        private func validateLegacyConfig(_ commonParams: Params.Common?) throws {
            if commonParams?.colors != nil, commonParams?.variablesColors != nil {
                throw ExFigError.custom(
                    errorString:
                    "In the configuration file, you can use "
                        + "either the common/colors or common/variablesColors parameter"
                )
            }
        }

        /// Loads colors from Figma using either Variables API or legacy Styles API.
        private func loadLegacyColors(config: LegacyExportConfig) async throws -> ColorsLoaderOutput {
            try await config.ui.withSpinner("Fetching colors from Figma...") {
                if let variableParams = config.commonParams?.variablesColors {
                    let loader = ColorsVariablesLoader(
                        client: config.client,
                        figmaParams: config.figmaParams,
                        variableParams: variableParams,
                        filter: filter
                    )
                    return try await loader.load()
                } else {
                    let loader = ColorsLoader(
                        client: config.client,
                        figmaParams: config.figmaParams,
                        colorParams: config.commonParams?.colors,
                        filter: filter
                    )
                    return try await loader.load()
                }
            }
        }

        /// Extracts name validation and replacement regexps from common params.
        private func extractNameRegexps(
            from commonParams: Params.Common?
        ) -> (validate: String?, replace: String?) {
            if let variableParams = commonParams?.variablesColors {
                return (variableParams.nameValidateRegexp, variableParams.nameReplaceRegexp)
            }
            return (commonParams?.colors?.nameValidateRegexp, commonParams?.colors?.nameReplaceRegexp)
        }

        // MARK: - Entry-based Export Methods

        private func exportXcodeColorsEntry(
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

            try fileWriter.write(files: files)

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

        private func exportAndroidColorsEntry(
            colorPairs: [AssetPair<Color>],
            entry: Params.Android.ColorsEntry,
            android: Params.Android,
            ui: TerminalUI
        ) async throws {
            let output = AndroidOutput(
                xmlOutputDirectory: android.mainRes,
                xmlResourcePackage: android.resourcePackage,
                srcDirectory: android.mainSrc,
                packageName: entry.composePackageName,
                templatesPath: android.templatesPath
            )
            let exporter = AndroidColorExporter(
                output: output,
                xmlOutputFileName: entry.xmlOutputFileName
            )
            let files = try exporter.export(colorPairs: colorPairs)

            let fileName = entry.xmlOutputFileName ?? "colors.xml"

            let lightColorsFileURL = android.mainRes.appendingPathComponent(
                "values/" + fileName)
            let darkColorsFileURL = android.mainRes.appendingPathComponent(
                "values-night/" + fileName)

            try? FileManager.default.removeItem(atPath: lightColorsFileURL.path)
            try? FileManager.default.removeItem(atPath: darkColorsFileURL.path)

            try fileWriter.write(files: files)

            // Theme attributes export
            if let themeConfig = entry.themeAttributes, themeConfig.isEnabled {
                try await exportThemeAttributes(
                    colorPairs: colorPairs,
                    config: themeConfig,
                    android: android,
                    ui: ui
                )
            }
        }

        // MARK: - Theme Attributes Export

        private func exportThemeAttributes(
            colorPairs: [AssetPair<Color>],
            config: Params.Android.ThemeAttributes,
            android: Params.Android,
            ui: TerminalUI
        ) async throws {
            let nameTransform = config.nameTransform

            // Create exporter with name transformation config
            let exporter = AndroidThemeAttributesExporter(
                stripPrefixes: nameTransform?.resolvedStripPrefixes ?? [],
                style: nameTransform?.resolvedStyle ?? .pascalCase,
                prefix: nameTransform?.resolvedPrefix ?? "color"
            )

            // Export theme attributes content
            let result = exporter.export(colorPairs: colorPairs)

            // Warn about collisions
            if result.hasCollisions {
                let collisionInfos = result.collisions.map {
                    ThemeAttributeCollisionInfo(
                        attr: $0.attributeName,
                        kept: $0.keptXmlName,
                        discarded: $0.discardedXmlName
                    )
                }
                ui.warning(.themeAttributesNameCollision(count: result.collisions.count, collisions: collisionInfos))
            }

            // Skip if no attributes generated
            guard !result.attributeMap.isEmpty else { return }

            // Resolve file paths relative to mainRes
            let attrsURL = android.mainRes.appendingPathComponent(config.resolvedAttrsFile)
            let stylesURL = android.mainRes.appendingPathComponent(config.resolvedStylesFile)
            let stylesNightURL = android.mainRes.appendingPathComponent(config.resolvedStylesNightFile)

            // Check if we're in batch mode
            if let collector = SharedThemeAttributesStorage.collector {
                // Batch mode: collect for later merge
                let collection = ThemeAttributesCollection(
                    themeName: config.themeName,
                    markerStart: config.resolvedMarkerStart,
                    markerEnd: config.resolvedMarkerEnd,
                    attrsContent: result.attrsContent,
                    stylesContent: result.stylesContent,
                    attrsFile: attrsURL,
                    stylesFile: stylesURL,
                    stylesNightFile: FileManager.default.fileExists(atPath: stylesNightURL.path) ? stylesNightURL : nil,
                    autoCreateMarkers: config.shouldAutoCreateMarkers
                )
                await collector.add(collection)
            } else {
                // Standalone mode: write immediately
                try writeThemeAttributesImmediately(
                    config: config,
                    result: result,
                    attrsURL: attrsURL,
                    stylesURL: stylesURL,
                    stylesNightURL: stylesNightURL
                )
            }
        }

        private func writeThemeAttributesImmediately(
            config: Params.Android.ThemeAttributes,
            result: ThemeAttributesExportResult,
            attrsURL: URL,
            stylesURL: URL,
            stylesNightURL: URL
        ) throws {
            // Create marker updater
            let updater = MarkerFileUpdater(
                markerStart: config.resolvedMarkerStart,
                markerEnd: config.resolvedMarkerEnd,
                themeName: config.themeName
            )

            // Update attrs.xml
            try updateThemeAttributesFile(
                url: attrsURL,
                content: result.attrsContent,
                updater: updater,
                autoCreate: config.shouldAutoCreateMarkers,
                template: attrsXMLTemplate(updater: updater)
            )

            // Update styles.xml (light)
            try updateThemeAttributesFile(
                url: stylesURL,
                content: result.stylesContent,
                updater: updater,
                autoCreate: config.shouldAutoCreateMarkers,
                template: nil // No auto-create for styles.xml - requires manual theme setup
            )

            // Update styles-night.xml (dark) if file exists
            if FileManager.default.fileExists(atPath: stylesNightURL.path) {
                try updateThemeAttributesFile(
                    url: stylesNightURL,
                    content: result.stylesContent,
                    updater: updater,
                    autoCreate: false,
                    template: nil
                )
            }
        }

        private func updateThemeAttributesFile(
            url: URL,
            content: String,
            updater: MarkerFileUpdater,
            autoCreate: Bool,
            template: String?
        ) throws {
            // Ensure parent directory exists
            let directory = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )

            let updatedContent = try updater.update(
                content: content,
                in: url,
                autoCreate: autoCreate,
                templateContent: template
            )

            try Data(updatedContent.utf8).write(to: url, options: .atomic)
        }

        private func attrsXMLTemplate(updater: MarkerFileUpdater) -> String {
            """
            <?xml version="1.0" encoding="utf-8"?>
            <resources>
                \(updater.fullStartMarker)
                \(updater.fullEndMarker)
            </resources>
            """
        }

        private func exportFlutterColorsEntry(
            colorPairs: [AssetPair<Color>],
            entry: Params.Flutter.ColorsEntry,
            flutter: Params.Flutter
        ) throws {
            let output = FlutterOutput(
                outputDirectory: flutter.output,
                templatesPath: flutter.templatesPath,
                colorsClassName: entry.className
            )
            let exporter = FlutterColorExporter(
                output: output,
                outputFileName: entry.output
            )
            let files = try exporter.export(colorPairs: colorPairs)

            let fileName = entry.output ?? "colors.dart"
            let colorsFileURL = flutter.output.appendingPathComponent(fileName)

            try? FileManager.default.removeItem(atPath: colorsFileURL.path)

            try fileWriter.write(files: files)
        }

        // MARK: - Web Colors Export

        private func exportWebColorsMultiple(
            entries: [Params.Web.ColorsEntry],
            web: Params.Web,
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

                let colorPairs = try await ui.withSpinner("Processing colors for Web...") {
                    let processor = ColorsProcessor(
                        platform: .web,
                        nameValidateRegexp: entry.nameValidateRegexp,
                        nameReplaceRegexp: entry.nameReplaceRegexp,
                        nameStyle: .kebabCase
                    )
                    let result = processor.process(light: colors.light, dark: colors.dark)
                    if let warning = result.warning {
                        ui.warning(warning)
                    }
                    return try result.get()
                }

                try await ui.withSpinner("Exporting colors to Web project...") {
                    try exportWebColorsEntry(colorPairs: colorPairs, entry: entry, web: web)
                }

                totalCount += colorPairs.count
            }

            if BatchProgressViewStorage.progressView == nil {
                await checkForUpdate(logger: logger)
            }

            ui.success("Done! Exported \(totalCount) colors to Web project.")
            return totalCount
        }

        private func exportWebColorsLegacy(
            colorsConfig: Params.Web.ColorsConfiguration,
            web: Params.Web,
            config: LegacyExportConfig
        ) async throws -> Int {
            try validateLegacyConfig(config.commonParams)

            let colors = try await loadLegacyColors(config: config)

            let (finalNameValidateRegexp, finalNameReplaceRegexp) = extractNameRegexps(
                from: config.commonParams
            )

            let entry = colorsConfig.entries[0]

            let colorPairs = try await config.ui.withSpinner("Processing colors for Web...") {
                let processor = ColorsProcessor(
                    platform: .web,
                    nameValidateRegexp: finalNameValidateRegexp,
                    nameReplaceRegexp: finalNameReplaceRegexp,
                    nameStyle: .kebabCase
                )
                let result = processor.process(light: colors.light, dark: colors.dark)
                if let warning = result.warning {
                    config.ui.warning(warning)
                }
                return try result.get()
            }

            try await config.ui.withSpinner("Exporting colors to Web project...") {
                try exportWebColorsEntry(colorPairs: colorPairs, entry: entry, web: web)
            }

            if BatchProgressViewStorage.progressView == nil {
                await checkForUpdate(logger: logger)
            }

            config.ui.success("Done! Exported \(colorPairs.count) colors to Web project.")
            return colorPairs.count
        }

        private func exportWebColorsEntry(
            colorPairs: [AssetPair<Color>],
            entry: Params.Web.ColorsEntry,
            web: Params.Web
        ) throws {
            let outputDir = if let dir = entry.outputDirectory {
                web.output.appendingPathComponent(dir)
            } else {
                web.output
            }

            let output = WebOutput(
                outputDirectory: outputDir,
                templatesPath: web.templatesPath
            )
            let exporter = WebColorExporter(
                output: output,
                cssFileName: entry.cssFileName,
                tsFileName: entry.tsFileName,
                jsonFileName: entry.jsonFileName
            )
            let files = try exporter.export(colorPairs: colorPairs)

            // Remove existing files
            let cssFileName = entry.cssFileName ?? "theme.css"
            let tsFileName = entry.tsFileName ?? "variables.ts"

            let cssFileURL = outputDir.appendingPathComponent(cssFileName)
            let tsFileURL = outputDir.appendingPathComponent(tsFileName)

            try? FileManager.default.removeItem(atPath: cssFileURL.path)
            try? FileManager.default.removeItem(atPath: tsFileURL.path)

            if let jsonFileName = entry.jsonFileName {
                let jsonFileURL = outputDir.appendingPathComponent(jsonFileName)
                try? FileManager.default.removeItem(atPath: jsonFileURL.path)
            }

            try fileWriter.write(files: files)
        }
    }
}
