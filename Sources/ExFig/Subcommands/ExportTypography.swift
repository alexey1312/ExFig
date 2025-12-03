import AndroidExport
import ArgumentParser
import ExFigCore
import FigmaAPI
import Foundation
import XcodeExport

extension ExFigCommand {
    struct ExportTypography: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "typography",
            abstract: "Exports typography from Figma",
            discussion: "Exports font styles from Figma to Xcode",
            aliases: ["text-styles"]
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @OptionGroup
        var options: ExFigOptions

        @OptionGroup
        var cacheOptions: CacheOptions

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
                    ui.success("No changes detected. Typography is up to date.")
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

            ui.info("Using ExFig \(ExFigCommand.version) to export typography.")

            let textStyles = try await ui.withSpinner("Fetching text styles from Figma...") {
                let loader = TextStylesLoader(client: client, params: options.params.figma)
                return try await loader.load()
            }

            if let ios = options.params.ios,
               let typographyParams = ios.typography
            {
                let processedTextStyles = try await ui.withSpinner("Processing typography for iOS...") {
                    let processor = TypographyProcessor(
                        platform: .ios,
                        nameValidateRegexp: options.params.common?.typography?.nameValidateRegexp,
                        nameReplaceRegexp: options.params.common?.typography?.nameReplaceRegexp,
                        nameStyle: typographyParams.nameStyle
                    )
                    return try processor.process(assets: textStyles).get()
                }

                try await ui.withSpinner("Exporting typography to Xcode project...") {
                    try exportXcodeTextStyles(textStyles: processedTextStyles, iosParams: ios, ui: ui)
                }

                await checkForUpdate(logger: logger)

                ui.success("Done! Exported \(processedTextStyles.count) text styles to Xcode project.")
            }

            if let android = options.params.android {
                let processedTextStyles = try await ui.withSpinner("Processing typography for Android...") {
                    let processor = TypographyProcessor(
                        platform: .android,
                        nameValidateRegexp: options.params.common?.typography?.nameValidateRegexp,
                        nameReplaceRegexp: options.params.common?.typography?.nameReplaceRegexp,
                        nameStyle: options.params.android?.typography?.nameStyle
                    )
                    return try processor.process(assets: textStyles).get()
                }

                try await ui.withSpinner("Exporting typography to Android Studio project...") {
                    try exportAndroidTextStyles(textStyles: processedTextStyles, androidParams: android)
                }

                await checkForUpdate(logger: logger)

                ui.success("Done! Exported \(processedTextStyles.count) text styles to Android project.")
            }

            // Update cache after successful export
            if let trackingManager, !fileVersions.isEmpty {
                try trackingManager.updateCache(with: fileVersions)
            }
        }

        private func createXcodeOutput(from iosParams: Params.iOS) -> XcodeTypographyOutput {
            let fontUrls = XcodeTypographyOutput.FontURLs(
                fontExtensionURL: iosParams.typography?.fontSwift,
                swiftUIFontExtensionURL: iosParams.typography?.swiftUIFontSwift
            )
            let labelUrls = XcodeTypographyOutput.LabelURLs(
                labelsDirectory: iosParams.typography?.labelsDirectory,
                labelStyleExtensionsURL: iosParams.typography?.labelStyleSwift
            )
            let urls = XcodeTypographyOutput.URLs(
                fonts: fontUrls,
                labels: labelUrls
            )
            return XcodeTypographyOutput(
                urls: urls,
                generateLabels: iosParams.typography?.generateLabels,
                addObjcAttribute: iosParams.addObjcAttribute,
                templatesPath: iosParams.templatesPath
            )
        }

        private func exportXcodeTextStyles(textStyles: [TextStyle], iosParams: Params.iOS, ui: TerminalUI) throws {
            let output = createXcodeOutput(from: iosParams)
            let exporter = XcodeTypographyExporter(output: output)
            let files = try exporter.export(textStyles: textStyles)

            try fileWriter.write(files: files)

            guard iosParams.xcassetsInSwiftPackage == false else { return }

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

        private func exportAndroidTextStyles(textStyles: [TextStyle], androidParams: Params.Android) throws {
            let output = AndroidOutput(
                xmlOutputDirectory: androidParams.mainRes,
                xmlResourcePackage: androidParams.resourcePackage,
                srcDirectory: androidParams.mainSrc,
                packageName: androidParams.typography?.composePackageName,
                templatesPath: androidParams.templatesPath
            )
            let exporter = AndroidTypographyExporter(output: output)
            let files = try exporter.exportFonts(textStyles: textStyles)

            let fileURL = androidParams.mainRes.appendingPathComponent("values/typography.xml")

            try? FileManager.default.removeItem(atPath: fileURL.path)
            try fileWriter.write(files: files)
        }
    }
}
