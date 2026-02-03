import ExFigCore
import Foundation

/// Web images export configuration entry.
///
/// Supports SVG/PNG output with optional React TSX component generation.
public struct WebImagesEntry: Decodable, Sendable {
    // MARK: - Source (Figma Frame)

    /// Figma frame name containing images. Overrides common.images.figmaFrameName.
    public let figmaFrameName: String?

    // MARK: - Name Processing

    /// Regex pattern for validating/filtering image names.
    public let nameValidateRegexp: String?

    /// Replacement pattern using captured groups from nameValidateRegexp.
    public let nameReplaceRegexp: String?

    /// Naming style for generated identifiers.
    public let nameStyle: NameStyle?

    // MARK: - Output (Web-specific)

    /// Output directory for generated TypeScript components (e.g., "src/components/images").
    public let outputDirectory: String

    /// Directory for image assets (e.g., "public/images").
    public let assetsDirectory: String?

    /// Generate React TSX components. Defaults to true.
    public let generateReactComponents: Bool?

    // MARK: - Initializer

    public init(
        figmaFrameName: String? = nil,
        nameValidateRegexp: String? = nil,
        nameReplaceRegexp: String? = nil,
        nameStyle: NameStyle? = nil,
        outputDirectory: String,
        assetsDirectory: String? = nil,
        generateReactComponents: Bool? = nil
    ) {
        self.figmaFrameName = figmaFrameName
        self.nameValidateRegexp = nameValidateRegexp
        self.nameReplaceRegexp = nameReplaceRegexp
        self.nameStyle = nameStyle
        self.outputDirectory = outputDirectory
        self.assetsDirectory = assetsDirectory
        self.generateReactComponents = generateReactComponents
    }
}

// MARK: - Convenience Extensions

public extension WebImagesEntry {
    /// Returns an ImagesSourceInput for use with ImagesExportContext.
    func imagesSourceInput(fileId: String, darkFileId: String? = nil) -> ImagesSourceInput {
        ImagesSourceInput(
            fileId: fileId,
            darkFileId: darkFileId,
            frameName: figmaFrameName ?? "Images",
            sourceFormat: .svg,
            scales: [1.0],
            useSingleFile: darkFileId == nil,
            darkModeSuffix: "_dark",
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp
        )
    }

    /// Effective name style, defaulting to snake_case.
    var effectiveNameStyle: NameStyle {
        nameStyle ?? .snakeCase
    }

    /// Whether to generate React components, defaulting to true.
    var effectiveGenerateReactComponents: Bool {
        generateReactComponents ?? true
    }
}
