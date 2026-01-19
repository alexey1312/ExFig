import AndroidExport
import ExFigCore
import FigmaAPI
import Foundation

// MARK: - Android Colors Export

extension ExFigCommand.ExportColors {
    /// Exports Android colors using multiple entries format.
    func exportAndroidColorsMultiple(
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
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        ui.success("Done! Exported \(totalCount) colors to Android project.")
        return totalCount
    }

    /// Exports Android colors using legacy format (common.variablesColors or common.colors).
    func exportAndroidColorsLegacy(
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
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        config.ui.success("Done! Exported \(colorPairs.count) colors to Android project.")
        return colorPairs.count
    }

    // MARK: - Android Entry Export

    func exportAndroidColorsEntry(
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
            colorKotlinURL: entry.colorKotlin,
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

        try ExFigCommand.fileWriter.write(files: files)

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

    func exportThemeAttributes(
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

        // Resolve file paths relative to mainRes, normalizing .. components
        let basePath = android.mainRes.path
        let attrsPath = (basePath as NSString).appendingPathComponent(config.resolvedAttrsFile)
        let stylesPath = (basePath as NSString).appendingPathComponent(config.resolvedStylesFile)
        let stylesNightPath = (basePath as NSString).appendingPathComponent(config.resolvedStylesNightFile)

        let attrsURL = URL(fileURLWithPath: (attrsPath as NSString).standardizingPath)
        let stylesURL = URL(fileURLWithPath: (stylesPath as NSString).standardizingPath)
        let stylesNightURL = URL(fileURLWithPath: (stylesNightPath as NSString).standardizingPath)

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

    func writeThemeAttributesImmediately(
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

    func updateThemeAttributesFile(
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

    func attrsXMLTemplate(updater: MarkerFileUpdater) -> String {
        """
        <?xml version="1.0" encoding="utf-8"?>
        <resources>
            \(updater.fullStartMarker)
            \(updater.fullEndMarker)
        </resources>
        """
    }
}
