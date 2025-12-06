import ExFigCore
import FigmaAPI
import Foundation
import Logging

/// Output type for icons loading operations.
typealias IconsLoaderOutput = (light: [ImagePack], dark: [ImagePack]?)

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
}
