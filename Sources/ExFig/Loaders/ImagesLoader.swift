// swiftlint:disable file_length
import ExFigCore
import FigmaAPI
import Foundation
import Logging

/// Configuration for loading images from a specific Figma frame.
struct ImagesLoaderConfig: Sendable {
    /// Figma frame name to load images from.
    let frameName: String

    /// Custom scales for raster images.
    let scales: [Double]?

    /// Creates config for a specific iOS images entry.
    static func forIOS(entry: Params.iOS.ImagesEntry, params: Params) -> ImagesLoaderConfig {
        ImagesLoaderConfig(
            frameName: entry.figmaFrameName ?? params.common?.images?.figmaFrameName ?? "Illustrations",
            scales: entry.scales
        )
    }

    /// Creates config for a specific Android images entry.
    static func forAndroid(entry: Params.Android.ImagesEntry, params: Params) -> ImagesLoaderConfig {
        ImagesLoaderConfig(
            frameName: entry.figmaFrameName ?? params.common?.images?.figmaFrameName ?? "Illustrations",
            scales: entry.scales
        )
    }

    /// Creates config for a specific Flutter images entry.
    static func forFlutter(entry: Params.Flutter.ImagesEntry, params: Params) -> ImagesLoaderConfig {
        ImagesLoaderConfig(
            frameName: entry.figmaFrameName ?? params.common?.images?.figmaFrameName ?? "Illustrations",
            scales: entry.scales
        )
    }

    /// Creates default config from params (for backward compatibility).
    static func defaultConfig(params: Params) -> ImagesLoaderConfig {
        ImagesLoaderConfig(
            frameName: params.common?.images?.figmaFrameName ?? "Illustrations",
            scales: nil
        )
    }
}

/// Output type for images loading operations.
typealias ImagesLoaderOutput = (light: [ImagePack], dark: [ImagePack]?)

/// Output type for images loading with granular cache tracking (vector images only).
struct ImagesLoaderResultWithHashes {
    let light: [ImagePack]
    let dark: [ImagePack]?
    /// Computed hashes for granular cache update (fileId → (nodeId → hash)).
    let computedHashes: [String: [NodeId: String]]
    /// Whether all images were skipped by granular cache.
    let allSkipped: Bool
    /// All image names before filtering (for template generation).
    let allNames: [String]
}

/// Loads images (illustrations) from Figma files.
final class ImagesLoader: ImageLoaderBase, @unchecked Sendable { // swiftlint:disable:this type_body_length
    private let config: ImagesLoaderConfig

    init(
        client: Client,
        params: Params,
        platform: Platform,
        logger: Logger,
        config: ImagesLoaderConfig? = nil
    ) {
        self.config = config ?? ImagesLoaderConfig.defaultConfig(params: params)
        super.init(client: client, params: params, platform: platform, logger: logger)
    }

    private var frameName: String {
        config.frameName
    }

    /// Custom scales from config, or nil to use defaults.
    private var configScales: [Double]? {
        config.scales
    }

    /// Loads images from Figma, supporting both single-file and separate light/dark file modes.
    func load(
        filter: String? = nil,
        onBatchProgress: @escaping BatchProgressCallback = { _, _ in }
    ) async throws -> ImagesLoaderOutput {
        if let useSingleFile = params.common?.images?.useSingleFile, useSingleFile {
            try await loadFromSingleFile(filter: filter, onBatchProgress: onBatchProgress)
        } else {
            try await loadFromLightAndDarkFile(filter: filter, onBatchProgress: onBatchProgress)
        }
    }

