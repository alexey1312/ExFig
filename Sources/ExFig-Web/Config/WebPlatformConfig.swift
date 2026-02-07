import Foundation

/// Web platform-level configuration.
///
/// Contains settings that apply across all Web asset exports:
/// - Output directory for CSS/JS/JSON files
/// - Template customization
public struct WebPlatformConfig: Sendable {
    /// Output directory for generated files.
    public let output: URL

    /// Custom templates path for code generation.
    public let templatesPath: URL?

    public init(output: URL, templatesPath: URL? = nil) {
        self.output = output
        self.templatesPath = templatesPath
    }
}
