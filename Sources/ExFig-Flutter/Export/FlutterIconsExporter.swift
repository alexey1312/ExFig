import ExFigCore
import Foundation

/// Exports icons from Figma frames to Flutter SVG assets and Dart code.
public struct FlutterIconsExporter: AssetExporter {
    public let assetType: AssetType = .icons

    public init() {}
}
