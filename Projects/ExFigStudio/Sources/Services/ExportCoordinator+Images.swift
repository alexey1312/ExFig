import ExFigCore
import ExFigKit
import FlutterExport
import Foundation
import XcodeExport

// MARK: - Images Export

extension ExportCoordinator {
    func exportImages(params: Params, platforms: [ExFigCore.Platform]) async throws -> [ExportResult] {
        var results: [ExportResult] = []

        await progressReporter.beginPhase("Loading images from Figma")

        for platform in platforms {
            do {
                let count = try await exportImagesToPlatform(platform: platform, params: params)
                results.append(.success(platform: platform, assetType: .images, count: count))
                await progressReporter.success("Exported \(count) images to \(platform.rawValue)")
            } catch {
                results.append(.failure(platform: platform, assetType: .images, error: error))
                await progressReporter
                    .error("Failed to export images to \(platform.rawValue): \(error.localizedDescription)")
            }
        }

        await progressReporter.endPhase()
        return results
    }

    private func exportImagesToPlatform(
        platform: ExFigCore.Platform,
        params: Params
    ) async throws -> Int {
        await progressReporter.info("Loading images for \(platform.rawValue)...")

        let loader = ImagesLoader(
            client: client,
            params: params,
            platform: platform,
            logger: logger
        )

        let imagesOutput = try await loader.load()
        await progressReporter.info("Loaded \(imagesOutput.light.count) images")

        let processor = ImagesProcessor(
            platform: platform,
            nameValidateRegexp: params.common?.images?.nameValidateRegexp,
            nameReplaceRegexp: params.common?.images?.nameReplaceRegexp,
            nameStyle: nil
        )

        let result = processor.process(light: imagesOutput.light, dark: imagesOutput.dark)
        let images = try result.get()

        await progressReporter.info("Exporting images to \(platform.rawValue)...")

        switch platform {
        case .ios:
            try await exportImagesToiOS(images: images, params: params)
        case .android:
            try await exportImagesToAndroid(images: images, params: params)
        case .flutter:
            try await exportImagesToFlutter(images: images, params: params)
        case .web:
            await progressReporter.warning("Web images export not yet implemented")
        }

        return images.count
    }

    private func exportImagesToiOS(images: [AssetPair<ImagePack>], params: Params) async throws {
        guard let ios = params.ios, let imagesConfig = ios.images else {
            throw ExFigKitError.configurationError("iOS images configuration not found")
        }

        let entry = imagesConfig.entries[0]
        let assetsURL = ios.xcassetsPath.appendingPathComponent(entry.assetsFolder)

        let output = XcodeImagesOutput(
            assetsFolderURL: assetsURL,
            assetsInMainBundle: ios.xcassetsInMainBundle,
            assetsInSwiftPackage: ios.xcassetsInSwiftPackage,
            resourceBundleNames: ios.resourceBundleNames,
            addObjcAttribute: ios.addObjcAttribute,
            preservesVectorRepresentation: nil,
            uiKitImageExtensionURL: entry.imageSwift,
            swiftUIImageExtensionURL: entry.swiftUIImageSwift,
            templatesPath: ios.templatesPath
        )

        let exporter = XcodeImagesExporter(output: output)
        let files = try exporter.export(assets: images, allAssetNames: nil, append: false)

        try? FileManager.default.removeItem(atPath: assetsURL.path)

        let remoteCount = files.filter { $0.sourceURL != nil }.count
        if remoteCount > 0 {
            await progressReporter.info("Downloading \(remoteCount) image files...")
        }
        let downloadedFiles = try await downloadRemoteFiles(files)
        try writeFiles(downloadedFiles)
    }

    /// Export images to Android.
    /// Note: Android images require direct file download and scaling which is handled by CLI.
    /// GUI v1 does not support Android images export yet.
    private func exportImagesToAndroid(images: [AssetPair<ImagePack>], params: Params) async throws {
        guard params.android != nil, params.android?.images != nil else {
            throw ExFigKitError.configurationError("Android images configuration not found")
        }

        await progressReporter.warning("Android images export not yet supported in GUI. Use CLI for full export.")
    }

    private func exportImagesToFlutter(images: [AssetPair<ImagePack>], params: Params) async throws {
        guard let flutter = params.flutter, let imagesConfig = flutter.images else {
            throw ExFigKitError.configurationError("Flutter images configuration not found")
        }

        let entry = imagesConfig.entries[0]
        let imagesAssetsURL = URL(fileURLWithPath: entry.output, relativeTo: flutter.output)

        let output = FlutterOutput(
            outputDirectory: flutter.output,
            imagesAssetsDirectory: imagesAssetsURL,
            templatesPath: flutter.templatesPath,
            imagesClassName: entry.className
        )

        let exporter = FlutterImagesExporter(
            output: output,
            outputFileName: entry.dartFile,
            scales: entry.scales,
            format: entry.format?.rawValue
        )
        let (dartFile, assetFiles) = try exporter.export(images: images, allImageNames: nil)

        let remoteCount = assetFiles.filter { $0.sourceURL != nil }.count
        if remoteCount > 0 {
            await progressReporter.info("Downloading \(remoteCount) image files...")
        }
        let downloadedAssets = try await downloadRemoteFiles(assetFiles)

        try writeFiles([dartFile])
        try writeFiles(downloadedAssets)
    }
}
