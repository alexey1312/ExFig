import ExFigCore
import Foundation

/// Exports colors from Figma Variables to Flutter Dart color classes.
public struct FlutterColorsExporter: AssetExporter {
    public let assetType: AssetType = .colors

    public init() {}
}
