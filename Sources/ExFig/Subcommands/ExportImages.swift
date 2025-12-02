import AndroidExport
import ArgumentParser
import ExFigCore
import FigmaAPI
import Foundation
import XcodeExport

extension ExFigCommand {
    // swiftlint:disable:next type_body_length
    struct ExportImages: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "images",
            abstract: "Exports images from Figma",
            discussion: "Exports images from Figma to Xcode / Android Studio project"
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @OptionGroup
        var options: ExFigOptions

        @Argument(help: """
        [Optional] Name of the images to export. For example \"img/login\" to export \
        single image, \"img/onboarding/1, img/onboarding/2\" to export several images \
        and \"img/onboarding/*\" to export all images from onboarding group
        """)
        var filter: String?

        func run() async throws {
            ExFigCommand.initializeTerminalUI(verbose: globalOptions.verbose, quiet: globalOptions.quiet)
            let ui = ExFigCommand.terminalUI!

            let client = FigmaClient(accessToken: options.accessToken, timeout: options.params.figma.timeout)

            if options.params.ios != nil {
                ui.info("Using ExFig \(ExFigCommand.version) to export images to Xcode project.")
                try await exportiOSImages(client: client, params: options.params, ui: ui)
            }

            if options.params.android != nil {
                ui.info("Using ExFig \(ExFigCommand.version) to export images to Android Studio project.")
                try await exportAndroidImages(client: client, params: options.params, ui: ui)
            }
        }

        // swiftlint:disable:next function_body_length
        private func exportiOSImages(client: Client, params: Params, ui: TerminalUI) async throws {
            guard let ios = params.ios,
                  let imagesParams = ios.images
            else {
                ui.warning("Nothing to do. You haven't specified ios.images parameters in the config file.")
                return
            }

            let imagesTuple = try await ui.withSpinner("Fetching images from Figma...") {
                let loader = ImagesLoader(client: client, params: params, platform: .ios, logger: logger)
                return try await loader.load(filter: filter)
            }

            let images = try await ui.withSpinner("Processing images...") {
                let processor = ImagesProcessor(
                    platform: .ios,
                    nameValidateRegexp: params.common?.images?.nameValidateRegexp,
                    nameReplaceRegexp: params.common?.images?.nameReplaceRegexp,
                    nameStyle: imagesParams.nameStyle
                )
                let result = processor.process(light: imagesTuple.light, dark: imagesTuple.dark)
                if let warning = result.warning?.errorDescription {
                    ui.warning(warning)
                }
                return try result.get()
            }

            let assetsURL = ios.xcassetsPath.appendingPathComponent(imagesParams.assetsFolder)

            let output = XcodeImagesOutput(
                assetsFolderURL: assetsURL,
                assetsInMainBundle: ios.xcassetsInMainBundle,
                assetsInSwiftPackage: ios.xcassetsInSwiftPackage,
                resourceBundleNames: ios.resourceBundleNames,
                addObjcAttribute: ios.addObjcAttribute,
                uiKitImageExtensionURL: imagesParams.imageSwift,
                swiftUIImageExtensionURL: imagesParams.swiftUIImageSwift,
                templatesPath: ios.templatesPath
            )

            let exporter = XcodeImagesExporter(output: output)
            let localAndRemoteFiles = try exporter.export(assets: images, append: filter != nil)
            if filter == nil {
                try? FileManager.default.removeItem(atPath: assetsURL.path)
            }

            let remoteFilesCount = localAndRemoteFiles.filter { $0.sourceURL != nil }.count

            // Download with progress bar
            let localFiles: [FileContents] = if remoteFilesCount > 0 {
                try await ui.withProgress("Downloading images", total: remoteFilesCount) { progress in
                    try await fileDownloader.fetch(files: localAndRemoteFiles) { current, _ in
                        await progress.update(current: current)
                    }
                }
            } else {
                localAndRemoteFiles
            }

            try await ui.withSpinner("Writing files to Xcode project...") {
                try fileWriter.write(files: localFiles)
            }

            guard params.ios?.xcassetsInSwiftPackage == false else {
                await checkForUpdate(logger: logger)
                ui.success("Done! Exported \(images.count) images.")
                return
            }

            do {
                let xcodeProject = try XcodeProjectWriter(xcodeProjPath: ios.xcodeprojPath, target: ios.target)
                try localFiles.forEach { file in
                    if file.destination.file.pathExtension == "swift" {
                        try xcodeProject.addFileReferenceToXcodeProj(file.destination.url)
                    }
                }
                try xcodeProject.save()
            } catch {
                ui.warning("Unable to add some file references to Xcode project")
            }

            await checkForUpdate(logger: logger)

            ui.success("Done! Exported \(images.count) images.")
        }

