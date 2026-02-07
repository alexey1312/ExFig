// swiftlint:disable type_name

import ExFigConfig
import ExFigCore
import Foundation

/// Typealias for backward compatibility with consumers.
public typealias iOSIconsEntry = iOS.IconsEntry

// MARK: - Convenience Extensions

public extension iOS.IconsEntry {
    /// Returns an IconsSourceInput for use with IconsExportContext.
    func iconsSourceInput(darkFileId: String? = nil) -> IconsSourceInput {
        IconsSourceInput(
            figmaFileId: figmaFileId,
            darkFileId: darkFileId,
            frameName: figmaFrameName ?? "Icons",
            format: VectorFormat(rawValue: format.rawValue) ?? .svg,
            useSingleFile: darkFileId == nil,
            darkModeSuffix: "_dark",
            renderMode: renderMode.flatMap { XcodeRenderMode(rawValue: $0.rawValue) },
            renderModeDefaultSuffix: renderModeDefaultSuffix,
            renderModeOriginalSuffix: renderModeOriginalSuffix,
            renderModeTemplateSuffix: renderModeTemplateSuffix,
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp
        )
    }

    /// Converts PKL NameStyle to ExFigCore NameStyle.
    var coreNameStyle: NameStyle {
        nameStyle.coreNameStyle
    }

    /// Path to generate UIImage extension as URL.
    var imageSwiftURL: URL? {
        imageSwift.map { URL(fileURLWithPath: $0) }
    }

    /// Path to generate SwiftUI Image extension as URL.
    var swiftUIImageSwiftURL: URL? {
        swiftUIImageSwift.map { URL(fileURLWithPath: $0) }
    }

    /// Path to generate Figma Code Connect Swift file as URL.
    var codeConnectSwiftURL: URL? {
        codeConnectSwift.map { URL(fileURLWithPath: $0) }
    }

    /// Converts PKL XcodeRenderMode to ExFigCore XcodeRenderMode.
    var coreRenderMode: XcodeRenderMode? {
        renderMode.flatMap { XcodeRenderMode(rawValue: $0.rawValue) }
    }

    // MARK: - Entry-Level Override Resolution

    /// Resolved xcassets path: entry override or platform config fallback.
    func resolvedXcassetsPath(fallback: URL?) -> URL? {
        xcassetsPath.map { URL(fileURLWithPath: $0) } ?? fallback
    }

    /// Resolved templates path: entry override or platform config fallback.
    func resolvedTemplatesPath(fallback: URL?) -> URL? {
        templatesPath.map { URL(fileURLWithPath: $0) } ?? fallback
    }

    /// Resolved Figma file ID: entry override or global fallback.
    func resolvedFigmaFileId(fallback: String?) -> String? {
        figmaFileId ?? fallback
    }
}

// swiftlint:enable type_name
