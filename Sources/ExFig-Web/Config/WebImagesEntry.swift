import ExFigConfig
import ExFigCore
import Foundation

/// Typealias for backward compatibility with consumers.
public typealias WebImagesEntry = Web.ImagesEntry

// MARK: - Convenience Extensions

public extension Web.ImagesEntry {
    /// Returns an ImagesSourceInput for use with ImagesExportContext.
    func imagesSourceInput(darkFileId: String? = nil) -> ImagesSourceInput {
        ImagesSourceInput(
            darkFileId: darkFileId,
            frameName: figmaFrameName ?? "Images",
            sourceFormat: .svg,
            scales: [1.0],
            useSingleFile: darkFileId == nil,
            darkModeSuffix: "_dark",
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp
        )
    }

    /// Whether to generate React components, defaulting to true.
    var effectiveGenerateReactComponents: Bool {
        generateReactComponents ?? true
    }
}