        // swiftlint:disable:next function_body_length
        private func exportAndroidImages(client: Client, params: Params, ui: TerminalUI) async throws {
            guard let androidImages = params.android?.images else {
                ui.warning("Nothing to do. You haven't specified android.images parameter in the config file.")
                return
            }

            let imagesTuple = try await ui.withSpinner("Fetching images from Figma...") {
                let loader = ImagesLoader(client: client, params: params, platform: .android, logger: logger)
                return try await loader.load(filter: filter)
            }

            let images = try await ui.withSpinner("Processing images...") {
                let processor = ImagesProcessor(
                    platform: .android,
                    nameValidateRegexp: params.common?.images?.nameValidateRegexp,
                    nameReplaceRegexp: params.common?.images?.nameReplaceRegexp,
                    nameStyle: .snakeCase
                )
                let result = processor.process(light: imagesTuple.light, dark: imagesTuple.dark)
                if let warning = result.warning?.errorDescription {
                    ui.warning(warning)
                }
                return try result.get()
            }

            switch androidImages.format {
            case .svg:
                try await exportAndroidSVGImages(images: images, params: params, ui: ui)
            case .png, .webp:
                try await exportAndroidRasterImages(images: images, params: params, ui: ui)
            }

            await checkForUpdate(logger: logger)

            ui.success("Done! Exported \(images.count) images.")
        }

        // swiftlint:disable:next function_body_length
        private func exportAndroidSVGImages(
            images: [AssetPair<ImagesProcessor.AssetType>],
            params: Params,
            ui: TerminalUI
        ) async throws {
            guard let android = params.android, let androidImages = android.images else {
                ui.warning("Nothing to do. You haven't specified android.images parameter in the config file.")
                return
            }

            // Create empty temp directory
            let tempDirectoryLightURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            let tempDirectoryDarkURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

            // Download SVG files to user's temp directory
            let remoteFiles = images.flatMap { asset -> [FileContents] in
                let lightFiles = asset.light.images.compactMap { image -> FileContents? in
                    guard let fileURL = URL(string: "\(image.name).svg") else { return nil }
                    let dest = Destination(directory: tempDirectoryLightURL, file: fileURL)
                    return FileContents(destination: dest, sourceURL: image.url)
                }
                let darkFiles = asset.dark?.images.compactMap { image -> FileContents? in
                    guard let fileURL = URL(string: "\(image.name).svg") else { return nil }
                    let dest = Destination(directory: tempDirectoryDarkURL, file: fileURL)
                    return FileContents(destination: dest, sourceURL: image.url, dark: true)
                } ?? []
                return lightFiles + darkFiles
            }

            var localFiles: [FileContents] = if !remoteFiles.isEmpty {
                try await ui.withProgress("Downloading SVG files", total: remoteFiles.count) { progress in
                    try await fileDownloader.fetch(files: remoteFiles) { current, _ in
                        await progress.update(current: current)
                    }
                }
            } else {
                []
            }

            // Move downloaded SVG files to new empty temp directory
            try fileWriter.write(files: localFiles)

            // Convert all SVG to XML files
            try await ui.withSpinner("Converting SVGs to vector drawables...") {
                try svgFileConverter.convert(inputDirectoryUrl: tempDirectoryLightURL)
                if images.first?.dark != nil {
                    try svgFileConverter.convert(inputDirectoryUrl: tempDirectoryDarkURL)
                }
            }

            // Create output directory main/res/drawable/
            let lightDirectory = URL(fileURLWithPath: android.mainRes
                .appendingPathComponent(androidImages.output)
                .appendingPathComponent("drawable", isDirectory: true).path)

            let darkDirectory = URL(fileURLWithPath: android.mainRes
                .appendingPathComponent(androidImages.output)
                .appendingPathComponent("drawable-night", isDirectory: true).path)

            if filter == nil {
                // Clear output directory
                try? FileManager.default.removeItem(atPath: lightDirectory.path)
                try? FileManager.default.removeItem(atPath: darkDirectory.path)
            }

            // Move XML files to main/res/drawable/
            localFiles = localFiles.map { fileContents -> FileContents in
                let source = fileContents.destination.url
                    .deletingPathExtension()
                    .appendingPathExtension("xml")

                let fileURL = fileContents.destination.file
                    .deletingPathExtension()
                    .appendingPathExtension("xml")

                let directory = fileContents.dark ? darkDirectory : lightDirectory

                return FileContents(
                    destination: Destination(directory: directory, file: fileURL),
                    dataFile: source
                )
            }

            let filesToWrite = localFiles
            try await ui.withSpinner("Writing files to Android Studio project...") {
                try fileWriter.write(files: filesToWrite)
            }

            try? FileManager.default.removeItem(at: tempDirectoryLightURL)
            try? FileManager.default.removeItem(at: tempDirectoryDarkURL)
        }

