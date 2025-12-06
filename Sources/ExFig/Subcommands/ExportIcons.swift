// swiftlint:disable file_length type_body_length
import AndroidExport
import ArgumentParser
import ExFigCore
import FigmaAPI
import FlutterExport
import Foundation
import SVGKit
import XcodeExport

extension ExFigCommand {
    struct ExportIcons: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "icons",
            abstract: "Exports icons from Figma",
            discussion: "Exports icons from Figma to Xcode / Android Studio project"
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @OptionGroup
        var options: ExFigOptions

        @OptionGroup
        var cacheOptions: CacheOptions

        @OptionGroup
        var faultToleranceOptions: HeavyFaultToleranceOptions

        @Argument(help: """
        [Optional] Name of the icons to export. For example \"ic/24/edit\" \
        to export single icon, \"ic/24/edit, ic/16/notification\" to export several icons and \
        \"ic/16/*\" to export all icons of size 16 pt
        """)
        var filter: String?

        func run() async throws {
            ExFigCommand.initializeTerminalUI(verbose: globalOptions.verbose, quiet: globalOptions.quiet)
            let ui = ExFigCommand.terminalUI!

            let baseClient = FigmaClient(accessToken: options.accessToken, timeout: options.params.figma.timeout)
            let rateLimiter = faultToleranceOptions.createRateLimiter()
            let client = faultToleranceOptions.createRateLimitedClient(
                wrapping: baseClient,
                rateLimiter: rateLimiter,
                onRetry: { attempt, error in
                    ui.warning("Retry \(attempt) after error: \(error.localizedDescription)")
                }
            )

            // Check for version changes if cache is enabled
            let versionCheck = try await VersionTrackingHelper.checkForChanges(
                config: VersionTrackingConfig(
                    client: client,
                    params: options.params,
                    cacheOptions: cacheOptions,
                    configCacheEnabled: options.params.common?.cache?.isEnabled ?? false,
                    configCachePath: options.params.common?.cache?.path,
                    assetType: "Icons",
                    ui: ui,
                    logger: logger
                )
            )

            guard case let .proceed(trackingManager, fileVersions) = versionCheck else {
                return
            }

            if options.params.ios != nil {
                ui.info("Using ExFig \(ExFigCommand.version) to export icons to Xcode project.")
                try await exportiOSIcons(client: client, params: options.params, ui: ui)
            }

            if options.params.android != nil {
                ui.info("Using ExFig \(ExFigCommand.version) to export icons to Android Studio project.")
                try await exportAndroidIcons(client: client, params: options.params, ui: ui)
            }

            if options.params.flutter != nil {
                ui.info("Using ExFig \(ExFigCommand.version) to export icons to Flutter project.")
                try await exportFlutterIcons(client: client, params: options.params, ui: ui)
            }

            // Update cache after successful export
            try VersionTrackingHelper.updateCacheIfNeeded(manager: trackingManager, versions: fileVersions)
        }

