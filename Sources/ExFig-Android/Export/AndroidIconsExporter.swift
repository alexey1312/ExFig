import ExFigCore
import Foundation

/// Exports icons from Figma frames to Android vector drawables and Jetpack Compose code.
public struct AndroidIconsExporter: AssetExporter {
    public let assetType: AssetType = .icons

    public init() {}
}
