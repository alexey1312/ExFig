// MARK: - iOS Colors Configuration

extension PKLConfig.iOS.ColorsConfiguration: FileIdProvider {
    func getFileIds() -> Set<String> {
        switch self {
        case .legacy:
            // Legacy format: tokensFileId is in common.variablesColors
            []
        case let .multiple(entries):
            // Multi-entry format: each entry has its own tokensFileId
            Set(entries.map(\.tokensFileId).filter { !$0.isEmpty })
        }
    }
}

// MARK: - Android Colors Configuration

extension PKLConfig.Android.ColorsConfiguration: FileIdProvider {
    func getFileIds() -> Set<String> {
        switch self {
        case .legacy:
            []
        case let .multiple(entries):
            Set(entries.map(\.tokensFileId).filter { !$0.isEmpty })
        }
    }
}

// MARK: - Flutter Colors Configuration

extension PKLConfig.Flutter.ColorsConfiguration: FileIdProvider {
    func getFileIds() -> Set<String> {
        switch self {
        case .legacy:
            []
        case let .multiple(entries):
            Set(entries.map(\.tokensFileId).filter { !$0.isEmpty })
        }
    }
}

// MARK: - Web Colors Configuration

extension PKLConfig.Web.ColorsConfiguration: FileIdProvider {
    func getFileIds() -> Set<String> {
        switch self {
        case .legacy:
            []
        case let .multiple(entries):
            Set(entries.map(\.tokensFileId).filter { !$0.isEmpty })
        }
    }
}

// MARK: - PKLConfig Aggregation

extension PKLConfig: FileIdProvider {
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
        if let colors = ios?.colors { ids.formUnion(colors.getFileIds()) }
        if let colors = android?.colors { ids.formUnion(colors.getFileIds()) }
        if let colors = flutter?.colors { ids.formUnion(colors.getFileIds()) }
        if let colors = web?.colors { ids.formUnion(colors.getFileIds()) }

        return ids
    }
}
