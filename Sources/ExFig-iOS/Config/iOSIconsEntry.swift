// swiftlint:disable type_name

import ExFigCore
import Foundation

/// iOS icons export configuration entry.
///
/// Defines how icons from Figma frames are exported to an iOS/Xcode project.
/// Supports xcassets with PDF/SVG and Swift extensions.
///
/// ## Source Configuration
///
/// Icons are loaded from Figma frames:
/// - `figmaFrameName`: Frame containing icon components
/// - `format`: Vector format (svg or pdf)
///
/// ## Output Configuration
///
/// - `assetsFolder`: Folder inside xcassets for icons
/// - `imageSwift`: Generate UIImage extension
/// - `swiftUIImageSwift`: Generate SwiftUI Image extension
/// - `preservesVectorRepresentation`: Icons to preserve as vectors
public struct iOSIconsEntry: Decodable, Sendable {
    // MARK: - Source (Figma Frame)

    /// Figma frame name containing icons. Overrides common.icons.figmaFrameName.
    public let figmaFrameName: String?

    /// Vector format for icons (svg or pdf).
    public let format: VectorFormat

    // MARK: - Name Processing

    /// Regex pattern for validating/filtering icon names.
    public let nameValidateRegexp: String?

    /// Replacement pattern using captured groups from nameValidateRegexp.
    public let nameReplaceRegexp: String?

    /// Naming style for generated Swift identifiers.
    public let nameStyle: NameStyle

    // MARK: - Output (iOS-specific)

    /// Folder name inside xcassets for icons.
    public let assetsFolder: String

    /// Icon names that should preserve vector representation in Xcode.
    public let preservesVectorRepresentation: [String]?

    /// Path to generate UIImage extension.
    public let imageSwift: URL?

    /// Path to generate SwiftUI Image extension.
    public let swiftUIImageSwift: URL?

    /// Path to generate Figma Code Connect Swift file.
    public let codeConnectSwift: URL?

    // MARK: - Render Mode

    /// Default render mode for all icons.
    public let renderMode: XcodeRenderMode?

    /// Suffix for icons that should use default render mode.
    public let renderModeDefaultSuffix: String?

    /// Suffix for icons that should use original render mode.
    public let renderModeOriginalSuffix: String?

    /// Suffix for icons that should use template render mode.
    public let renderModeTemplateSuffix: String?

    // MARK: - Initializer

    public init(
        figmaFrameName: String? = nil,
        format: VectorFormat = .svg,
        nameValidateRegexp: String? = nil,
        nameReplaceRegexp: String? = nil,
        nameStyle: NameStyle = .camelCase,
        assetsFolder: String,
        preservesVectorRepresentation: [String]? = nil,
        imageSwift: URL? = nil,
        swiftUIImageSwift: URL? = nil,
        codeConnectSwift: URL? = nil,
        renderMode: XcodeRenderMode? = nil,
        renderModeDefaultSuffix: String? = nil,
        renderModeOriginalSuffix: String? = nil,
        renderModeTemplateSuffix: String? = nil
    ) {
        self.figmaFrameName = figmaFrameName
        self.format = format
        self.nameValidateRegexp = nameValidateRegexp
        self.nameReplaceRegexp = nameReplaceRegexp
        self.nameStyle = nameStyle
        self.assetsFolder = assetsFolder
        self.preservesVectorRepresentation = preservesVectorRepresentation
        self.imageSwift = imageSwift
        self.swiftUIImageSwift = swiftUIImageSwift
        self.codeConnectSwift = codeConnectSwift
        self.renderMode = renderMode
        self.renderModeDefaultSuffix = renderModeDefaultSuffix
        self.renderModeOriginalSuffix = renderModeOriginalSuffix
        self.renderModeTemplateSuffix = renderModeTemplateSuffix
    }
}

// MARK: - Convenience Extensions

public extension iOSIconsEntry {
    /// Returns an IconsSourceInput for use with IconsExportContext.
    func iconsSourceInput(darkFileId: String? = nil) -> IconsSourceInput {
        IconsSourceInput(
            darkFileId: darkFileId,
            frameName: figmaFrameName ?? "Icons",
            format: format,
            useSingleFile: darkFileId == nil,
            darkModeSuffix: "_dark",
            renderMode: renderMode,
            renderModeDefaultSuffix: renderModeDefaultSuffix,
            renderModeOriginalSuffix: renderModeOriginalSuffix,
            renderModeTemplateSuffix: renderModeTemplateSuffix,
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp
        )
    }
}

// swiftlint:enable type_name
