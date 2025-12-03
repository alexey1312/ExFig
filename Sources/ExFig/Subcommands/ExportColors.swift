import AndroidExport
import ArgumentParser
import ExFigCore
import FigmaAPI
import FlutterExport
import Foundation
import XcodeExport

extension ExFigCommand {
    struct ExportColors: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "colors",
            abstract: "Exports colors from Figma",
            discussion: "Exports light and dark color palette from Figma to Xcode / Android Studio project"
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @OptionGroup
        var options: ExFigOptions

        @OptionGroup
        var cacheOptions: CacheOptions

        @Argument(help: """
        [Optional] Name of the colors to export. For example \"background/default\" \
        to export single color, \"background/default, background/secondary\" to export several colors and \
        \"background/*\" to export all colors from the folder.
        """)
        var filter: String?

        // swiftlint:disable:next function_body_length
        func run() async throws {
            ExFigCommand.initializeTerminalUI(verbose: globalOptions.verbose, quiet: globalOptions.quiet)
            let ui = ExFigCommand.terminalUI!

            let client = FigmaClient(accessToken: options.accessToken, timeout: options.params.figma.timeout)

            // Check for version changes if cache is enabled
            let configCacheEnabled = options.params.common?.cache?.isEnabled ?? false
            let cacheEnabled = cacheOptions.isEnabled(configEnabled: configCacheEnabled)
            let cachePath = cacheOptions.resolvePath(configPath: options.params.common?.cache?.path)

            var trackingManager: ImageTrackingManager?
            var fileVersions: [FileVersionInfo] = []

            if cacheEnabled {
                trackingManager = ImageTrackingManager(
                    client: client,
                    cachePath: cachePath,
                    logger: logger
                )

                let result = try await ui.withSpinner("Checking for changes...") {
                    try await trackingManager!.checkForChanges(
                        lightFileId: options.params.figma.lightFileId,
                        darkFileId: options.params.figma.darkFileId,
                        force: cacheOptions.force
                    )
                }

                switch result {
                case let .noChanges(files):
                    ui.success("No changes detected. Colors are up to date.")
                    for file in files {
                        ui.info("  - \(file.fileName): version \(file.currentVersion) (unchanged)")
                    }
                    return
                case let .exportNeeded(files):
                    fileVersions = files
                    if cacheOptions.force {
                        ui.info("Force export requested.")
                    } else {
                        ui.info("Changes detected, exporting...")
                    }
                    for file in files {
                        if let cached = file.cachedVersion {
                            ui.info("  - \(file.fileName): \(cached) -> \(file.currentVersion)")
                        } else {
                            ui.info("  - \(file.fileName): version \(file.currentVersion) (new)")
                        }
                    }
                case let .partialChanges(changed, unchanged):
                    fileVersions = changed + unchanged
                    ui.info("Partial changes detected:")
                    for file in changed {
                        ui.info("  - \(file.fileName): \(file.cachedVersion ?? "new") -> \(file.currentVersion)")
                    }
                    for file in unchanged {
                        ui.info("  - \(file.fileName): unchanged")
                    }
                }
            }

            ui.info("Using ExFig \(ExFigCommand.version) to export colors.")
            let commonParams = options.params.common

            if commonParams?.colors != nil, commonParams?.variablesColors != nil {
                let errorMsg = "In the configuration file, you can use " +
                    "either the common/colors or common/variablesColors parameter"
                throw ExFigError.custom(errorString: errorMsg)
            }

            let figmaParams = options.params.figma
            var colors: ColorsLoaderOutput?
            var nameValidateRegexp: String?
            var nameReplaceRegexp: String?

            // Fetch colors with spinner
            colors = try await ui.withSpinner("Fetching colors from Figma...") {
                if let variableParams = commonParams?.variablesColors {
                    let loader = ColorsVariablesLoader(
                        client: client,
                        figmaParams: figmaParams,
                        variableParams: variableParams,
                        filter: filter
                    )
                    return try await loader.load()
                } else {
                    let loader = ColorsLoader(
                        client: client,
                        figmaParams: figmaParams,
                        colorParams: commonParams?.colors,
                        filter: filter
                    )
                    return try await loader.load()
                }
            }

            if let variableParams = commonParams?.variablesColors {
                nameValidateRegexp = variableParams.nameValidateRegexp
                nameReplaceRegexp = variableParams.nameReplaceRegexp
            } else {
                nameValidateRegexp = commonParams?.colors?.nameValidateRegexp
                nameReplaceRegexp = commonParams?.colors?.nameReplaceRegexp
            }

            guard let colors else {
                throw ExFigError.custom(errorString: "Failed to load colors from Figma")
            }

            if let ios = options.params.ios {
                let validateRegexp = nameValidateRegexp
                let replaceRegexp = nameReplaceRegexp
                let colorPairs = try await ui.withSpinner("Processing colors for iOS...") {
                    let processor = ColorsProcessor(
                        platform: .ios,
                        nameValidateRegexp: validateRegexp,
                        nameReplaceRegexp: replaceRegexp,
                        nameStyle: options.params.ios?.colors?.nameStyle
                    )
                    let result = processor.process(
                        light: colors.light,
                        dark: colors.dark,
                        lightHC: colors.lightHC,
                        darkHC: colors.darkHC
                    )
                    if let warning = result.warning?.errorDescription {
                        ui.warning(warning)
                    }
                    return try result.get()
                }

                try await ui.withSpinner("Exporting colors to Xcode project...") {
                    try exportXcodeColors(colorPairs: colorPairs, iosParams: ios, ui: ui)
                }

                await checkForUpdate(logger: logger)

                ui.success("Done! Exported \(colorPairs.count) colors to Xcode project.")
            }

            if let android = options.params.android {
                let validateRegexpAndroid = nameValidateRegexp
                let replaceRegexpAndroid = nameReplaceRegexp
                let colorPairs = try await ui.withSpinner("Processing colors for Android...") {
                    let processor = ColorsProcessor(
                        platform: .android,
                        nameValidateRegexp: validateRegexpAndroid,
                        nameReplaceRegexp: replaceRegexpAndroid,
                        nameStyle: .snakeCase
                    )
                    let result = processor.process(light: colors.light, dark: colors.dark)
                    if let warning = result.warning?.errorDescription {
                        ui.warning(warning)
                    }
                    return try result.get()
                }

                try await ui.withSpinner("Exporting colors to Android Studio project...") {
                    try exportAndroidColors(colorPairs: colorPairs, androidParams: android)
                }

                await checkForUpdate(logger: logger)

                ui.success("Done! Exported \(colorPairs.count) colors to Android project.")
            }

            if let flutter = options.params.flutter, flutter.colors != nil {
                let validateRegexpFlutter = nameValidateRegexp
                let replaceRegexpFlutter = nameReplaceRegexp
                let colorPairs = try await ui.withSpinner("Processing colors for Flutter...") {
                    let processor = ColorsProcessor(
                        platform: .android, // Flutter uses similar naming to Android
                        nameValidateRegexp: validateRegexpFlutter,
                        nameReplaceRegexp: replaceRegexpFlutter,
                        nameStyle: NameStyle.camelCase
                    )
                    let result = processor.process(light: colors.light, dark: colors.dark)
                    if let warning = result.warning?.errorDescription {
                        ui.warning(warning)
                    }
                    return try result.get()
                }

                try await ui.withSpinner("Exporting colors to Flutter project...") {
                    try exportFlutterColors(colorPairs: colorPairs, flutterParams: flutter)
                }

                await checkForUpdate(logger: logger)

                ui.success("Done! Exported \(colorPairs.count) colors to Flutter project.")
            }

            // Update cache after successful export
            if let trackingManager, !fileVersions.isEmpty {
                try trackingManager.updateCache(with: fileVersions)
            }
        }

