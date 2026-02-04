import Foundation

/// Android platform-level configuration.
///
/// Contains settings that apply across all Android asset exports:
/// - Resource directories
/// - Package names for code generation
/// - Template customization
public struct AndroidPlatformConfig: Sendable {
    /// Path to the main res directory (e.g., app/src/main/res).
    public let mainRes: URL

    /// Resource package name for generated code.
    public let resourcePackage: String?

    /// Path to the main src directory for generated Kotlin code.
    public let mainSrc: URL?

    /// Custom templates path for code generation.
    public let templatesPath: URL?

    /// Figma file ID for typography (from figma.lightFileId).
    public let figmaFileId: String?

    /// Timeout for Figma API requests.
    public let figmaTimeout: TimeInterval?

    public init(
        mainRes: URL,
        resourcePackage: String? = nil,
        mainSrc: URL? = nil,
        templatesPath: URL? = nil,
        figmaFileId: String? = nil,
        figmaTimeout: TimeInterval? = nil
    ) {
        self.mainRes = mainRes
        self.resourcePackage = resourcePackage
        self.mainSrc = mainSrc
        self.templatesPath = templatesPath
        self.figmaFileId = figmaFileId
        self.figmaTimeout = figmaTimeout
    }
}
