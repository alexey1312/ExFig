import ArgumentParser
import ExFigCore
import FigmaAPI
import Foundation
import Logging

extension ExFigCommand {
    struct FetchImages: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "fetch",
            abstract: "Downloads images from Figma without config file",
            discussion: """
            Downloads images from a specific Figma frame to a local directory.
            All parameters are passed via command-line arguments.

            Examples:
              # Download PNGs at 3x scale (default)
              exfig fetch --file-id abc123 --frame "Illustrations" --output ./images

              # Download SVGs
              exfig fetch -f abc123 -r "Icons" -o ./icons --format svg

              # Download PDFs
              exfig fetch -f abc123 -r "Icons" -o ./icons --format pdf

              # Download with filtering
              exfig fetch -f abc123 -r "Images" -o ./images --filter "logo/*"

              # Download PNG at 2x scale with camelCase naming
              exfig fetch -f abc123 -r "Images" -o ./images --scale 2 --name-style camelCase

              # Download with dark mode variants
              exfig fetch -f abc123 -r "Images" -o ./images --dark-mode-suffix "_dark"

              # Download as WebP with quality settings
              exfig fetch -f abc123 -r "Images" -o ./images --format webp --webp-quality 90
            """
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @OptionGroup
        var downloadOptions: DownloadOptions

        @OptionGroup
        var faultToleranceOptions: HeavyFaultToleranceOptions

        // swiftlint:disable:next function_body_length
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

            // Create Figma client with fault tolerance
            let baseClient = FigmaClient(accessToken: accessToken, timeout: TimeInterval(downloadOptions.timeout))
            let rateLimiter = faultToleranceOptions.createRateLimiter()
            let maxRetries = faultToleranceOptions.maxRetries
            let client = faultToleranceOptions.createRateLimitedClient(
                wrapping: baseClient,
                rateLimiter: rateLimiter,
                onRetry: { attempt, error in
                    let warning = ExFigWarning.retrying(
                        attempt: attempt,
                        maxAttempts: maxRetries,
                        error: error.localizedDescription,
                        delay: "..."
                    )
                    ui.warning(warning)
                }
            )

            // Create loader
            let loader = DownloadImageLoader(
                client: client,
                logger: ExFigCommand.logger
            )

            // Load images from Figma
            let imagePacks = try await ui.withSpinnerProgress("Fetching images from Figma...") { onProgress in
                try await loadImages(using: loader, onBatchProgress: onProgress)
            }

            guard !imagePacks.isEmpty else {
                ui.warning(.noAssetsFound(assetType: "images", frameName: downloadOptions.frameName))
                return
            }

            ui.info("Found \(imagePacks.count) images")

            // Process names using extracted processor
            let processedPacks = DownloadImageProcessor.processNames(
                imagePacks,
                validateRegexp: downloadOptions.nameValidateRegexp,
                replaceRegexp: downloadOptions.nameReplaceRegexp,
                nameStyle: downloadOptions.nameStyle
            )

            // Handle dark mode if suffix is specified
            let (lightPacks, darkPacks) = DownloadImageProcessor.splitByDarkMode(
                processedPacks,
                darkSuffix: downloadOptions.darkModeSuffix
            )

            // Create file contents for download
            var allFiles = DownloadImageProcessor.createFileContents(
                from: lightPacks,
                outputURL: outputURL,
                format: downloadOptions.format,
                dark: false,
                darkModeSuffix: downloadOptions.darkModeSuffix
            )
            if let darkPacks {
                allFiles += DownloadImageProcessor.createFileContents(
                    from: darkPacks,
                    outputURL: outputURL,
                    format: downloadOptions.format,
                    dark: true,
                    darkModeSuffix: downloadOptions.darkModeSuffix
                )
            }
            let filesToDownload = allFiles

            // Download files with progress
            ui.info("Downloading \(filesToDownload.count) files...")
            let fileDownloader = faultToleranceOptions.createFileDownloader()
            let downloadedFiles = try await ui.withProgress("Downloading", total: filesToDownload.count) { progress in
                try await fileDownloader.fetch(files: filesToDownload) { current, _ in
                    progress.update(current: current)
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

        private func loadImages(
            using loader: DownloadImageLoader,
            onBatchProgress: @escaping BatchProgressCallback = { _, _ in }
        ) async throws -> [ImagePack] {
            if downloadOptions.isVectorFormat {
                let params: FormatParams = downloadOptions.format == .svg ? SVGParams() : PDFParams()
                return try await loader.loadVectorImages(
                    fileId: downloadOptions.fileId,
                    frameName: downloadOptions.frameName,
                    params: params,
                    filter: downloadOptions.filter,
                    onBatchProgress: onBatchProgress
                )
            } else {
                return try await loader.loadRasterImages(
                    fileId: downloadOptions.fileId,
                    frameName: downloadOptions.frameName,
                    scale: downloadOptions.effectiveScale,
                    format: downloadOptions.format.rawValue,
                    filter: downloadOptions.filter,
                    onBatchProgress: onBatchProgress
                )
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
