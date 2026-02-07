// swiftlint:disable file_length

import ExFigConfig
import ExFigCore
import FigmaAPI
import Foundation

// swiftlint:disable type_body_length

/// Concrete implementation of `ImagesExportContext` for the ExFig CLI.
///
/// Bridges between the plugin system and ExFig's internal services:
/// - Uses `ImagesLoader` for Figma data loading
/// - Uses `ImagesProcessor` for platform-specific processing
/// - Uses `ExFigCommand.fileWriter` for file output
/// - Uses `TerminalUI` for progress and logging
/// - Uses `PipelinedDownloader` for batch-optimized downloads
/// - Uses format converters for HEIC/WebP conversion
/// - Supports granular cache for incremental exports
struct ImagesExportContextImpl: ImagesExportContextWithGranularCache {
    let client: Client
    let ui: TerminalUI
    let params: PKLConfig
    let filter: String?
    let isBatchMode: Bool
    let fileDownloader: FileDownloader
    let configExecutionContext: ConfigExecutionContext?
    let granularCacheManager: GranularCacheManager?
    let platform: Platform

    init(
        client: Client,
        ui: TerminalUI,
        params: PKLConfig,
        filter: String? = nil,
        isBatchMode: Bool = false,
        fileDownloader: FileDownloader = FileDownloader(),
        configExecutionContext: ConfigExecutionContext? = nil,
        granularCacheManager: GranularCacheManager? = nil,
        platform: Platform = .ios
    ) {
        self.client = client
        self.ui = ui
        self.params = params
        self.filter = filter
        self.isBatchMode = isBatchMode
        self.fileDownloader = fileDownloader
        self.configExecutionContext = configExecutionContext
        self.granularCacheManager = granularCacheManager
        self.platform = platform
    }

    var isGranularCacheEnabled: Bool {
        granularCacheManager != nil
    }

    // MARK: - ExportContext

    func writeFiles(_ files: [FileContents]) throws {
        try ExFigCommand.fileWriter.write(files: files)
    }

    func info(_ message: String) {
        ui.info(message)
    }

    func warning(_ message: String) {
        ui.warning(message)
    }

    func success(_ message: String) {
        ui.success(message)
    }

    func withSpinner<T: Sendable>(
        _ message: String,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await ui.withSpinner(message, operation: operation)
    }

    // MARK: - ImagesExportContext

    func loadImages(from source: ImagesSourceInput) async throws -> ImagesLoadOutput {
        // Convert source format
        let loaderSourceFormat: ImagesSourceFormat = source.sourceFormat == .svg ? .svg : .png

        // Create loader config from source input
        let config = ImagesLoaderConfig(
            frameName: source.frameName,
            scales: source.scales,
            format: nil, // Format is determined by platform exporter
            sourceFormat: loaderSourceFormat
        )

        let loader = ImagesLoader(
            client: client,
            params: params,
            platform: platform,
            logger: ExFigCommand.logger,
            config: config
        )

        let result = try await loader.load(filter: filter)

        return ImagesLoadOutput(
            light: result.light,
            dark: result.dark ?? []
        )
    }

    func processImages(
        _ images: ImagesLoadOutput,
        platform: Platform,
        nameValidateRegexp: String?,
        nameReplaceRegexp: String?,
        nameStyle: NameStyle
    ) throws -> ImagesProcessResult {
        let processor = ImagesProcessor(
            platform: platform,
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp,
            nameStyle: nameStyle
        )

        let result = processor.process(
            light: images.light,
            dark: images.dark.isEmpty ? nil : images.dark
        )

        return try ImagesProcessResult(
            imagePairs: result.get(),
            warning: result.warning?.errorDescription
        )
    }

