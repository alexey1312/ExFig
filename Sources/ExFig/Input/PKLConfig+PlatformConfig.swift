import ExFig_Android
import ExFig_Flutter
import ExFig_iOS
import ExFig_Web
import Foundation

// MARK: - iOS

extension PKLConfig.iOS {
    /// Creates iOSPlatformConfig from PKLConfig.iOS.
    func platformConfig(figma: PKLConfig.Figma? = nil) -> iOSPlatformConfig {
        iOSPlatformConfig(
            xcodeprojPath: xcodeprojPath,
            target: target,
            xcassetsPath: xcassetsPath,
            xcassetsInMainBundle: xcassetsInMainBundle,
            xcassetsInSwiftPackage: xcassetsInSwiftPackage,
            resourceBundleNames: resourceBundleNames,
            addObjcAttribute: addObjcAttribute,
            templatesPath: templatesPath,
            figmaFileId: figma?.lightFileId,
            figmaTimeout: figma?.timeout
        )
    }
}

// MARK: - Android

extension PKLConfig.Android {
    /// Creates AndroidPlatformConfig from PKLConfig.Android.
    func platformConfig(figma: PKLConfig.Figma? = nil) -> AndroidPlatformConfig {
        AndroidPlatformConfig(
            mainRes: mainRes,
            resourcePackage: resourcePackage,
            mainSrc: mainSrc,
            templatesPath: templatesPath,
            figmaFileId: figma?.lightFileId,
            figmaTimeout: figma?.timeout
        )
    }
}

// MARK: - Flutter

extension PKLConfig.Flutter {
    /// Creates FlutterPlatformConfig from PKLConfig.Flutter.
    func platformConfig() -> FlutterPlatformConfig {
        FlutterPlatformConfig(
            output: output,
            templatesPath: templatesPath
        )
    }
}

// MARK: - Web

extension PKLConfig.Web {
    /// Creates WebPlatformConfig from PKLConfig.Web.
    func platformConfig() -> WebPlatformConfig {
        WebPlatformConfig(
            output: output,
            templatesPath: templatesPath
        )
    }
}
