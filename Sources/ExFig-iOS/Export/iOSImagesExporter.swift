// swiftlint:disable type_name

import ExFigCore
import Foundation

/// Exports images from Figma frames to iOS xcassets (PNG/HEIC) and Swift extensions.
public struct iOSImagesExporter: AssetExporter {
    public let assetType: AssetType = .images

    public init() {}
}

// swiftlint:enable type_name
