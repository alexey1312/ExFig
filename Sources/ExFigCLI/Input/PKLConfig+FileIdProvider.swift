import ExFigConfig

// MARK: - ExFig.ModuleImpl FileIdProvider

extension ExFig.ModuleImpl: FileIdProvider {
    /// Collects all unique Figma file IDs from all configuration sources.
    func getFileIds() -> Set<String> {
        var ids = Set<String>()

        // Base Figma file IDs (design files)
        if let id = figma?.lightFileId { ids.insert(id) }
        if let id = figma?.darkFileId { ids.insert(id) }
        if let id = figma?.lightHighContrastFileId { ids.insert(id) }
        if let id = figma?.darkHighContrastFileId { ids.insert(id) }

        // Variables API tokensFileId (PRIMARY for colors)
        if let id = common?.variablesColors?.tokensFileId {
            ids.insert(id)
        }

        // Multi-entry colors - each platform may have different tokensFileIds
        if let entries = ios?.colors {
            ids.formUnion(entries.compactMap(\.tokensFileId).filter { !$0.isEmpty })
        }
        if let entries = android?.colors {
            ids.formUnion(entries.compactMap(\.tokensFileId).filter { !$0.isEmpty })
        }
        if let entries = flutter?.colors {
            ids.formUnion(entries.compactMap(\.tokensFileId).filter { !$0.isEmpty })
        }
        if let entries = web?.colors {
            ids.formUnion(entries.compactMap(\.tokensFileId).filter { !$0.isEmpty })
        }

        return ids
    }
}
