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

    public init(
        mainRes: URL,
        resourcePackage: String? = nil,
        mainSrc: URL? = nil,
        templatesPath: URL? = nil
    ) {
        self.mainRes = mainRes
        self.resourcePackage = resourcePackage
        self.mainSrc = mainSrc
        self.templatesPath = templatesPath
    }
}
