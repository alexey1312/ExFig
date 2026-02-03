import ExFigCore
import Foundation

/// Exports typography styles from Figma to Android XML styles and Kotlin extensions.
public struct AndroidTypographyExporter: AssetExporter {
    public let assetType: AssetType = .typography

    public init() {}
}
