import ExFigCore
import Foundation

/// Exports images from Figma frames to Android drawable resources (PNG/WebP).
public struct AndroidImagesExporter: AssetExporter {
    public let assetType: AssetType = .images

    public init() {}
}