    func downloadFiles(
        _ files: [FileContents],
        progressTitle: String
    ) async throws -> [FileContents] {
        let remoteFilesCount = files.filter { $0.sourceURL != nil }.count

        guard remoteFilesCount > 0 else {
            return files
        }

        return try await ui.withProgress(progressTitle, total: remoteFilesCount) { progress in
            try await PipelinedDownloader.download(
                files: files,
                fileDownloader: fileDownloader,
                context: configExecutionContext
            ) { current, total in
                progress.update(current: current)
                // Report to batch progress if in batch mode
                if let callback = BatchProgressViewStorage.downloadProgressCallback {
                    Task { await callback(current, total) }
                }
            }
        }
    }

    func convertFormat(
        _ files: [FileContents],
        to outputFormat: ImageOutputFormat,
        heicOptions: HeicConverterOptions?,
        webpOptions: WebpConverterOptions?,
        progressTitle: String
    ) async throws -> [FileContents] {
        guard !files.isEmpty else { return files }

        switch outputFormat {
        case .heic:
            return try await convertToHeic(files: files, options: heicOptions, progressTitle: progressTitle)
        case .webp:
            return try await convertToWebP(files: files, options: webpOptions, progressTitle: progressTitle)
        case .png:
            return files // Already PNG, no conversion needed
        }
    }

    func rasterizeSVGs(
        _ files: [FileContents],
        scales: [Double],
        to outputFormat: ImageOutputFormat,
        heicOptions: HeicConverterOptions?,
        progressTitle: String
    ) async throws -> [FileContents] {
        guard !files.isEmpty else { return [] }

        return try await ui.withProgress(progressTitle, total: files.count * scales.count) { progress in
            var results: [FileContents] = []

            for fileContents in files {
                // Read SVG data from memory or temp file
                let svgData: Data
                if let data = fileContents.data {
                    svgData = data
                } else if let dataFile = fileContents.dataFile {
                    svgData = try Data(contentsOf: dataFile)
                } else {
                    let filename = fileContents.destination.file.lastPathComponent
                    throw SVGRasterizationError.missingData(filename: filename)
                }

                let baseName = fileContents.destination.file.deletingPathExtension().lastPathComponent
                let imagesetDir = fileContents.destination.directory

                for scale in scales {
                    let scaleSuffix = scale == 1.0 ? "" : "@\(Int(scale))x"
                    let outputExtension = outputFormat == .heic ? "heic" : "png"
                    let outputFileName = "\(baseName)\(scaleSuffix).\(outputExtension)"

                    let outputData: Data
                    switch outputFormat {
                    case .heic:
                        let converter = HeicConverterFactory.createSvgToHeicConverter(from: heicOptions)
                        outputData = try converter.convert(svgData: svgData, scale: scale, fileName: baseName)
                    case .png, .webp:
                        let converter = SvgToPngConverter()
                        outputData = try converter.convert(svgData: svgData, scale: scale, fileName: baseName)
                    }

                    results.append(FileContents(
                        destination: Destination(
                            directory: imagesetDir,
                            file: URL(fileURLWithPath: outputFileName)
                        ),
                        data: outputData
                    ))

                    progress.increment()
                }
            }

            return results
        }
    }

    func withProgress<T: Sendable>(
        _ title: String,
        total: Int,
        operation: @escaping @Sendable (ProgressReporter) async throws -> T
    ) async throws -> T {
        try await ui.withProgress(title, total: total) { progress in
            let reporter = ProgressBarReporter(progressBar: progress)
            return try await operation(reporter)
        }
    }

    // MARK: - Private Helpers

    private func convertToHeic(
        files: [FileContents],
        options: HeicConverterOptions?,
        progressTitle: String
    ) async throws -> [FileContents] {
        // Check if HEIC encoding is available
        guard NativeHeicEncoder.isAvailable() else {
            ui.warning(
                "HEIC encoding not available on this platform. Output will be PNG instead of HEIC. "
                    + "To suppress this warning, set outputFormat = \"png\" in your config."
            )
            return files
        }

        let pngFiles = files.filter { $0.destination.file.pathExtension == "png" }
        guard !pngFiles.isEmpty else { return files }

        // Write PNG files to disk first (HEIC converter reads from disk)
        try ExFigCommand.fileWriter.write(files: pngFiles)

        let converter = HeicConverterFactory.createHeicConverter(from: options)
        let filesToConvert = pngFiles.map { URL(fileURLWithPath: $0.destination.url.path) }

        try await ui.withProgress(progressTitle, total: filesToConvert.count) { progress in
            try await converter.convertBatch(files: filesToConvert) { current, _ in
                progress.update(current: current)
            }
        }

        // Delete source PNG files after successful conversion
        for pngFile in filesToConvert {
            try? FileManager.default.removeItem(at: pngFile)
        }

        // Update file references to use .heic extension
        return files.map { file in
            if file.destination.file.pathExtension == "png" {
                return file.changingExtension(newExtension: "heic")
            }
            return file
        }
    }