        private func exportXcodeColors(
            colorPairs: [AssetPair<Color>],
            iosParams: Params.iOS,
            ui: TerminalUI
        ) throws {
            guard let colorParams = iosParams.colors else {
                ui.warning("Nothing to do. Add ios.colors parameters to the config file.")
                return
            }

            var colorsURL: URL?
            if colorParams.useColorAssets {
                if let folder = colorParams.assetsFolder {
                    colorsURL = iosParams.xcassetsPath.appendingPathComponent(folder)
                } else {
                    throw ExFigError.colorsAssetsFolderNotSpecified
                }
            }

            let output = XcodeColorsOutput(
                assetsColorsURL: colorsURL,
                assetsInMainBundle: iosParams.xcassetsInMainBundle,
                assetsInSwiftPackage: iosParams.xcassetsInSwiftPackage,
                resourceBundleNames: iosParams.resourceBundleNames,
                addObjcAttribute: iosParams.addObjcAttribute,
                colorSwiftURL: colorParams.colorSwift,
                swiftuiColorSwiftURL: colorParams.swiftuiColorSwift,
                groupUsingNamespace: colorParams.groupUsingNamespace,
                templatesPath: iosParams.templatesPath
            )

            let exporter = XcodeColorExporter(output: output)
            let files = try exporter.export(colorPairs: colorPairs)

            if colorParams.useColorAssets, let url = colorsURL {
                try? FileManager.default.removeItem(atPath: url.path)
            }

            try fileWriter.write(files: files)

            guard iosParams.xcassetsInSwiftPackage == false else {
                return
            }

            do {
                let xcodeProject = try XcodeProjectWriter(
                    xcodeProjPath: iosParams.xcodeprojPath,
                    target: iosParams.target
                )
                try files.forEach { file in
                    if file.destination.file.pathExtension == "swift" {
                        try xcodeProject.addFileReferenceToXcodeProj(file.destination.url)
                    }
                }
                try xcodeProject.save()
            } catch {
                ui.warning("Unable to add some file references to Xcode project")
            }
        }

