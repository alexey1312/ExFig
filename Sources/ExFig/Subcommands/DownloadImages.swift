// swiftlint:disable file_length
import ArgumentParser
import ExFigCore
import FigmaAPI
import Foundation
import Logging

extension ExFigCommand {
    struct DownloadImages: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "download",
            abstract: "Downloads images from Figma without config file",
            discussion: """
            Downloads images from a specific Figma frame to a local directory.
            All parameters are passed via command-line arguments.

            Examples:
              # Download PNGs at 3x scale (default)
              exfig download --file-id abc123 --frame "Illustrations" --output ./images

              # Download SVGs
              exfig download -f abc123 -r "Icons" -o ./icons --format svg

              # Download with filtering
              exfig download -f abc123 -r "Images" -o ./images --filter "logo/*"

              # Download PNG at 2x scale with camelCase naming
              exfig download -f abc123 -r "Images" -o ./images --scale 2 --name-style camelCase

              # Download with dark mode variants
              exfig download -f abc123 -r "Images" -o ./images --dark-mode-suffix "_dark"

              # Download as WebP with quality settings
              exfig download -f abc123 -r "Images" -o ./images --format webp --webp-quality 90
            """
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @OptionGroup
        var downloadOptions: DownloadOptions

        func run() async throws {
            // Initialize terminal UI
            ExFigCommand.initializeTerminalUI(verbose: globalOptions.verbose, quiet: globalOptions.quiet)
            let ui = ExFigCommand.terminalUI!

            // Validate access token
            guard let accessToken = downloadOptions.accessToken else {
                throw ExFigError.accessTokenNotFound
            }

            // Create output directory if needed
            let outputURL = downloadOptions.outputURL
            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

            ui.info("Downloading images from Figma...")
            ui.debug("File ID: \(downloadOptions.fileId)")
            ui.debug("Frame: \(downloadOptions.frameName)")
            ui.debug("Output: \(outputURL.path)")
            ui.debug("Format: \(downloadOptions.format.rawValue)")
            if !downloadOptions.isVectorFormat {
                ui.debug("Scale: \(downloadOptions.effectiveScale)x")
            }

            // Create Figma client
            let client = FigmaClient(accessToken: accessToken, timeout: TimeInterval(downloadOptions.timeout))

            // Create loader
            let loader = DownloadImageLoader(
                client: client,
                logger: ExFigCommand.logger
            )

            // Load images from Figma
            let imagePacks = try await ui.withSpinner("Fetching images from Figma...") {
                try await loadImages(using: loader)
            }

            guard !imagePacks.isEmpty else {
                ui.warning("No images found in frame '\(downloadOptions.frameName)'")
                return
            }

            ui.info("Found \(imagePacks.count) images")

            // Process names if needed
            let processedPacks = processNames(imagePacks)

            // Handle dark mode if suffix is specified
            let (lightPacks, darkPacks) = splitByDarkMode(processedPacks)

            // Create file contents for download
            var allFiles = createFileContents(from: lightPacks, dark: false)
            if let darkPacks {
                allFiles += createFileContents(from: darkPacks, dark: true)
            }
            let filesToDownload = allFiles

            // Download files with progress
            ui.info("Downloading \(filesToDownload.count) files...")
            let downloadedFiles = try await ui.withProgress("Downloading", total: filesToDownload.count) { progress in
                try await ExFigCommand.fileDownloader.fetch(files: filesToDownload) { current, _ in
                    await progress.update(current: current)
                }
            }

            // Convert to WebP if needed
            let finalFiles: [FileContents] = if downloadOptions.format == .webp {
                try await convertToWebP(downloadedFiles, ui: ui)
            } else {
                downloadedFiles
            }

            // Write files to disk
            try await ui.withSpinner("Writing files...") {
                try await ExFigCommand.fileWriter.writeParallel(files: finalFiles)
            }

            ui.success("Downloaded \(finalFiles.count) images to \(outputURL.path)")
        }

        // MARK: - Private Methods

        private func loadImages(using loader: DownloadImageLoader) async throws -> [ImagePack] {
            if downloadOptions.isVectorFormat {
                let params: FormatParams = downloadOptions.format == .svg ? SVGParams() : PDFParams()
                return try await loader.loadVectorImages(
                    fileId: downloadOptions.fileId,
                    frameName: downloadOptions.frameName,
                    params: params,
                    filter: downloadOptions.filter
                )
            } else {
                return try await loader.loadRasterImages(
                    fileId: downloadOptions.fileId,
                    frameName: downloadOptions.frameName,
                    scale: downloadOptions.effectiveScale,
                    format: downloadOptions.format.rawValue,
                    filter: downloadOptions.filter
                )
            }
        }

