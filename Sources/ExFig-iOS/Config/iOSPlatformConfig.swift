// swiftlint:disable type_name

import Foundation

/// iOS platform-level configuration.
///
/// Contains settings that apply across all iOS asset exports:
/// - Xcode project integration
/// - Asset catalog paths
/// - Swift code generation options
public struct iOSPlatformConfig: Sendable {
    /// Path to the .xcodeproj file.
    public let xcodeprojPath: String

    /// Target name within the Xcode project.
    public let target: String

    /// Path to the .xcassets directory.
    public let xcassetsPath: URL

    /// Whether assets are in the main bundle.
    public let xcassetsInMainBundle: Bool

    /// Whether assets are in a Swift Package.
    public let xcassetsInSwiftPackage: Bool?

    /// Names of resource bundles to use.
    public let resourceBundleNames: [String]?

    /// Whether to add @objc attribute to generated code.
    public let addObjcAttribute: Bool?

    /// Custom templates path for code generation.
    public let templatesPath: URL?

    public init(
        xcodeprojPath: String,
        target: String,
        xcassetsPath: URL,
        xcassetsInMainBundle: Bool = true,
        xcassetsInSwiftPackage: Bool? = nil,
        resourceBundleNames: [String]? = nil,
        addObjcAttribute: Bool? = nil,
        templatesPath: URL? = nil
    ) {
        self.xcodeprojPath = xcodeprojPath
        self.target = target
        self.xcassetsPath = xcassetsPath
        self.xcassetsInMainBundle = xcassetsInMainBundle
        self.xcassetsInSwiftPackage = xcassetsInSwiftPackage
        self.resourceBundleNames = resourceBundleNames
        self.addObjcAttribute = addObjcAttribute
        self.templatesPath = templatesPath
    }
}

// swiftlint:enable type_name