        private func exportAndroidColors(colorPairs: [AssetPair<Color>], androidParams: Params.Android) throws {
            let output = AndroidOutput(
                xmlOutputDirectory: androidParams.mainRes,
                xmlResourcePackage: androidParams.resourcePackage,
                srcDirectory: androidParams.mainSrc,
                packageName: androidParams.colors?.composePackageName,
                templatesPath: androidParams.templatesPath
            )
            let exporter = AndroidColorExporter(
                output: output,
                xmlOutputFileName: androidParams.colors?.xmlOutputFileName
            )
            let files = try exporter.export(colorPairs: colorPairs)

            let fileName = androidParams.colors?.xmlOutputFileName ?? "colors.xml"

            let lightColorsFileURL = androidParams.mainRes.appendingPathComponent("values/" + fileName)
            let darkColorsFileURL = androidParams.mainRes.appendingPathComponent("values-night/" + fileName)

            try? FileManager.default.removeItem(atPath: lightColorsFileURL.path)
            try? FileManager.default.removeItem(atPath: darkColorsFileURL.path)

            try fileWriter.write(files: files)
        }

        private func exportFlutterColors(colorPairs: [AssetPair<Color>], flutterParams: Params.Flutter) throws {
            let output = FlutterOutput(
                outputDirectory: flutterParams.output,
                templatesPath: flutterParams.templatesPath,
                colorsClassName: flutterParams.colors?.className
            )
            let exporter = FlutterColorExporter(
                output: output,
                outputFileName: flutterParams.colors?.output
            )
            let files = try exporter.export(colorPairs: colorPairs)

            let fileName = flutterParams.colors?.output ?? "colors.dart"
            let colorsFileURL = flutterParams.output.appendingPathComponent(fileName)

            try? FileManager.default.removeItem(atPath: colorsFileURL.path)

            try fileWriter.write(files: files)
        }
    }
}
