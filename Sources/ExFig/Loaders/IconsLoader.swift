import ExFigCore
import FigmaAPI
import Foundation
import Logging

/// Output type for icons loading operations.
typealias IconsLoaderOutput = (light: [ImagePack], dark: [ImagePack]?)

/// Output type for icons loading with granular cache tracking.
struct IconsLoaderResultWithHashes {
    let light: [ImagePack]
    let dark: [ImagePack]?
    /// Computed hashes for granular cache update (fileId → (nodeId → hash)).
    let computedHashes: [String: [NodeId: String]]
    /// Whether all icons were skipped by granular cache.
    let allSkipped: Bool
    /// All icon names before filtering (for template generation).
    let allNames: [String]
}

/// Loads icons from Figma files.
final class IconsLoader: ImageLoaderBase, @unchecked Sendable {
    private var frameName: String {
        params.common?.icons?.figmaFrameName ?? "Icons"
    }

    /// Loads icons from Figma, supporting both single-file and separate light/dark file modes.
    func load(
        filter: String? = nil,
        onBatchProgress: @escaping BatchProgressCallback = { _, _ in }
    ) async throws -> IconsLoaderOutput {
        if let useSingleFile = params.common?.icons?.useSingleFile, useSingleFile {
            try await loadFromSingleFile(filter: filter, onBatchProgress: onBatchProgress)
        } else {
            try await loadFromLightAndDarkFile(filter: filter, onBatchProgress: onBatchProgress)
        }
    }

    /// Loads icons with granular cache tracking for per-node change detection.
    ///
    /// When `granularCacheManager` is set, this method computes hashes for each icon
    /// component and filters to only changed icons. Returns computed hashes for
    /// cache update after successful export.
    func loadWithGranularCache(
        filter: String? = nil,
        onBatchProgress: @escaping BatchProgressCallback = { _, _ in }
    ) async throws -> IconsLoaderResultWithHashes {
        if let useSingleFile = params.common?.icons?.useSingleFile, useSingleFile {
            try await loadFromSingleFileWithGranularCache(
                filter: filter, onBatchProgress: onBatchProgress
            )
        } else {
            try await loadFromLightAndDarkFileWithGranularCache(
                filter: filter, onBatchProgress: onBatchProgress
            )
        }
    }

    // MARK: - Private Loading Methods

    private func loadFromSingleFile(
        filter: String? = nil,
        onBatchProgress: @escaping BatchProgressCallback
    ) async throws -> IconsLoaderOutput {
        let formatParams = makeFormatParams()

        let icons = try await loadVectorImages(
            fileId: params.figma.lightFileId,
            frameName: frameName,
            params: formatParams,
            filter: filter,
            onBatchProgress: onBatchProgress
        )

        let darkSuffix = params.common?.icons?.darkModeSuffix ?? "_dark"
        let (lightIcons, darkIcons) = splitByDarkMode(icons, darkSuffix: darkSuffix)

        return (
            lightIcons.map { updateRenderMode($0) },
            darkIcons.map { updateRenderMode($0) }
        )
    }

    private func loadFromLightAndDarkFile(
        filter: String? = nil,
        onBatchProgress: @escaping BatchProgressCallback
    ) async throws -> IconsLoaderOutput {
        // Build list of files to load
        var filesToLoad: [(key: String, fileId: String)] = [
            ("light", params.figma.lightFileId),
        ]
        if let darkFileId = params.figma.darkFileId {
            filesToLoad.append(("dark", darkFileId))
        }

        // Load all files in parallel
        let results = try await withThrowingTaskGroup(
            of: (String, [ImagePack]).self
        ) { [self] group in
            for (key, fileId) in filesToLoad {
                group.addTask { [key, fileId, filter, onBatchProgress] in
                    // Create format params inside task to avoid Sendable issues
                    let formatParams = self.makeFormatParams()

                    let icons = try await self.loadVectorImages(
                        fileId: fileId,
                        frameName: self.frameName,
                        params: formatParams,
                        filter: filter,
                        onBatchProgress: onBatchProgress
                    ).map { self.updateRenderMode($0) }
                    return (key, icons)
                }
            }

            var iconsByKey: [String: [ImagePack]] = [:]
            for try await (key, icons) in group {
                iconsByKey[key] = icons
            }
            return iconsByKey
        }

        guard let lightIcons = results["light"] else {
            throw ExFigError.componentsNotFound
        }

        return (lightIcons, results["dark"])
    }

    // MARK: - Helpers

    private func makeFormatParams() -> FormatParams {
        switch (platform, params.ios?.icons?.format) {
        case (.android, _), (.ios, .svg):
            SVGParams()
        case (.ios, _):
            PDFParams()
        }
    }

