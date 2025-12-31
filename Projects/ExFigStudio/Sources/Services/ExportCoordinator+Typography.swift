import AndroidExport
import ExFigCore
import ExFigKit
import XcodeExport

// MARK: - Typography Export

extension ExportCoordinator {
    func exportTypography(params: Params, platforms: [ExFigCore.Platform]) async throws -> [ExportResult] {
        var results: [ExportResult] = []

        await progressReporter.beginPhase("Loading typography from Figma")

        do {
            let loader = TextStylesLoader(client: client, params: params.figma)
            let textStyles = try await loader.load()
            await progressReporter.info("Loaded \(textStyles.count) text styles")

            for platform in platforms {
                await progressReporter.info("Exporting typography to \(platform.rawValue)...")

                do {
                    try exportTypographyToPlatform(platform: platform, textStyles: textStyles, params: params)
                    results.append(.success(platform: platform, assetType: .typography, count: textStyles.count))
                    await progressReporter.success("Exported \(textStyles.count) text styles to \(platform.rawValue)")
                } catch {
                    results.append(.failure(platform: platform, assetType: .typography, error: error))
                    await progressReporter
                        .error("Failed to export typography to \(platform.rawValue): \(error.localizedDescription)")
                }
            }
        } catch {
            await progressReporter.error("Failed to load typography: \(error.localizedDescription)")
            for platform in platforms {
                results.append(.failure(platform: platform, assetType: .typography, error: error))
            }
        }

        await progressReporter.endPhase()
        return results
    }

    private func exportTypographyToPlatform(
        platform: ExFigCore.Platform,
        textStyles: [TextStyle],
        params: Params
    ) throws {
        switch platform {
        case .ios:
            try exportTypographyToiOS(textStyles: textStyles, params: params)
        case .android:
            try exportTypographyToAndroid(textStyles: textStyles, params: params)
        case .flutter:
            try exportTypographyToFlutter(textStyles: textStyles, params: params)
        case .web:
            break
        }
    }

    private func exportTypographyToiOS(textStyles: [TextStyle], params: Params) throws {
        guard let ios = params.ios, let typographyConfig = ios.typography else {
            throw ExFigKitError.configurationError("iOS typography configuration not found")
        }

        let fontURLs = XcodeTypographyOutput.FontURLs(
            fontExtensionURL: typographyConfig.fontSwift,
            swiftUIFontExtensionURL: typographyConfig.swiftUIFontSwift
        )
        let labelURLs = XcodeTypographyOutput.LabelURLs(
            labelsDirectory: typographyConfig.labelsDirectory,
            labelStyleExtensionsURL: typographyConfig.labelStyleSwift
        )
        let urls = XcodeTypographyOutput.URLs(fonts: fontURLs, labels: labelURLs)

        let output = XcodeTypographyOutput(
            urls: urls,
            generateLabels: typographyConfig.generateLabels,
            addObjcAttribute: ios.addObjcAttribute,
            templatesPath: ios.templatesPath
        )

        let exporter = XcodeTypographyExporter(output: output)
        let files = try exporter.export(textStyles: textStyles)

        try writeFiles(files)
    }

    private func exportTypographyToAndroid(textStyles: [TextStyle], params: Params) throws {
        guard let android = params.android, android.typography != nil else {
            throw ExFigKitError.configurationError("Android typography configuration not found")
        }

        let output = AndroidOutput(
            xmlOutputDirectory: android.mainRes,
            xmlResourcePackage: android.resourcePackage,
            srcDirectory: android.mainSrc,
            packageName: nil,
            templatesPath: android.templatesPath
        )

        let exporter = AndroidTypographyExporter(output: output)
        let files = try exporter.exportFonts(textStyles: textStyles)

        try writeFiles(files)
    }

    /// Export typography to Flutter.
    /// Note: Flutter typography export is not yet implemented.
    private func exportTypographyToFlutter(textStyles: [TextStyle], params: Params) throws {
        guard params.flutter != nil else {
            throw ExFigKitError.configurationError("Flutter configuration not found")
        }

        throw ExFigKitError.configurationError("Flutter typography export not yet supported. Use CLI for full export.")
    }
}
