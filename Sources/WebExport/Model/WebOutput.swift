import Foundation

public struct WebOutput: Sendable {
    /// Path to output directory for generated files (e.g., src/tokens/)
    public let outputDirectory: URL

    /// Path to assets directory for icons (e.g., assets/icons/)
    public let iconsAssetsDirectory: URL?

    /// Path to assets directory for images (e.g., assets/images/)
    public let imagesAssetsDirectory: URL?

    /// Custom templates path
    public let templatesPath: URL?

    public init(
        outputDirectory: URL,
        iconsAssetsDirectory: URL? = nil,
        imagesAssetsDirectory: URL? = nil,
        templatesPath: URL? = nil
    ) {
        self.outputDirectory = outputDirectory
        self.iconsAssetsDirectory = iconsAssetsDirectory
        self.imagesAssetsDirectory = imagesAssetsDirectory
        self.templatesPath = templatesPath
    }
}
