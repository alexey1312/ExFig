import AndroidExport
import ExFigCore
import ExFigKit
import FlutterExport
import Foundation
import XcodeExport

// MARK: - Icons Export

extension ExportCoordinator {
    func exportIcons(params: Params, platforms: [ExFigCore.Platform]) async throws -> [ExportResult] {
        var results: [ExportResult] = []

        await progressReporter.beginPhase("Loading icons from Figma")

        for platform in platforms {
            do {
                let count = try await exportIconsToPlatform(platform: platform, params: params)
                results.append(.success(platform: platform, assetType: .icons, count: count))
                await progressReporter.success("Exported \(count) icons to \(platform.rawValue)")
            } catch {
                results.append(.failure(platform: platform, assetType: .icons, error: error))
                await progressReporter
                    .error("Failed to export icons to \(platform.rawValue): \(error.localizedDescription)")
            }
        }

        await progressReporter.endPhase()
        return results
    }

    private func exportIconsToPlatform(
        platform: ExFigCore.Platform,
        params: Params
    ) async throws -> Int {
        await progressReporter.info("Loading icons for \(platform.rawValue)...")

        let loader = IconsLoader(
            client: client,
            params: params,
            platform: platform,
            logger: logger
        )

        let iconsOutput = try await loader.load()
        await progressReporter.info("Loaded \(iconsOutput.light.count) icons")

        let processor = ImagesProcessor(
            platform: platform,
            nameValidateRegexp: params.common?.icons?.nameValidateRegexp,
            nameReplaceRegexp: params.common?.icons?.nameReplaceRegexp,
            nameStyle: nil
        )

        let result = processor.process(light: iconsOutput.light, dark: iconsOutput.dark)
        let icons = try result.get()

        await progressReporter.info("Exporting icons to \(platform.rawValue)...")

        switch platform {
        case .ios:
            try await exportIconsToiOS(icons: icons, params: params)
        case .android:
            try await exportIconsToAndroid(icons: icons, params: params)
        case .flutter:
            try await exportIconsToFlutter(icons: icons, params: params)
        case .web:
            await progressReporter.warning("Web icons export not yet implemented")
        }

        return icons.count
    }

    private func exportIconsToiOS(icons: [AssetPair<ImagePack>], params: Params) async throws {
        guard let ios = params.ios, let iconsConfig = ios.icons else {
            throw ExFigKitError.configurationError("iOS icons configuration not found")
        }

        let entry = iconsConfig.entries[0]
        let assetsURL = ios.xcassetsPath.appendingPathComponent(entry.assetsFolder)

        let output = XcodeImagesOutput(
            assetsFolderURL: assetsURL,
            assetsInMainBundle: ios.xcassetsInMainBundle,
            assetsInSwiftPackage: ios.xcassetsInSwiftPackage,
            resourceBundleNames: ios.resourceBundleNames,
            addObjcAttribute: ios.addObjcAttribute,
            preservesVectorRepresentation: entry.preservesVectorRepresentation,
            uiKitImageExtensionURL: entry.imageSwift,
            swiftUIImageExtensionURL: entry.swiftUIImageSwift,
            templatesPath: ios.templatesPath
        )

        let exporter = XcodeIconsExporter(output: output)
        let files = try exporter.export(icons: icons, allIconNames: nil, append: false)

        try? FileManager.default.removeItem(atPath: assetsURL.path)

        let remoteCount = files.filter { $0.sourceURL != nil }.count
        if remoteCount > 0 {
            await progressReporter.info("Downloading \(remoteCount) icon files...")
        }
        let downloadedFiles = try await downloadRemoteFiles(files)
        try writeFiles(downloadedFiles)
    }

    /// Export icons to Android.
    /// Note: Android icons export requires SVG → VectorDrawable conversion which is complex.
    /// GUI v1 uses direct Compose painterResource pattern.
    private func exportIconsToAndroid(icons: [AssetPair<ImagePack>], params: Params) async throws {
        guard let android = params.android, let iconsConfig = android.icons else {
            throw ExFigKitError.configurationError("Android icons configuration not found")
        }

        let entry = iconsConfig.entries[0]

        let output = AndroidOutput(
            xmlOutputDirectory: android.mainRes,
            xmlResourcePackage: android.resourcePackage,
            srcDirectory: android.mainSrc,
            packageName: entry.composePackageName,
            templatesPath: android.templatesPath
        )

        let exporter = AndroidComposeIconExporter(output: output)
        let iconNames = icons.map(\.light.name)
        if let file = try exporter.exportIcons(iconNames: iconNames, allIconNames: nil) {
            try writeFiles([file])
        }

        await progressReporter
            .warning("Android icons export generates Compose extension only. Use CLI for full VectorDrawable export.")
    }

    private func exportIconsToFlutter(icons: [AssetPair<ImagePack>], params: Params) async throws {
        guard let flutter = params.flutter, let iconsConfig = flutter.icons else {
            throw ExFigKitError.configurationError("Flutter icons configuration not found")
        }

        let entry = iconsConfig.entries[0]
        let iconsAssetsURL = URL(fileURLWithPath: entry.output, relativeTo: flutter.output)

        let output = FlutterOutput(
            outputDirectory: flutter.output,
            iconsAssetsDirectory: iconsAssetsURL,
            templatesPath: flutter.templatesPath,
            iconsClassName: entry.className
        )

        let exporter = FlutterIconsExporter(output: output, outputFileName: entry.dartFile)
        let (dartFile, assetFiles) = try exporter.export(icons: icons, allIconNames: nil)

        let remoteCount = assetFiles.filter { $0.sourceURL != nil }.count
        if remoteCount > 0 {
            await progressReporter.info("Downloading \(remoteCount) icon files...")
        }
        let downloadedAssets = try await downloadRemoteFiles(assetFiles)

        try writeFiles([dartFile])
        try writeFiles(downloadedAssets)
    }
}
