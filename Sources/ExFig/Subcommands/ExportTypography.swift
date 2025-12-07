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

        @OptionGroup
        var faultToleranceOptions: FaultToleranceOptions

        func run() async throws {
            ExFigCommand.initializeTerminalUI(verbose: globalOptions.verbose, quiet: globalOptions.quiet)
            let ui = ExFigCommand.terminalUI!

            let client = resolveClient(
                accessToken: options.accessToken,
                timeout: options.params.figma.timeout,
                options: faultToleranceOptions,
                ui: ui
            )

            _ = try await performExport(client: client, ui: ui)
        }

        // swiftlint:disable:next function_body_length
        func performExport(client: Client, ui: TerminalUI) async throws -> Int {
            // Check for version changes if cache is enabled
            let versionCheck = try await VersionTrackingHelper.checkForChanges(
                config: VersionTrackingConfig(
                    client: client,
                    params: options.params,
                    cacheOptions: cacheOptions,
                    configCacheEnabled: options.params.common?.cache?.isEnabled ?? false,
                    configCachePath: options.params.common?.cache?.path,
                    assetType: "Typography",
                    ui: ui,
                    logger: logger
                )
            )

            guard case let .proceed(trackingManager, fileVersions) = versionCheck else {
                return 0
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
            try VersionTrackingHelper.updateCacheIfNeeded(manager: trackingManager, versions: fileVersions)

            return textStyles.count
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
                ui.warning(.xcodeProjectUpdateFailed)
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