        // swiftlint:disable:next function_body_length
        private func exportiOSIcons(client: Client, params: Params, ui: TerminalUI) async throws {
            guard let ios = params.ios,
                  let iconsParams = ios.icons
            else {
                ui.warning("Nothing to do. You haven't specified ios.icons parameters in the config file.")
                return
            }

            let imagesTuple = try await ui.withSpinnerProgress("Fetching icons from Figma...") { onProgress in
                let loader = IconsLoader(client: client, params: params, platform: .ios, logger: logger)
                return try await loader.load(filter: filter, onBatchProgress: onProgress)
            }

            let (icons, iconsWarning): ([AssetPair<ImagesProcessor.AssetType>], AssetsValidatorWarning?) =
                try await ui.withSpinner("Processing icons...") {
                    let processor = ImagesProcessor(
                        platform: .ios,
                        nameValidateRegexp: params.common?.icons?.nameValidateRegexp,
                        nameReplaceRegexp: params.common?.icons?.nameReplaceRegexp,
                        nameStyle: iconsParams.nameStyle
                    )
                    let result = processor.process(light: imagesTuple.light, dark: imagesTuple.dark)
                    return try (result.get(), result.warning)
                }
            if let iconsWarning {
                ui.warning(iconsWarning)
            }

            let assetsURL = ios.xcassetsPath.appendingPathComponent(iconsParams.assetsFolder)

            let output = XcodeImagesOutput(
                assetsFolderURL: assetsURL,
                assetsInMainBundle: ios.xcassetsInMainBundle,
                assetsInSwiftPackage: ios.xcassetsInSwiftPackage,
                resourceBundleNames: ios.resourceBundleNames,
                addObjcAttribute: ios.addObjcAttribute,
                preservesVectorRepresentation: iconsParams.preservesVectorRepresentation,
                uiKitImageExtensionURL: iconsParams.imageSwift,
                swiftUIImageExtensionURL: iconsParams.swiftUIImageSwift,
                templatesPath: ios.templatesPath
            )

            let exporter = XcodeIconsExporter(output: output)
            let localAndRemoteFiles = try exporter.export(icons: icons, append: filter != nil)
            if filter == nil {
                try? FileManager.default.removeItem(atPath: assetsURL.path)
            }

            let remoteFilesCount = localAndRemoteFiles.filter { $0.sourceURL != nil }.count
            let fileDownloader = faultToleranceOptions.createFileDownloader()

            // Download with progress bar
            let localFiles: [FileContents] = if remoteFilesCount > 0 {
                try await ui.withProgress("Downloading icons", total: remoteFilesCount) { progress in
                    try await fileDownloader.fetch(files: localAndRemoteFiles) { current, _ in
                        progress.update(current: current)
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
                ui.success("Done! Exported \(icons.count) icons.")
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

            ui.success("Done! Exported \(icons.count) icons.")
        }

        // swiftlint:disable:next function_body_length
        private func exportAndroidIcons(client: Client, params: Params, ui: TerminalUI) async throws {
            guard let android = params.android, let androidIcons = android.icons else {
                ui.warning("Nothing to do. You haven't specified android.icons parameter in the config file.")
                return
            }

            // Check if ImageVector format is requested
            let composeFormat = androidIcons.composeFormat ?? .resourceReference

            if composeFormat == .imageVector {
                try await exportAndroidIconsAsImageVector(client: client, params: params, ui: ui)
                return
            }

            // 1. Get Icons info
            let imagesTuple = try await ui.withSpinnerProgress("Fetching icons from Figma...") { onProgress in
                let loader = IconsLoader(client: client, params: params, platform: .android, logger: logger)
                return try await loader.load(filter: filter, onBatchProgress: onProgress)
            }

            // 2. Process images
            let (icons, iconsWarning): ([AssetPair<ImagesProcessor.AssetType>], AssetsValidatorWarning?) =
                try await ui.withSpinner("Processing icons...") {
                    let processor = ImagesProcessor(
                        platform: .android,
                        nameValidateRegexp: params.common?.icons?.nameValidateRegexp,
                        nameReplaceRegexp: params.common?.icons?.nameReplaceRegexp,
                        nameStyle: .snakeCase
                    )
                    let result = processor.process(light: imagesTuple.light, dark: imagesTuple.dark)
                    return try (result.get(), result.warning)
                }
            if let iconsWarning {
                ui.warning(iconsWarning)
            }

            // Create empty temp directory
            let tempDirectoryLightURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            let tempDirectoryDarkURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

            // 3. Download SVG files to user's temp directory
            let remoteFiles = icons.flatMap { asset -> [FileContents] in
                let lightFiles = asset.light.images.compactMap { image -> FileContents? in
                    guard let fileURL = URL(string: "\(image.name).svg") else { return nil }
                    let dest = Destination(directory: tempDirectoryLightURL, file: fileURL)
                    return FileContents(destination: dest, sourceURL: image.url, isRTL: image.isRTL)
                }
                let darkFiles = asset.dark?.images.compactMap { image -> FileContents? in
                    guard let fileURL = URL(string: "\(image.name).svg") else { return nil }
                    let dest = Destination(directory: tempDirectoryDarkURL, file: fileURL)
                    return FileContents(destination: dest, sourceURL: image.url, dark: true, isRTL: image.isRTL)
                } ?? []
                return lightFiles + darkFiles
            }

            let fileDownloader = faultToleranceOptions.createFileDownloader()
            var localFiles: [FileContents] = if !remoteFiles.isEmpty {
                try await ui.withProgress("Downloading SVG files", total: remoteFiles.count) { progress in
                    try await fileDownloader.fetch(files: remoteFiles) { current, _ in
                        progress.update(current: current)
                    }
                }
            } else {
                []
            }

            // 4. Move downloaded SVG files to new empty temp directory
            try fileWriter.write(files: localFiles)

            // 5. Convert all SVG to XML files
            let rtlFileNames = Set(remoteFiles.filter(\.isRTL).map {
                $0.destination.file.deletingPathExtension().lastPathComponent
            })

            try await ui.withSpinner("Converting SVGs to vector drawables...") {
                try svgFileConverter.convert(inputDirectoryUrl: tempDirectoryLightURL, rtlFiles: rtlFileNames)
                try svgFileConverter.convert(inputDirectoryUrl: tempDirectoryDarkURL, rtlFiles: rtlFileNames)
            }

            // Create output directory main/res/custom-directory/drawable/
            let lightDirectory = URL(fileURLWithPath: android.mainRes
                .appendingPathComponent(androidIcons.output)
                .appendingPathComponent("drawable", isDirectory: true).path)

            let darkDirectory = URL(fileURLWithPath: android.mainRes
                .appendingPathComponent(androidIcons.output)
                .appendingPathComponent("drawable-night", isDirectory: true).path)

            if filter == nil {
                // Clear output directory
                try? FileManager.default.removeItem(atPath: lightDirectory.path)
                try? FileManager.default.removeItem(atPath: darkDirectory.path)
            }

            // 6. Move XML files to main/res/drawable/
            localFiles = localFiles.map { fileContents -> FileContents in
                let directory = fileContents.dark ? darkDirectory : lightDirectory

                let source = fileContents.destination.url
                    .deletingPathExtension()
                    .appendingPathExtension("xml")

                let fileURL = fileContents.destination.file
                    .deletingPathExtension()
                    .appendingPathExtension("xml")

                return FileContents(
                    destination: Destination(directory: directory, file: fileURL),
                    dataFile: source
                )
            }

            // 7. Create Compose extension if configured
            let output = AndroidOutput(
                xmlOutputDirectory: android.mainRes,
                xmlResourcePackage: android.resourcePackage,
                srcDirectory: android.mainSrc,
                packageName: android.icons?.composePackageName,
                templatesPath: android.templatesPath
            )
            let composeExporter = AndroidComposeIconExporter(output: output)
            let composeIconNames = Set(localFiles.filter { fileContents in
                !fileContents.dark
            }.map { fileContents -> String in
                fileContents.destination.file.deletingPathExtension().lastPathComponent
            })
            let composeFile = try composeExporter.exportIcons(iconNames: Array(composeIconNames).sorted())
            composeFile.map { localFiles.append($0) }

            let filesToWrite = localFiles
            try await ui.withSpinner("Writing files to Android Studio project...") {
                try fileWriter.write(files: filesToWrite)
            }

            try? FileManager.default.removeItem(at: tempDirectoryLightURL)
            try? FileManager.default.removeItem(at: tempDirectoryDarkURL)

            await checkForUpdate(logger: logger)

            ui.success("Done! Exported \(icons.count) icons.")
        }

        // Exports Android icons as Jetpack Compose ImageVector Kotlin files
        // swiftlint:disable:next function_body_length
        private func exportAndroidIconsAsImageVector(client: Client, params: Params, ui: TerminalUI) async throws {
            guard let android = params.android, let androidIcons = android.icons else {
                return
            }

            guard let packageName = androidIcons.composePackageName else {
                ui.warning("composePackageName is required for ImageVector export. Skipping Compose generation.")
                return
            }

            guard let srcDirectory = android.mainSrc else {
                ui.warning("mainSrc is required for ImageVector export. Skipping Compose generation.")
                return
            }

            // 1. Get Icons info
            let imagesTuple = try await ui.withSpinnerProgress("Fetching icons from Figma...") { onProgress in
                let loader = IconsLoader(client: client, params: params, platform: .android, logger: logger)
                return try await loader.load(filter: filter, onBatchProgress: onProgress)
            }

            // 2. Process images
            let (icons, iconsWarning): ([AssetPair<ImagesProcessor.AssetType>], AssetsValidatorWarning?) =
                try await ui.withSpinner("Processing icons...") {
                    let processor = ImagesProcessor(
                        platform: .android,
                        nameValidateRegexp: params.common?.icons?.nameValidateRegexp,
                        nameReplaceRegexp: params.common?.icons?.nameReplaceRegexp,
                        nameStyle: .snakeCase
                    )
                    let result = processor.process(light: imagesTuple.light, dark: imagesTuple.dark)
                    return try (result.get(), result.warning)
                }
            if let iconsWarning {
                ui.warning(iconsWarning)
            }

            // Create temp directory for SVG files
            let tempDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

            // 3. Download SVG files to temp directory
            let remoteFiles = icons.flatMap { asset -> [FileContents] in
                asset.light.images.compactMap { image -> FileContents? in
                    guard let fileURL = URL(string: "\(image.name).svg") else { return nil }
                    let dest = Destination(directory: tempDirectoryURL, file: fileURL)
                    return FileContents(destination: dest, sourceURL: image.url, isRTL: image.isRTL)
                }
            }

            let fileDownloader = faultToleranceOptions.createFileDownloader()
            let localFiles: [FileContents] = if !remoteFiles.isEmpty {
                try await ui.withProgress("Downloading SVG files", total: remoteFiles.count) { progress in
                    try await fileDownloader.fetch(files: remoteFiles) { current, _ in
                        progress.update(current: current)
                    }
                }
            } else {
                []
            }

            try fileWriter.write(files: localFiles)

            // 4. Convert SVGs to ImageVector Kotlin files
            let kotlinFiles = try await ui.withSpinner("Converting SVGs to ImageVector...") {
                let outputDirectory = srcDirectory.appendingPathComponent(
                    packageName.replacingOccurrences(of: ".", with: "/")
                )

                let exporter = AndroidImageVectorExporter(
                    outputDirectory: outputDirectory,
                    config: .init(
                        packageName: packageName,
                        extensionTarget: androidIcons.composeExtensionTarget,
                        generatePreview: true,
                        colorMappings: [:]
                    )
                )

                // Collect SVG data from temp files
                var svgFiles: [String: Data] = [:]
                for file in localFiles {
                    let iconName = file.destination.file.deletingPathExtension().lastPathComponent
                    if let data = try? Data(contentsOf: file.destination.url) {
                        svgFiles[iconName] = data
                    }
                }

                let files = try exporter.export(svgFiles: svgFiles)

                // Clear output directory if not filtering
                if filter == nil {
                    try? FileManager.default.removeItem(atPath: outputDirectory.path)
                }

                return files
            }

            try await ui.withSpinner("Writing Kotlin files to Android Studio project...") {
                try fileWriter.write(files: kotlinFiles)
            }

            // Cleanup temp directory
            try? FileManager.default.removeItem(at: tempDirectoryURL)

            await checkForUpdate(logger: logger)

            ui.success("Done! Generated \(kotlinFiles.count) ImageVector files.")
        }

        private func exportFlutterIcons(client: Client, params: Params, ui: TerminalUI) async throws {
            guard let flutter = params.flutter, let flutterIcons = flutter.icons else {
                ui.warning("Nothing to do. You haven't specified flutter.icons parameter in the config file.")
                return
            }

            // 1. Get Icons info
            let imagesTuple = try await ui.withSpinnerProgress("Fetching icons from Figma...") { onProgress in
                let loader = IconsLoader(client: client, params: params, platform: .android, logger: logger)
                return try await loader.load(filter: filter, onBatchProgress: onProgress)
            }

            // 2. Process images
            let (icons, iconsWarning): ([AssetPair<ImagesProcessor.AssetType>], AssetsValidatorWarning?) =
                try await ui.withSpinner("Processing icons...") {
                    let processor = ImagesProcessor(
                        platform: .android, // Flutter uses similar naming to Android
                        nameValidateRegexp: params.common?.icons?.nameValidateRegexp,
                        nameReplaceRegexp: params.common?.icons?.nameReplaceRegexp,
                        nameStyle: .snakeCase
                    )
                    let result = processor.process(light: imagesTuple.light, dark: imagesTuple.dark)
                    return try (result.get(), result.warning)
                }
            if let iconsWarning {
                ui.warning(iconsWarning)
            }

            // 3. Export icons
            let assetsDirectory = URL(fileURLWithPath: flutterIcons.output)
            let output = FlutterOutput(
                outputDirectory: flutter.output,
                iconsAssetsDirectory: assetsDirectory,
                templatesPath: flutter.templatesPath,
                iconsClassName: flutterIcons.className
            )

            let exporter = FlutterIconsExporter(output: output, outputFileName: flutterIcons.dartFile)
            let (dartFile, assetFiles) = try exporter.export(icons: icons)

            // 4. Download SVG files
            let remoteFiles = assetFiles.filter { $0.sourceURL != nil }
            let fileDownloader = faultToleranceOptions.createFileDownloader()

            var localFiles: [FileContents] = if !remoteFiles.isEmpty {
                try await ui.withProgress("Downloading SVG files", total: remoteFiles.count) { progress in
                    try await fileDownloader.fetch(files: remoteFiles) { current, _ in
                        progress.update(current: current)
                    }
                }
            } else {
                []
            }

            // Clear output directory if not filtering
            if filter == nil {
                try? FileManager.default.removeItem(atPath: assetsDirectory.path)
            }

            // 5. Write files
            localFiles.append(dartFile)

            let filesToWrite = localFiles
            try await ui.withSpinner("Writing files to Flutter project...") {
                try fileWriter.write(files: filesToWrite)
            }

            await checkForUpdate(logger: logger)

            ui.success("Done! Exported \(icons.count) icons to Flutter project.")
        }
    }
}
