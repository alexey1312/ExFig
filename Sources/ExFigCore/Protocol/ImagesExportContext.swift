import Foundation

// MARK: - Images Export Context

/// Context for images export operations.
///
/// Extends `ExportContext` with images-specific functionality
/// like loading images from Figma frames and format conversion.
public protocol ImagesExportContext: ExportContext {
    /// Loads images from a Figma frame.
    ///
    /// - Parameter source: Images source configuration.
    /// - Returns: Loaded images output (light, dark variants).
    func loadImages(from source: ImagesSourceInput) async throws -> ImagesLoadOutput

    /// Processes images into platform-specific format.
    ///
    /// - Parameters:
    ///   - images: Raw images from Figma.
    ///   - platform: Target platform.
    ///   - nameValidateRegexp: Optional regex for name validation.
    ///   - nameReplaceRegexp: Optional regex for name replacement.
    ///   - nameStyle: Naming style for generated code.
    /// - Returns: Processed image pairs.
    func processImages(
        _ images: ImagesLoadOutput,
        platform: Platform,
        nameValidateRegexp: String?,
        nameReplaceRegexp: String?,
        nameStyle: NameStyle
    ) throws -> ImagesProcessResult

    /// Downloads remote files with progress reporting.
    ///
    /// In batch mode, uses `PipelinedDownloader` with shared queue for ~45% speedup.
    /// In standalone mode, uses direct file downloader.
    ///
    /// - Parameters:
    ///   - files: Files to download (may contain remote URLs).
    ///   - progressTitle: Title for the progress bar.
    /// - Returns: Files with downloaded data populated.
    func downloadFiles(
        _ files: [FileContents],
        progressTitle: String
    ) async throws -> [FileContents]

    /// Converts images to a different format (e.g., PNG to HEIC).
    ///
    /// - Parameters:
    ///   - files: Files to convert (must be already downloaded).
    ///   - outputFormat: Target format.
    ///   - progressTitle: Title for progress bar.
    /// - Returns: Converted files.
    func convertFormat(
        _ files: [FileContents],
        to outputFormat: ImageOutputFormat,
        progressTitle: String
    ) async throws -> [FileContents]

    /// Rasterizes SVG files to raster format at specified scales.
    ///
    /// - Parameters:
    ///   - files: SVG files to rasterize.
    ///   - scales: Scale factors (e.g., [1.0, 2.0, 3.0] for iOS).
    ///   - outputFormat: Target raster format (png or heic).
    ///   - progressTitle: Title for progress bar.
    /// - Returns: Rasterized files at all scales.
    func rasterizeSVGs(
        _ files: [FileContents],
        scales: [Double],
        to outputFormat: ImageOutputFormat,
        progressTitle: String
    ) async throws -> [FileContents]

    /// Runs an operation with a progress bar.
    ///
    /// - Parameters:
    ///   - title: Progress bar title.
    ///   - total: Total number of items.
    ///   - operation: The operation to run, receives progress callback.
    /// - Returns: The operation result.
    func withProgress<T: Sendable>(
        _ title: String,
        total: Int,
        operation: @escaping @Sendable (ProgressReporter) async throws -> T
    ) async throws -> T
}

/// Input for loading images from Figma.
public struct ImagesSourceInput: Sendable {
    /// The Figma file ID containing images.
    public let fileId: String

    /// Optional dark mode file ID (if separate files for light/dark).
    public let darkFileId: String?

    /// The frame name containing images.
    public let frameName: String

    /// Source format for images (png or svg).
    public let sourceFormat: ImageSourceFormat

    /// Scales to request from Figma (for raster images).
    public let scales: [Double]

    /// Whether to use single file with dark mode suffix.
    public let useSingleFile: Bool

    /// Suffix for dark mode images when using single file.
    public let darkModeSuffix: String

    /// Name validation regex.
    public let nameValidateRegexp: String?

    /// Name replacement regex.
    public let nameReplaceRegexp: String?

    public init(
        fileId: String,
        darkFileId: String? = nil,
        frameName: String,
        sourceFormat: ImageSourceFormat = .png,
        scales: [Double] = [1.0, 2.0, 3.0],
        useSingleFile: Bool = false,
        darkModeSuffix: String = "_dark",
        nameValidateRegexp: String? = nil,
        nameReplaceRegexp: String? = nil
    ) {
        self.fileId = fileId
        self.darkFileId = darkFileId
        self.frameName = frameName
        self.sourceFormat = sourceFormat
        self.scales = scales
        self.useSingleFile = useSingleFile
        self.darkModeSuffix = darkModeSuffix
        self.nameValidateRegexp = nameValidateRegexp
        self.nameReplaceRegexp = nameReplaceRegexp
    }
}

/// Source format for images from Figma.
public enum ImageSourceFormat: String, Sendable, Decodable {
    case png
    case svg
}

/// Output format for images.
public enum ImageOutputFormat: String, Sendable, Decodable {
    case png
    case heic
    case webp
}

/// Output from images loading.
public struct ImagesLoadOutput: Sendable {
    public let light: [ImagePack]
    public let dark: [ImagePack]

    public init(
        light: [ImagePack],
        dark: [ImagePack] = []
    ) {
        self.light = light
        self.dark = dark
    }
}

/// Result from images processing.
public struct ImagesProcessResult: Sendable {
    public let imagePairs: [AssetPair<ImagePack>]
    public let warning: String?

    public init(imagePairs: [AssetPair<ImagePack>], warning: String? = nil) {
        self.imagePairs = imagePairs
        self.warning = warning
    }
}
