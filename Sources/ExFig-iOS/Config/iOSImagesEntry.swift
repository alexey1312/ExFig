// swiftlint:disable type_name

import ExFigCore
import Foundation

/// iOS images export configuration entry.
///
/// Defines how images from Figma frames are exported to an iOS/Xcode project.
/// Supports xcassets with PNG/HEIC and Swift extensions.
///
/// ## Source Configuration
///
/// Images are loaded from Figma frames:
/// - `figmaFrameName`: Frame containing image components
/// - `sourceFormat`: Format to fetch from Figma (png or svg)
/// - `scales`: Scale factors for raster images (default: [1.0, 2.0, 3.0])
///
/// ## Output Configuration
///
/// - `assetsFolder`: Folder inside xcassets for images
/// - `outputFormat`: Output format (png or heic)
/// - `imageSwift`: Generate UIImage extension
/// - `swiftUIImageSwift`: Generate SwiftUI Image extension
public struct iOSImagesEntry: Decodable, Sendable {
    // MARK: - Source (Figma Frame)

    /// Figma frame name containing images. Overrides common.images.figmaFrameName.
    public let figmaFrameName: String?

    /// Source format for fetching from Figma API (png or svg).
    public let sourceFormat: ImageSourceFormat?

    /// Scale factors for raster images.
    public let scales: [Double]?

    // MARK: - Name Processing

    /// Regex pattern for validating/filtering image names.
    public let nameValidateRegexp: String?

    /// Replacement pattern using captured groups from nameValidateRegexp.
    public let nameReplaceRegexp: String?

    /// Naming style for generated Swift identifiers.
    public let nameStyle: NameStyle

    // MARK: - Output (iOS-specific)

    /// Folder name inside xcassets for images.
    public let assetsFolder: String

    /// Output format for asset catalog (png or heic).
    /// HEIC provides ~40-50% smaller files but requires iOS 12+ and macOS for encoding.
    public let outputFormat: ImageOutputFormat?

    /// HEIC encoding options. Only used when outputFormat is heic.
    public let heicOptions: HeicOptions?

    /// Path to generate UIImage extension.
    public let imageSwift: URL?

    /// Path to generate SwiftUI Image extension.
    public let swiftUIImageSwift: URL?

    /// Path to generate Figma Code Connect Swift file.
    public let codeConnectSwift: URL?

    // MARK: - Render Mode

    /// Default render mode for all images.
    public let renderMode: XcodeRenderMode?

    /// Suffix for images that should use default render mode.
    public let renderModeDefaultSuffix: String?

    /// Suffix for images that should use original render mode.
    public let renderModeOriginalSuffix: String?

    /// Suffix for images that should use template render mode.
    public let renderModeTemplateSuffix: String?

    // MARK: - Initializer

    public init(
        figmaFrameName: String? = nil,
        sourceFormat: ImageSourceFormat? = nil,
        scales: [Double]? = nil,
        nameValidateRegexp: String? = nil,
        nameReplaceRegexp: String? = nil,
        nameStyle: NameStyle = .camelCase,
        assetsFolder: String,
        outputFormat: ImageOutputFormat? = nil,
        heicOptions: HeicOptions? = nil,
        imageSwift: URL? = nil,
        swiftUIImageSwift: URL? = nil,
        codeConnectSwift: URL? = nil,
        renderMode: XcodeRenderMode? = nil,
        renderModeDefaultSuffix: String? = nil,
        renderModeOriginalSuffix: String? = nil,
        renderModeTemplateSuffix: String? = nil
    ) {
        self.figmaFrameName = figmaFrameName
        self.sourceFormat = sourceFormat
        self.scales = scales
        self.nameValidateRegexp = nameValidateRegexp
        self.nameReplaceRegexp = nameReplaceRegexp
        self.nameStyle = nameStyle
        self.assetsFolder = assetsFolder
        self.outputFormat = outputFormat
        self.heicOptions = heicOptions
        self.imageSwift = imageSwift
        self.swiftUIImageSwift = swiftUIImageSwift
        self.codeConnectSwift = codeConnectSwift
        self.renderMode = renderMode
        self.renderModeDefaultSuffix = renderModeDefaultSuffix
        self.renderModeOriginalSuffix = renderModeOriginalSuffix
        self.renderModeTemplateSuffix = renderModeTemplateSuffix
    }
}

// MARK: - Convenience Extensions

public extension iOSImagesEntry {
    /// Returns an ImagesSourceInput for use with ImagesExportContext.
    func imagesSourceInput(fileId: String, darkFileId: String? = nil) -> ImagesSourceInput {
        ImagesSourceInput(
            fileId: fileId,
            darkFileId: darkFileId,
            frameName: figmaFrameName ?? "Images",
            sourceFormat: sourceFormat ?? .png,
            scales: scales ?? [1.0, 2.0, 3.0],
            useSingleFile: darkFileId == nil,
            darkModeSuffix: "_dark",
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp
        )
    }

    /// Effective output format, defaulting to PNG.
    var effectiveOutputFormat: ImageOutputFormat {
        outputFormat ?? .png
    }

    /// Effective scales, defaulting to iOS standard [1.0, 2.0, 3.0].
    var effectiveScales: [Double] {
        scales ?? [1.0, 2.0, 3.0]
    }
}

// MARK: - HEIC Options

/// Options for HEIC encoding.
public struct HeicOptions: Decodable, Sendable {
    /// Compression quality (0.0 to 1.0). Default: 0.8
    public let quality: Double?

    public init(quality: Double? = nil) {
        self.quality = quality
    }
}

// swiftlint:enable type_name
