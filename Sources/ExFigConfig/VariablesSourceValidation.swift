import ExFigCore

public extension Common_VariablesSource {
    /// Returns a validated `ColorsSourceInput` for use with `ColorsExportContext`.
    ///
    /// When `tokensFile` is set, bypasses Figma API validation and returns a local-file source.
    /// Otherwise, throws if required Figma fields (`tokensFileId`, `tokensCollectionName`,
    /// `lightModeName`) are nil or empty.
    func validatedColorsSourceInput() throws -> ColorsSourceInput {
        // Local tokens file source — bypass Figma validation
        if let tokensFile {
            return ColorsSourceInput(
                tokensFilePath: tokensFile.path,
                tokensFileGroupFilter: tokensFile.groupFilter,
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

        // Figma Variables source — require all fields
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
