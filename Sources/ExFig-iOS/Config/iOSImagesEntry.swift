// swiftlint:disable type_name

import ExFigConfig
import ExFigCore
import Foundation

/// Typealias for backward compatibility with consumers.
public typealias iOSImagesEntry = iOS.ImagesEntry

// MARK: - Convenience Extensions

public extension iOS.ImagesEntry {
    /// Returns an ImagesSourceInput for use with ImagesExportContext.
    func imagesSourceInput(darkFileId: String? = nil) -> ImagesSourceInput {
        ImagesSourceInput(
            darkFileId: darkFileId,
            frameName: figmaFrameName ?? "Images",
            sourceFormat: sourceFormat.flatMap { ImageSourceFormat(rawValue: $0.rawValue) } ?? .png,
            scales: effectiveScales,
            useSingleFile: darkFileId == nil,
            darkModeSuffix: "_dark",
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp
        )
    }

    /// Effective output format, defaulting to PNG.
    var effectiveOutputFormat: ImageOutputFormat {
        outputFormat.flatMap { ImageOutputFormat(rawValue: $0.rawValue) } ?? .png
    }

    /// Effective scales, defaulting to iOS standard [1.0, 2.0, 3.0].
    var effectiveScales: [Double] {
        scales?.map { Double($0) } ?? [1.0, 2.0, 3.0]
    }

    /// Converts PKL NameStyle to ExFigCore NameStyle.
    var coreNameStyle: NameStyle {
        switch nameStyle {
        case .camelCase: .camelCase
        case .snake_case: .snakeCase
        case .pascalCase: .pascalCase
        case .flatCase: .flatCase
        case .kebab_case: .kebabCase
        case .sCREAMING_SNAKE_CASE: .screamingSnakeCase
        }
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

    /// Converts entry's HEIC options to protocol-level HeicConverterOptions.
    var heicConverterOptions: HeicConverterOptions? {
        guard let opts = heicOptions else { return nil }
        return HeicConverterOptions(
            encoding: nil,
            quality: opts.quality
        )
    }
}

// swiftlint:enable type_name
