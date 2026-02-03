import ExFigCore
import Foundation

/// Exports colors from Figma Variables to CSS variables and TypeScript constants.
public struct WebColorsExporter: AssetExporter {
    public let assetType: AssetType = .colors

    public init() {}
}
