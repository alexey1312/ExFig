import ExFigCore
import FigmaAPI
import Foundation
import Logging

/// Output type for images loading operations.
typealias ImagesLoaderOutput = (light: [ImagePack], dark: [ImagePack]?)

/// Loads images (illustrations) from Figma files.
final class ImagesLoader: ImageLoaderBase, @unchecked Sendable {
    private var frameName: String {
        params.common?.images?.figmaFrameName ?? "Illustrations"
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

    // MARK: - Private Loading Methods

    private func loadFromSingleFile(
        filter: String? = nil,
        onBatchProgress: @escaping BatchProgressCallback
    ) async throws -> ImagesLoaderOutput {
        let darkSuffix = params.common?.images?.darkModeSuffix ?? "_dark"

        switch (platform, params.android?.images?.format) {
        case (.android, .png), (.android, .webp), (.ios, _):
            let scales = getScales(customScales: platform == .android
                ? params.android?.images?.scales
                : params.ios?.images?.scales)

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

        switch (platform, params.android?.images?.format) {
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
        let scales = getScales(customScales: platform == .android
            ? params.android?.images?.scales
            : params.ios?.images?.scales)

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
}
