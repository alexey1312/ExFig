// swiftlint:disable type_name

import ExFigCore
import Foundation

/// Android platform plugin that provides asset exporters for Android Studio projects.
///
/// This plugin handles export of colors, icons, images, and typography
/// to Android projects using XML resources, vector drawables, and Kotlin code.
public struct AndroidPlugin: PlatformPlugin {
    public let identifier = "android"
    public let platform: Platform = .android
    public let configKeys: Set<String> = ["android"]

    public init() {}

    public func exporters() -> [any AssetExporter] {
        [
            AndroidColorsExporter(),
            AndroidIconsExporter(),
            AndroidImagesExporter(),
            AndroidTypographyExporter(),
        ]
    }
}

// swiftlint:enable type_name