    private func updateRenderMode(_ icon: ImagePack) -> ImagePack {
        // Filtering at suffixes
        var renderMode = params.ios?.icons?.renderMode ?? .template
        let defaultSuffix = renderMode == .template ? params.ios?.icons?.renderModeDefaultSuffix : nil
        let originalSuffix = renderMode == .template ? params.ios?.icons?.renderModeOriginalSuffix : nil
        let templateSuffix = renderMode != .template ? params.ios?.icons?.renderModeTemplateSuffix : nil
        var suffix: String?

        if let defaultSuffix, icon.name.hasSuffix(defaultSuffix) {
            renderMode = .default
            suffix = defaultSuffix
        } else if let originalSuffix, icon.name.hasSuffix(originalSuffix) {
            renderMode = .original
            suffix = originalSuffix
        } else if let templateSuffix, icon.name.hasSuffix(templateSuffix) {
            renderMode = .template
            suffix = templateSuffix
        }
        var newIcon = icon
        newIcon.name = String(icon.name.dropLast(suffix?.count ?? 0))
        newIcon.renderMode = renderMode
        return newIcon
    }

    // MARK: - Granular Cache Methods

    private func loadFromSingleFileWithGranularCache(
        filter: String? = nil,
        onBatchProgress: @escaping BatchProgressCallback
    ) async throws -> IconsLoaderResultWithHashes {
        let formatParams = makeFormatParams()
        let fileId = params.figma.lightFileId
        let darkSuffix = params.common?.icons?.darkModeSuffix ?? "_dark"

        let result = try await loadVectorImagesWithGranularCache(
            fileId: fileId,
            frameName: frameName,
            params: formatParams,
            filter: filter,
            onBatchProgress: onBatchProgress
        )

        // Filter out dark mode names - they should not appear as separate properties
        let lightOnlyNames = result.allNames.filter { !$0.hasSuffix(darkSuffix) }

        if result.allSkipped {
            return IconsLoaderResultWithHashes(
                light: [],
                dark: nil,
                computedHashes: [fileId: result.computedHashes],
                allSkipped: true,
                allNames: lightOnlyNames
            )
        }

        let (lightIcons, darkIcons) = splitByDarkMode(result.packs, darkSuffix: darkSuffix)

        return IconsLoaderResultWithHashes(
            light: lightIcons.map { updateRenderMode($0) },
            dark: darkIcons.map { updateRenderMode($0) },
            computedHashes: [fileId: result.computedHashes],
            allSkipped: false,
            allNames: lightOnlyNames
        )
    }

    /// Result of loading a single file with granular cache.
    private struct FileGranularResult: Sendable {
        let key: String
        let fileId: String
        let packs: [ImagePack]
        let hashes: [NodeId: String]
        let allSkipped: Bool
        let allNames: [String]
    }

    // swiftlint:disable:next function_body_length
    private func loadFromLightAndDarkFileWithGranularCache(
        filter: String? = nil,
        onBatchProgress: @escaping BatchProgressCallback
    ) async throws -> IconsLoaderResultWithHashes {
        // Build list of files to load
        var filesToLoad: [(key: String, fileId: String)] = [
            ("light", params.figma.lightFileId),
        ]
        if let darkFileId = params.figma.darkFileId {
            filesToLoad.append(("dark", darkFileId))
        }

        // Load all files in parallel
        let results = try await withThrowingTaskGroup(of: FileGranularResult.self) { [self] group in
            for (key, fileId) in filesToLoad {
                group.addTask { [key, fileId, filter, onBatchProgress] in
                    let formatParams = self.makeFormatParams()

                    let result = try await self.loadVectorImagesWithGranularCache(
                        fileId: fileId,
                        frameName: self.frameName,
                        params: formatParams,
                        filter: filter,
                        onBatchProgress: onBatchProgress
                    )

                    let packs = result.packs.map { self.updateRenderMode($0) }
                    return FileGranularResult(
                        key: key,
                        fileId: fileId,
                        packs: packs,
                        hashes: result.computedHashes,
                        allSkipped: result.allSkipped,
                        allNames: result.allNames
                    )
                }
            }

            var fileResults: [FileGranularResult] = []
            for try await result in group {
                fileResults.append(result)
            }
            return fileResults
        }

        // Build computed hashes map
        var computedHashes: [String: [NodeId: String]] = [:]
        for result in results {
            computedHashes[result.fileId] = result.hashes
        }

        // Collect all names from light file (primary source for template generation)
        let lightResult = results.first(where: { $0.key == "light" })
        let allNames = lightResult?.allNames ?? []

        // Check if all files were skipped
        let allSkipped = results.allSatisfy(\.allSkipped)
        if allSkipped {
            return IconsLoaderResultWithHashes(
                light: [],
                dark: nil,
                computedHashes: computedHashes,
                allSkipped: true,
                allNames: allNames
            )
        }

        // Extract light and dark icons
        guard let lightResult else {
            throw ExFigError.componentsNotFound
        }

        let darkResult = results.first(where: { $0.key == "dark" })

        return IconsLoaderResultWithHashes(
            light: lightResult.packs,
            dark: darkResult?.packs,
            computedHashes: computedHashes,
            allSkipped: false,
            allNames: allNames
        )
    }
}
