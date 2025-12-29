import AndroidExport
import ExFigCore
import ExFigKit
import FlutterExport
import Foundation
import XcodeExport

// MARK: - Colors Export

extension ExportCoordinator {
    func exportColors(params: Params, platforms: [ExFigCore.Platform]) async throws -> [ExportResult] {
        var results: [ExportResult] = []

        await progressReporter.beginPhase("Loading colors from Figma")

        guard let variablesConfig = params.common?.variablesColors else {
            await progressReporter.warning("No colors configuration found")
            await progressReporter.endPhase()
            return platforms.map { .skipped(platform: $0, assetType: .colors) }
        }

        do {
            let loader = ColorsVariablesLoader(
                client: client,
                figmaParams: params.figma,
                variableParams: variablesConfig,
                filter: nil
            )

            let colorsOutput = try await loader.load()
            let colorCount = colorsOutput.light.count
            await progressReporter.info("Loaded \(colorCount) colors from Figma Variables")

            for platform in platforms {
                await progressReporter.info("Exporting colors to \(platform.rawValue)...")

                do {
                    let count = try await exportColorsToPlatform(
                        platform: platform,
                        colors: colorsOutput,
                        params: params
                    )
                    results.append(.success(platform: platform, assetType: .colors, count: count))
                    await progressReporter.success("Exported \(count) colors to \(platform.rawValue)")
                } catch {
                    results.append(.failure(platform: platform, assetType: .colors, error: error))
                    await progressReporter
                        .error("Failed to export colors to \(platform.rawValue): \(error.localizedDescription)")
                }
            }
        } catch {
            await progressReporter.error("Failed to load colors: \(error.localizedDescription)")
            for platform in platforms {
                results.append(.failure(platform: platform, assetType: .colors, error: error))
            }
        }

        await progressReporter.endPhase()
        return results
    }

    private func exportColorsToPlatform(
        platform: ExFigCore.Platform,
        colors: ColorsLoaderOutput,
        params: Params
    ) async throws -> Int {
        let processor = ColorsProcessor(
            platform: platform,
            nameValidateRegexp: params.common?.variablesColors?.nameValidateRegexp,
            nameReplaceRegexp: params.common?.variablesColors?.nameReplaceRegexp,
            nameStyle: platform == .ios ? .camelCase : (platform == .android ? .snakeCase : .camelCase)
        )

        let result = processor.process(
            light: colors.light,
            dark: colors.dark,
            lightHC: colors.lightHC,
            darkHC: colors.darkHC
        )
        let colorPairs = try result.get()

        switch platform {
        case .ios:
            try exportColorsToiOS(colorPairs: colorPairs, params: params)
        case .android:
            try exportColorsToAndroid(colorPairs: colorPairs, params: params)
        case .flutter:
            try exportColorsToFlutter(colorPairs: colorPairs, params: params)
        case .web:
            await progressReporter.warning("Web colors export not yet implemented")
        }

        return colorPairs.count
    }

    private func exportColorsToiOS(colorPairs: [AssetPair<Color>], params: Params) throws {
        guard let ios = params.ios, let colorsConfig = ios.colors else {
            throw ExFigKitError.configurationError("iOS colors configuration not found")
        }

        let entry = colorsConfig.entries[0]

        var colorsURL: URL?
        if entry.useColorAssets {
            if let folder = entry.assetsFolder {
                colorsURL = ios.xcassetsPath.appendingPathComponent(folder)
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

        try writeFiles(files)
    }

    private func exportColorsToAndroid(colorPairs: [AssetPair<Color>], params: Params) throws {
        guard let android = params.android, let colorsConfig = android.colors else {
            throw ExFigKitError.configurationError("Android colors configuration not found")
        }

        let entry = colorsConfig.entries[0]

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
        let lightColorsFileURL = android.mainRes.appendingPathComponent("values/" + fileName)
        let darkColorsFileURL = android.mainRes.appendingPathComponent("values-night/" + fileName)
        try? FileManager.default.removeItem(atPath: lightColorsFileURL.path)
        try? FileManager.default.removeItem(atPath: darkColorsFileURL.path)

        try writeFiles(files)
    }

    private func exportColorsToFlutter(colorPairs: [AssetPair<Color>], params: Params) throws {
        guard let flutter = params.flutter, let colorsConfig = flutter.colors else {
            throw ExFigKitError.configurationError("Flutter colors configuration not found")
        }

        let entry = colorsConfig.entries[0]

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

        try writeFiles(files)
    }
}
