import ExFigCore
import Foundation

// swiftlint:disable type_name

/// iOS platform plugin that provides asset exporters for Xcode projects.
///
/// This plugin handles export of colors, icons, images, and typography
/// to iOS/iPadOS/macOS projects using xcassets and Swift extensions.
public struct iOSPlugin: PlatformPlugin {
    public let identifier = "ios"
    public let platform: Platform = .ios
    public let configKeys: Set<String> = ["ios"]

    public init() {}

    public func exporters() -> [any AssetExporter] {
        [
            iOSColorsExporter(),
            iOSIconsExporter(),
            iOSImagesExporter(),
            iOSTypographyExporter(),
        ]
    }
}

// swiftlint:enable type_name
