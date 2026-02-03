import ExFigCore
import Foundation

/// Exports images from Figma frames to Flutter PNG/WebP assets and Dart code.
public struct FlutterImagesExporter: AssetExporter {
    public let assetType: AssetType = .images

    public init() {}
}