    /// Loads images with granular cache tracking for per-node change detection.
    ///
    /// Note: Granular cache only applies to vector images (SVG format). For raster
    /// images (PNG/WebP), this method falls back to regular loading since they use
    /// multi-scale exports with different component loading.
    ///
    /// When `granularCacheManager` is set, this method computes hashes for each image
    /// component and filters to only changed images. Returns computed hashes for
    /// cache update after successful export.
    func loadWithGranularCache(
        filter: String? = nil,
        onBatchProgress: @escaping BatchProgressCallback = { _, _ in }
    ) async throws -> ImagesLoaderResultWithHashes {
        if let useSingleFile = params.common?.images?.useSingleFile, useSingleFile {
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
    ) async throws -> ImagesLoaderOutput {
        let darkSuffix = params.common?.images?.darkModeSuffix ?? "_dark"

        switch (platform, params.android?.images?.entries.first?.format) {
        case (.android, .png), (.android, .webp), (.ios, _):
            let scales = getScales(customScales: configScales)

            let images = try await loadPNGImages(
                fileId: params.figma.lightFileId,
                frameName: frameName,
                filter: filter,
                scales: scales,
                onBatchProgress: onBatchProgress
            )
            let (lightImages, darkImages) = splitByDarkMode(images, darkSuffix: darkSuffix)
            return (lightImages, darkImages)

        default:
            let pack = try await loadVectorImages(
                fileId: params.figma.lightFileId,
                frameName: frameName,
                params: SVGParams(),
                filter: filter,
                onBatchProgress: onBatchProgress
            )
            let (lightPack, darkPack) = splitByDarkMode(pack, darkSuffix: darkSuffix)
            return (lightPack, darkPack)
        }
    }

    private func loadFromLightAndDarkFile(
        filter: String? = nil,
        onBatchProgress: @escaping BatchProgressCallback
    ) async throws -> ImagesLoaderOutput {
        // Build list of files to load
        var filesToLoad: [(key: String, fileId: String)] = [
            ("light", params.figma.lightFileId),
        ]
        if let darkFileId = params.figma.darkFileId {
            filesToLoad.append(("dark", darkFileId))
        }

        switch (platform, params.android?.images?.entries.first?.format) {
        case (.android, .png), (.android, .webp), (.ios, _):
            return try await loadRasterImagesFromMultipleFiles(
                filesToLoad: filesToLoad,
                filter: filter,
                onBatchProgress: onBatchProgress
            )
        default:
            return try await loadVectorImagesFromMultipleFiles(
                filesToLoad: filesToLoad,
                filter: filter,
                onBatchProgress: onBatchProgress
            )
        }
    }

    private func loadRasterImagesFromMultipleFiles(
        filesToLoad: [(key: String, fileId: String)],
        filter: String?,
        onBatchProgress: @escaping BatchProgressCallback
    ) async throws -> ImagesLoaderOutput {
        let scales = getScales(customScales: configScales)

        // Load all files in parallel for PNG/WebP
        let results = try await withThrowingTaskGroup(
            of: (String, [ImagePack]).self
        ) { [self] group in
            for (key, fileId) in filesToLoad {
                group.addTask { [key, fileId, filter, scales, onBatchProgress] in
                    let images = try await self.loadPNGImages(
                        fileId: fileId,
                        frameName: self.frameName,
                        filter: filter,
                        scales: scales,
                        onBatchProgress: onBatchProgress
                    )
                    return (key, images)
                }
            }

            var imagesByKey: [String: [ImagePack]] = [:]
            for try await (key, images) in group {
                imagesByKey[key] = images
            }
            return imagesByKey
        }

        guard let lightImages = results["light"] else {
            throw ExFigError.componentsNotFound
        }

        return (lightImages, results["dark"])
    }

    private func loadVectorImagesFromMultipleFiles(
        filesToLoad: [(key: String, fileId: String)],
        filter: String?,
        onBatchProgress: @escaping BatchProgressCallback
    ) async throws -> ImagesLoaderOutput {
        // Load all files in parallel for SVG
        let results = try await withThrowingTaskGroup(
            of: (String, [ImagePack]).self
        ) { [self] group in
            for (key, fileId) in filesToLoad {
                group.addTask { [key, fileId, filter, onBatchProgress] in
                    let packs = try await self.loadVectorImages(
                        fileId: fileId,
                        frameName: self.frameName,
                        params: SVGParams(),
                        filter: filter,
                        onBatchProgress: onBatchProgress
                    )
                    return (key, packs)
                }
            }

            var packsByKey: [String: [ImagePack]] = [:]
            for try await (key, packs) in group {
                packsByKey[key] = packs
            }
            return packsByKey
        }

        guard let lightPacks = results["light"] else {
            throw ExFigError.componentsNotFound
        }

        return (lightPacks, results["dark"])
    }

    // MARK: - Granular Cache Methods

    private func loadFromSingleFileWithGranularCache( // swiftlint:disable:this function_body_length
        filter: String? = nil,
        onBatchProgress: @escaping BatchProgressCallback
    ) async throws -> ImagesLoaderResultWithHashes {
        let fileId = params.figma.lightFileId
        let darkSuffix = params.common?.images?.darkModeSuffix ?? "_dark"

        switch (platform, params.android?.images?.entries.first?.format) {
        case (.android, .png), (.android, .webp), (.ios, _):
            // Raster images (PNG/WebP) with granular cache
            let scales = getScales(customScales: configScales)

            let result = try await loadPNGImagesWithGranularCache(
                fileId: fileId,
                frameName: frameName,
                filter: filter,
                scales: scales,
                onBatchProgress: onBatchProgress
            )

            // Filter out dark mode names - they should not appear as separate properties
            let lightOnlyNames = result.allNames.filter { !$0.hasSuffix(darkSuffix) }

            if result.allSkipped {
                return ImagesLoaderResultWithHashes(
                    light: [],
                    dark: nil,
                    computedHashes: [fileId: result.computedHashes],
                    allSkipped: true,
                    allNames: lightOnlyNames
                )
            }

            let (lightImages, darkImages) = splitByDarkMode(result.packs, darkSuffix: darkSuffix)
            return ImagesLoaderResultWithHashes(
                light: lightImages,
                dark: darkImages,
                computedHashes: [fileId: result.computedHashes],
                allSkipped: false,
                allNames: lightOnlyNames
            )

        default:
            // Vector images (SVG) with granular cache
            let result = try await loadVectorImagesWithGranularCache(
                fileId: fileId,
                frameName: frameName,
                params: SVGParams(),
                filter: filter,
                onBatchProgress: onBatchProgress
            )

            // Filter out dark mode names - they should not appear as separate properties
            let lightOnlyNames = result.allNames.filter { !$0.hasSuffix(darkSuffix) }

            if result.allSkipped {
                return ImagesLoaderResultWithHashes(
                    light: [],
                    dark: nil,
                    computedHashes: [fileId: result.computedHashes],
                    allSkipped: true,
                    allNames: lightOnlyNames
                )
            }

            let (lightPacks, darkPacks) = splitByDarkMode(result.packs, darkSuffix: darkSuffix)
            return ImagesLoaderResultWithHashes(
                light: lightPacks,
                dark: darkPacks,
                computedHashes: [fileId: result.computedHashes],
                allSkipped: false,
                allNames: lightOnlyNames
            )
        }
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

    private func loadFromLightAndDarkFileWithGranularCache( // swiftlint:disable:this function_body_length
        filter: String? = nil,
        onBatchProgress: @escaping BatchProgressCallback
    ) async throws -> ImagesLoaderResultWithHashes {
        // Build list of files to load
        var filesToLoad: [(key: String, fileId: String)] = [
            ("light", params.figma.lightFileId),
        ]
        if let darkFileId = params.figma.darkFileId {
            filesToLoad.append(("dark", darkFileId))
        }

        // Determine format and scales once (same for all files)
        let isRasterFormat: Bool
        let scales: [Double]

        switch (platform, params.android?.images?.entries.first?.format) {
        case (.android, .png), (.android, .webp), (.ios, _):
            isRasterFormat = true
            scales = getScales(customScales: configScales)
        default:
            isRasterFormat = false
            scales = []
        }

        // Load all files in parallel
        let results = try await withThrowingTaskGroup(of: FileGranularResult.self) { [self] group in
            for (key, fileId) in filesToLoad {
                group.addTask { [key, fileId, filter, onBatchProgress, isRasterFormat, scales] in
                    if isRasterFormat {
                        // Raster images (PNG/WebP)
                        let result = try await self.loadPNGImagesWithGranularCache(
                            fileId: fileId,
                            frameName: self.frameName,
                            filter: filter,
                            scales: scales,
                            onBatchProgress: onBatchProgress
                        )
                        return FileGranularResult(
                            key: key,
                            fileId: fileId,
                            packs: result.packs,
                            hashes: result.computedHashes,
                            allSkipped: result.allSkipped,
                            allNames: result.allNames
                        )
                    } else {
                        // Vector images (SVG)
                        let result = try await self.loadVectorImagesWithGranularCache(
                            fileId: fileId,
                            frameName: self.frameName,
                            params: SVGParams(),
                            filter: filter,
                            onBatchProgress: onBatchProgress
                        )
                        return FileGranularResult(
                            key: key,
                            fileId: fileId,
                            packs: result.packs,
                            hashes: result.computedHashes,
                            allSkipped: result.allSkipped,
                            allNames: result.allNames
                        )
                    }
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
            return ImagesLoaderResultWithHashes(
                light: [],
                dark: nil,
                computedHashes: computedHashes,
                allSkipped: true,
                allNames: allNames
            )
        }

        // Extract light and dark packs
        guard let lightResult else {
            throw ExFigError.componentsNotFound
        }

        let darkResult = results.first(where: { $0.key == "dark" })

        return ImagesLoaderResultWithHashes(
            light: lightResult.packs,
            dark: darkResult?.packs,
            computedHashes: computedHashes,
            allSkipped: false,
            allNames: allNames
        )
    }
}
