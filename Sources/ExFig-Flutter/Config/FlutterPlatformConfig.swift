import Foundation

/// Flutter platform-level configuration.
///
/// Contains settings that apply across all Flutter asset exports:
/// - Output directory for Dart files
/// - Template customization
public struct FlutterPlatformConfig: Sendable {
    /// Output directory for generated Dart files.
    public let output: URL

    /// Custom templates path for code generation.
    public let templatesPath: URL?

    public init(output: URL, templatesPath: URL? = nil) {
        self.output = output
        self.templatesPath = templatesPath
    }
}