    private func convertToWebP(
        files: [FileContents],
        options: WebpConverterOptions?,
        progressTitle: String
    ) async throws -> [FileContents] {
        let pngFiles = files.filter { $0.destination.file.pathExtension == "png" }
        guard !pngFiles.isEmpty else { return files }

        // Write PNG files to disk first
        try ExFigCommand.fileWriter.write(files: pngFiles)

        let converter = WebpConverterFactory.createWebpConverter(from: options)
        let filesToConvert = pngFiles.map { URL(fileURLWithPath: $0.destination.url.path) }

        try await ui.withProgress(progressTitle, total: filesToConvert.count) { progress in
            try await converter.convertBatch(files: filesToConvert) { current, _ in
                progress.update(current: current)
            }
        }

        // Delete source PNG files after successful conversion
        for pngFile in filesToConvert {
            try? FileManager.default.removeItem(at: pngFile)
        }

        // Update file references to use .webp extension
        return files.map { file in
            if file.destination.file.pathExtension == "png" {
                return file.changingExtension(newExtension: "webp")
            }
            return file
        }
    }

    // MARK: - ImagesExportContextWithGranularCache

    func loadImagesWithGranularCache(
        from source: ImagesSourceInput,
        onProgress: (@Sendable (Int, Int) -> Void)?
    ) async throws -> ImagesLoadOutputWithHashes {
        let loaderSourceFormat: ImagesSourceFormat = source.sourceFormat == .svg ? .svg : .png

        let config = ImagesLoaderConfig(
            frameName: source.frameName,
            scales: source.scales,
            format: nil,
            sourceFormat: loaderSourceFormat
        )

        let loader = ImagesLoader(
            client: client,
            params: params,
            platform: platform,
            logger: ExFigCommand.logger,
            config: config
        )

        if let manager = granularCacheManager {
            loader.granularCacheManager = manager
            let result = try await loader.loadWithGranularCache(
                filter: filter,
                onBatchProgress: onProgress ?? { _, _ in }
            )
            return ImagesLoadOutputWithHashes(
                light: result.light,
                dark: result.dark ?? [],
                computedHashes: result.computedHashes,
                allSkipped: result.allSkipped,
                allAssetMetadata: result.allAssetMetadata
            )
        } else {
            let result = try await loader.load(filter: filter, onBatchProgress: onProgress ?? { _, _ in })
            return ImagesLoadOutputWithHashes(
                light: result.light,
                dark: result.dark ?? [],
                computedHashes: [:],
                allSkipped: false,
                allAssetMetadata: []
            )
        }
    }

    func processImageNames(
        _ names: [String],
        nameValidateRegexp: String?,
        nameReplaceRegexp: String?,
        nameStyle: NameStyle
    ) -> [String] {
        let processor = ImagesProcessor(
            platform: platform,
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp,
            nameStyle: nameStyle
        )
        return processor.processNames(names)
    }
}

// MARK: - Errors

/// Errors that can occur during SVG rasterization.
enum SVGRasterizationError: LocalizedError {
    /// SVG data is missing for rasterization.
    case missingData(filename: String)

    var errorDescription: String? {
        switch self {
        case let .missingData(filename):
            "Failed to read SVG data for rasterization: \(filename)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .missingData:
            "Ensure the SVG file was downloaded successfully before rasterization"
        }
    }
}

// swiftlint:enable file_length
