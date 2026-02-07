import ExFigCore
import Foundation

/// Flutter platform plugin that provides asset exporters for Flutter projects.
///
/// This plugin handles export of colors, icons, and images
/// to Flutter projects using Dart code and SVG/PNG assets.
public struct FlutterPlugin: PlatformPlugin {
    public let identifier = "flutter"
    public let platform: Platform = .flutter
    public let configKeys: Set<String> = ["flutter"]

    public init() {}

    public func exporters() -> [any AssetExporter] {
        [
            FlutterColorsExporter(),
            FlutterIconsExporter(),
            FlutterImagesExporter(),
        ]
    }
}
