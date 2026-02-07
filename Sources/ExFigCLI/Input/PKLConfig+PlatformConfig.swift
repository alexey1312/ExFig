import ExFig_Android
import ExFig_Flutter
import ExFig_iOS
import ExFig_Web
import ExFigConfig
import Foundation

// MARK: - iOS

extension iOS.iOSConfig {
    /// Creates iOSPlatformConfig from generated iOS.iOSConfig.
    func platformConfig(figma: Figma.FigmaConfig? = nil) -> iOSPlatformConfig {
        iOSPlatformConfig(
            xcodeprojPath: xcodeprojPath,
            target: target,
            xcassetsPath: xcassetsPath.map { URL(fileURLWithPath: $0) },
            xcassetsInMainBundle: xcassetsInMainBundle,
            xcassetsInSwiftPackage: xcassetsInSwiftPackage,
            resourceBundleNames: resourceBundleNames,
            addObjcAttribute: addObjcAttribute,
            templatesPath: templatesPath.map { URL(fileURLWithPath: $0) },
            figmaFileId: figma?.lightFileId,
            figmaTimeout: figma?.timeout.map { TimeInterval($0) }
        )
    }
}

// MARK: - Android

extension Android.AndroidConfig {
    /// Creates AndroidPlatformConfig from generated Android.AndroidConfig.
    func platformConfig(figma: Figma.FigmaConfig? = nil) -> AndroidPlatformConfig {
        AndroidPlatformConfig(
            mainRes: URL(fileURLWithPath: mainRes),
            resourcePackage: resourcePackage,
            mainSrc: mainSrc.map { URL(fileURLWithPath: $0) },
            templatesPath: templatesPath.map { URL(fileURLWithPath: $0) },
            figmaFileId: figma?.lightFileId,
            figmaTimeout: figma?.timeout.map { TimeInterval($0) }
        )
    }
}

// MARK: - Flutter

extension Flutter.FlutterConfig {
    /// Creates FlutterPlatformConfig from generated Flutter.FlutterConfig.
    func platformConfig() -> FlutterPlatformConfig {
        FlutterPlatformConfig(
            output: URL(fileURLWithPath: output),
            templatesPath: templatesPath.map { URL(fileURLWithPath: $0) }
        )
    }
}

// MARK: - Web

extension Web.WebConfig {
    /// Creates WebPlatformConfig from generated Web.WebConfig.
    func platformConfig() -> WebPlatformConfig {
        WebPlatformConfig(
            output: URL(fileURLWithPath: output),
            templatesPath: templatesPath.map { URL(fileURLWithPath: $0) }
        )
    }
}
