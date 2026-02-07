import ExFigConfig
import ExFigCore
import Foundation

/// Typealias for backward compatibility with consumers.
public typealias WebColorsEntry = Web.ColorsEntry

// MARK: - Convenience Extensions

public extension Web.ColorsEntry {
    /// Returns a ColorsSourceInput for use with ColorsExportContext.
    var colorsSourceInput: ColorsSourceInput {
        ColorsSourceInput(
            tokensFileId: tokensFileId ?? "",
            tokensCollectionName: tokensCollectionName ?? "",
            lightModeName: lightModeName ?? "",
            darkModeName: darkModeName,
            lightHCModeName: lightHCModeName,
            darkHCModeName: darkHCModeName,
            primitivesModeName: primitivesModeName,
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp
        )
    }
}
