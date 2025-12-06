import Foundation

public struct FlutterOutput: Sendable {
    /// Path to Flutter lib/ directory for Dart files (e.g., lib/generated/)
    public let outputDirectory: URL

    /// Path to Flutter assets directory for icons (e.g., assets/icons/)
    public let iconsAssetsDirectory: URL?

    /// Path to Flutter assets directory for images (e.g., assets/images/)
    public let imagesAssetsDirectory: URL?

    /// Custom templates path
    public let templatesPath: URL?

    /// Class name for generated colors (default: "AppColors")
    public let colorsClassName: String?

    /// Class name for generated icons (default: "AppIcons")
    public let iconsClassName: String?

    /// Class name for generated images (default: "AppImages")
    public let imagesClassName: String?

    public init(
        outputDirectory: URL,
        iconsAssetsDirectory: URL? = nil,
        imagesAssetsDirectory: URL? = nil,
        templatesPath: URL? = nil,
        colorsClassName: String? = nil,
        iconsClassName: String? = nil,
        imagesClassName: String? = nil
    ) {
        self.outputDirectory = outputDirectory
        self.iconsAssetsDirectory = iconsAssetsDirectory
        self.imagesAssetsDirectory = imagesAssetsDirectory
        self.templatesPath = templatesPath
        self.colorsClassName = colorsClassName
        self.iconsClassName = iconsClassName
        self.imagesClassName = imagesClassName
    }
}
