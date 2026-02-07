import ExFigConfig
import ExFigCore
import Foundation

/// Typealias for backward compatibility with consumers.
public typealias FlutterColorsEntry = Flutter.ColorsEntry

// MARK: - Convenience Extensions

public extension Flutter.ColorsEntry {
    /// Returns a validated ColorsSourceInput for use with ColorsExportContext.
    /// Throws if required fields (tokensFileId, tokensCollectionName, lightModeName) are nil or empty.
    func validatedColorsSourceInput() throws -> ColorsSourceInput {
        guard let tokensFileId, !tokensFileId.isEmpty else {
            throw ColorsConfigError.missingTokensFileId
        }
        guard let tokensCollectionName, !tokensCollectionName.isEmpty else {
            throw ColorsConfigError.missingTokensCollectionName
        }
        guard let lightModeName, !lightModeName.isEmpty else {
            throw ColorsConfigError.missingLightModeName
        }
        return ColorsSourceInput(
            tokensFileId: tokensFileId,
            tokensCollectionName: tokensCollectionName,
            lightModeName: lightModeName,
            darkModeName: darkModeName,
            lightHCModeName: lightHCModeName,
            darkHCModeName: darkHCModeName,
            primitivesModeName: primitivesModeName,
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp
        )
    }
}