        private func processNames(_ packs: [ImagePack]) -> [ImagePack] {
            packs.map { pack in
                var processed = pack

                // Apply regex replacement if both patterns are specified
                if let validateRegexp = downloadOptions.nameValidateRegexp,
                   let replaceRegexp = downloadOptions.nameReplaceRegexp
                {
                    // Normalize path separators
                    var name = pack.name.replacingOccurrences(of: "/", with: "_")
                    // Apply regex replacement
                    if let regex = try? NSRegularExpression(pattern: validateRegexp) {
                        let range = NSRange(name.startIndex..., in: name)
                        name = regex.stringByReplacingMatches(
                            in: name,
                            range: range,
                            withTemplate: replaceRegexp
                        )
                    }
                    processed.name = name
                } else {
                    // Just normalize path separators
                    processed.name = pack.name.replacingOccurrences(of: "/", with: "_")
                }

                // Apply name style
                if let nameStyle = downloadOptions.nameStyle {
                    switch nameStyle {
                    case .camelCase:
                        processed.name = processed.name.lowerCamelCased()
                    case .snakeCase:
                        processed.name = processed.name.snakeCased()
                    case .pascalCase:
                        processed.name = processed.name.camelCased()
                    case .kebabCase:
                        processed.name = processed.name.kebabCased()
                    case .screamingSnakeCase:
                        processed.name = processed.name.screamingSnakeCased()
                    }
                }

                return processed
            }
        }

        private func splitByDarkMode(_ packs: [ImagePack]) -> (light: [ImagePack], dark: [ImagePack]?) {
            guard let darkSuffix = downloadOptions.darkModeSuffix else {
                return (packs, nil)
            }

            let lightPacks = packs.filter { !$0.name.hasSuffix(darkSuffix) }
            let darkPacks = packs
                .filter { $0.name.hasSuffix(darkSuffix) }
                .map { pack -> ImagePack in
                    var newPack = pack
                    newPack.name = String(pack.name.dropLast(darkSuffix.count))
                    return newPack
                }

            return (lightPacks, darkPacks.isEmpty ? nil : darkPacks)
        }

        private func createFileContents(from packs: [ImagePack], dark: Bool) -> [FileContents] {
            let outputURL = downloadOptions.outputURL
            let fileExtension = downloadOptions.format == .webp ? "png" : downloadOptions.format.rawValue

            return packs.flatMap { pack -> [FileContents] in
                pack.images.map { image -> FileContents in
                    var fileName = pack.name
                    if dark {
                        fileName += downloadOptions.darkModeSuffix ?? "_dark"
                    }
                    fileName += ".\(fileExtension)"

                    let destination = Destination(
                        directory: outputURL,
                        file: URL(fileURLWithPath: fileName)
                    )

                    return FileContents(
                        destination: destination,
                        sourceURL: image.url,
                        scale: image.scale.value,
                        dark: dark
                    )
                }
            }
        }

        private func convertToWebP(_ files: [FileContents], ui: TerminalUI) async throws -> [FileContents] {
            let encoding: WebpConverter.Encoding = switch downloadOptions.webpEncoding {
            case .lossy:
                .lossy(quality: downloadOptions.webpQuality)
            case .lossless:
                .lossless
            }

            let converter = WebpConverter(encoding: encoding)

            // Get list of downloaded PNG files to convert
            let pngFiles = files.compactMap(\.dataFile)

            guard !pngFiles.isEmpty else {
                return files
            }

            try await ui.withSpinner("Converting to WebP...") {
                try await converter.convertBatch(files: pngFiles)
            }

            // Update file contents with WebP extension
            return files.map { file in
                file.changingExtension(newExtension: "webp")
            }
        }
    }
}

// MARK: - Download Image Loader

/// Simplified image loader for the download command.
/// Does not depend on Params struct - uses direct parameters.
private final class DownloadImageLoader: @unchecked Sendable {
    private let client: Client
    private let logger: Logger

    init(client: Client, logger: Logger) {
        self.client = client
        self.logger = logger
    }

