import ExFigCore
import Foundation

/// Web platform plugin that provides asset exporters for React/TypeScript projects.
///
/// This plugin handles export of colors, icons, and images
/// to web projects using CSS variables, TypeScript constants, and React components.
public struct WebPlugin: PlatformPlugin {
    public let identifier = "web"
    public let platform: Platform = .web
    public let configKeys: Set<String> = ["web"]

    public init() {}

    public func exporters() -> [any AssetExporter] {
        [
            WebColorsExporter(),
            WebIconsExporter(),
            WebImagesExporter(),
        ]
    }
}