        // swiftlint:disable:next function_body_length
        private func exportAndroidRasterImages(
            images: [AssetPair<ImagesProcessor.AssetType>],
            params: Params,
            ui: TerminalUI
        ) async throws {
            guard let android = params.android, let androidImages = android.images else {
                ui.warning("Nothing to do. You haven't specified android.images parameter in the config file.")
                return
            }

            // Create empty temp directory
            let tempDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

            // Download files to user's temp directory
            let remoteFiles = try images.flatMap { asset -> [FileContents] in
                let lightFiles = try makeRemoteFiles(
                    images: asset.light.images,
                    dark: false,
                    outputDirectory: tempDirectoryURL
                )
                let darkFiles = try asset.dark.flatMap { darkImagePack -> [FileContents] in
                    try makeRemoteFiles(images: darkImagePack.images, dark: true, outputDirectory: tempDirectoryURL)
                } ?? []
                return lightFiles + darkFiles
            }

            var localFiles: [FileContents] = if !remoteFiles.isEmpty {
                try await ui.withProgress("Downloading images", total: remoteFiles.count) { progress in
                    try await fileDownloader.fetch(files: remoteFiles) { current, _ in
                        await progress.update(current: current)
                    }
                }
            } else {
                []
            }

            // Move downloaded files to new empty temp directory
            try fileWriter.write(files: localFiles)

            // Convert to WebP
            if androidImages.format == .webp, let options = androidImages.webpOptions {
                let converter: WebpConverter
                switch (options.encoding, options.quality) {
                case (.lossless, _):
                    converter = WebpConverter(encoding: .lossless)
                case let (.lossy, quality?):
                    converter = WebpConverter(encoding: .lossy(quality: quality))
                case (.lossy, .none):
                    fatalError("Encoding quality not specified. Set android.images.webpOptions.quality in YAML file.")
                }
                let filesToConvert = localFiles.map(\.destination.url)
                try await ui.withProgress("Converting to WebP", total: filesToConvert.count) { progress in
                    try await converter.convertBatch(files: filesToConvert) { current, _ in
                        await progress.update(current: current)
                    }
                }
                localFiles = localFiles.map { $0.changingExtension(newExtension: "webp") }
            }

            if filter == nil {
                // Clear output directory
                let outputDirectory = URL(fileURLWithPath: android.mainRes.appendingPathComponent(androidImages.output)
                    .path)
                try? FileManager.default.removeItem(atPath: outputDirectory.path)
            }

            // Move PNG/WebP files to main/res/exfig-images/drawable-XXXdpi/
            let isSingleScale = params.android?.images?.scales?.count == 1
            localFiles = localFiles.map { fileContents -> FileContents in
                let directoryName = Drawable.scaleToDrawableName(
                    fileContents.scale,
                    dark: fileContents.dark,
                    singleScale: isSingleScale
                )
                let directory = URL(fileURLWithPath: android.mainRes.appendingPathComponent(androidImages.output).path)
                    .appendingPathComponent(directoryName, isDirectory: true)
                return FileContents(
                    destination: Destination(directory: directory, file: fileContents.destination.file),
                    dataFile: fileContents.destination.url
                )
            }

            let filesToWriteRaster = localFiles
            try await ui.withSpinner("Writing files to Android Studio project...") {
                try fileWriter.write(files: filesToWriteRaster)
            }

            try? FileManager.default.removeItem(at: tempDirectoryURL)
        }

        /// Make array of remote FileContents for downloading images
        /// - Parameters:
        ///   - images: Dictionary of images. Key = scale, value = image info
        ///   - dark: Dark mode?
        ///   - outputDirectory: URL of the output directory
        private func makeRemoteFiles(images: [Image], dark: Bool, outputDirectory: URL) throws -> [FileContents] {
            try images.map { image -> FileContents in
                guard let name = image.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                      let fileURL = URL(string: "\(name).\(image.format)")
                else {
                    throw ExFigError.invalidFileName(image.name)
                }
                let scale = image.scale.value
                let dest = Destination(
                    directory: outputDirectory
                        .appendingPathComponent(dark ? "dark" : "light")
                        .appendingPathComponent(String(scale)),
                    file: fileURL
                )
                return FileContents(destination: dest, sourceURL: image.url, scale: scale, dark: dark)
            }
        }
    }
}
