import ExFigConfig

// MARK: - ExFig.ModuleImpl FileIdProvider

extension ExFig.ModuleImpl: FileIdProvider {
    /// Collects all unique Figma file IDs from all configuration sources.
    func getFileIds() -> Set<String> {
        var ids = Set<String>()

        // Base Figma file IDs (design files)
        ids.formUnion(baseFigmaFileIds)

        // Variables API tokensFileId (PRIMARY for colors)
        if let id = common?.variablesColors?.tokensFileId {
            ids.insert(id)
        }

        // Multi-entry colors - each platform may have different tokensFileIds
        ids.formUnion(colorsTokensFileIds)

        // Icons/Images entries - each may override figmaFileId per-entry (Common.FrameSource)
        ids.formUnion(frameSourceFileIds)

        // Typography - per-entry fileId override (iOS and Android only)
        if let id = ios?.typography?.fileId, !id.isEmpty { ids.insert(id) }
        if let id = android?.typography?.fileId, !id.isEmpty { ids.insert(id) }

        return ids
    }

    private var baseFigmaFileIds: Set<String> {
        var ids = Set<String>()
        if let id = figma?.lightFileId { ids.insert(id) }
        if let id = figma?.darkFileId { ids.insert(id) }
        if let id = figma?.lightHighContrastFileId { ids.insert(id) }
        if let id = figma?.darkHighContrastFileId { ids.insert(id) }
        return ids
    }

    private var colorsTokensFileIds: Set<String> {
        var ids = Set<String>()
        collectTokensFileIds(from: ios?.colors, into: &ids)
        collectTokensFileIds(from: android?.colors, into: &ids)
        collectTokensFileIds(from: flutter?.colors, into: &ids)
        collectTokensFileIds(from: web?.colors, into: &ids)
        return ids
    }

    private func collectTokensFileIds(from entries: [some Common_VariablesSource]?, into ids: inout Set<String>) {
        guard let entries else { return }
        ids.formUnion(entries.compactMap(\.tokensFileId).filter { !$0.isEmpty })
    }

    private var frameSourceFileIds: Set<String> {
        var ids = Set<String>()
        for entries in [
            ios?.icons?.map(\.figmaFileId),
            android?.icons?.map(\.figmaFileId),
            flutter?.icons?.map(\.figmaFileId),
            web?.icons?.map(\.figmaFileId),
            ios?.images?.map(\.figmaFileId),
            android?.images?.map(\.figmaFileId),
            flutter?.images?.map(\.figmaFileId),
            web?.images?.map(\.figmaFileId),
        ] {
            if let entries {
                ids.formUnion(entries.compactMap { $0 }.filter { !$0.isEmpty })
            }
        }
        return ids
    }
}