    /// Loads vector images (SVG/PDF) from Figma.
    func loadVectorImages(
        fileId: String,
        frameName: String,
        params: FormatParams,
        filter: String?
    ) async throws -> [ImagePack] {
        var imagesDict = try await fetchImageComponents(fileId: fileId, frameName: frameName, filter: filter)

        guard !imagesDict.isEmpty else {
            throw ExFigError.componentsNotFound
        }

        // Filter out empty names
        imagesDict = imagesDict.filter { (_: NodeId, component: Component) in
            !component.name.trimmingCharacters(in: .whitespaces).isEmpty
        }

        logger.info("Fetching vector images...")
        let imageIdToImagePath = try await loadImages(fileId: fileId, imagesDict: imagesDict, params: params)

        // Remove components for which image file could not be fetched
        let badNodeIds = Set(imagesDict.keys).symmetricDifference(Set(imageIdToImagePath.keys))
        for nodeId in badNodeIds {
            imagesDict.removeValue(forKey: nodeId)
        }

        // Create image packs
        return imagesDict.compactMap { nodeId, component -> ImagePack? in
            guard let urlString = imageIdToImagePath[nodeId],
                  let url = URL(string: urlString)
            else {
                return nil
            }
            let image = Image(
                name: component.name,
                scale: .all,
                url: url,
                format: params.format
            )
            return ImagePack(name: component.name, images: [image], platform: nil)
        }
    }

    /// Loads raster images (PNG/JPG) from Figma at a specific scale.
    func loadRasterImages(
        fileId: String,
        frameName: String,
        scale: Double,
        format: String,
        filter: String?
    ) async throws -> [ImagePack] {
        let imagesDict = try await fetchImageComponents(fileId: fileId, frameName: frameName, filter: filter)

        guard !imagesDict.isEmpty else {
            throw ExFigError.componentsNotFound
        }

        logger.info("Fetching raster images at \(scale)x...")
        let params = FormatParams(scale: scale, format: format)
        let imageIdToImagePath = try await loadImages(fileId: fileId, imagesDict: imagesDict, params: params)

        // Create image packs
        return imagesDict.compactMap { nodeId, component -> ImagePack? in
            guard let urlString = imageIdToImagePath[nodeId],
                  let url = URL(string: urlString)
            else {
                return nil
            }

            let image = Image(
                name: component.name,
                scale: .individual(scale),
                url: url,
                format: format
            )
            return ImagePack(name: component.name, images: [image], platform: nil)
        }
    }

    // MARK: - Private Methods

    private func fetchImageComponents(
        fileId: String,
        frameName: String,
        filter: String?
    ) async throws -> [NodeId: Component] {
        var components = try await loadComponents(fileId: fileId)
            .filter { $0.containingFrame.name == frameName }

        if let filter {
            let assetsFilter = AssetsFilter(filter: filter)
            components = components.filter { component -> Bool in
                assetsFilter.match(name: component.name)
            }
        }

        return Dictionary(uniqueKeysWithValues: components.map { ($0.nodeId, $0) })
    }

    private func loadComponents(fileId: String) async throws -> [Component] {
        let endpoint = ComponentsEndpoint(fileId: fileId)
        return try await client.request(endpoint)
    }

    private func loadImages(
        fileId: String,
        imagesDict: [NodeId: Component],
        params: FormatParams
    ) async throws -> [NodeId: ImagePath] {
        let batchSize = 100
        let maxConcurrentBatches = 3

        let nodeIds: [NodeId] = imagesDict.keys.map { $0 }
        let batches = nodeIds.chunked(into: batchSize)

        let format = params.format
        let scale = params.scale

        let allResults = try await withThrowingTaskGroup(
            of: [(NodeId, ImagePath)].self
        ) { [self] group in
            var results: [[(NodeId, ImagePath)]] = []
            var activeTasks = 0

            for batch in batches {
                if activeTasks >= maxConcurrentBatches {
                    if let batchResult = try await group.next() {
                        results.append(batchResult)
                        activeTasks -= 1
                    }
                }

                group.addTask { [batch, fileId, format, scale, imagesDict] in
                    try await self.loadImageBatch(
                        fileId: fileId,
                        nodeIds: batch,
                        format: format,
                        scale: scale,
                        imagesDict: imagesDict
                    )
                }
                activeTasks += 1
            }

            for try await batchResult in group {
                results.append(batchResult)
            }

            return results.flatMap { $0 }
        }

        return Dictionary(uniqueKeysWithValues: allResults)
    }

    private func loadImageBatch(
        fileId: String,
        nodeIds: [NodeId],
        format: String,
        scale: Double?,
        imagesDict: [NodeId: Component]
    ) async throws -> [(NodeId, ImagePath)] {
        let params: FormatParams = switch format {
        case "svg": SVGParams()
        case "pdf": PDFParams()
        case "png" where scale != nil: PNGParams(scale: scale!)
        default: FormatParams(scale: scale, format: format)
        }

        let endpoint = ImageEndpoint(fileId: fileId, nodeIds: nodeIds, params: params)
        let dict = try await client.request(endpoint)

        return dict.compactMap { nodeId, imagePath in
            if let imagePath {
                return (nodeId, imagePath)
            } else {
                let componentName = imagesDict[nodeId]?.name ?? ""
                logger.error("Unable to get image for component '\(componentName)'. Skipping...")
                return nil
            }
        }
    }
}
