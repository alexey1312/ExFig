import ExFigCore
import Foundation

/// Exports colors from Figma Variables to Android XML resources and Kotlin extensions.
public struct AndroidColorsExporter: AssetExporter {
    public let assetType: AssetType = .colors

    public init() {}
}
