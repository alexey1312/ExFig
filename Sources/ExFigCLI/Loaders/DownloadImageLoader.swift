import ExFigCore
import FigmaAPI
import Foundation
import Logging

/// Simplified image loader for the download command.
/// Does not depend on Params struct - uses direct parameters.
final class DownloadImageLoader: Sendable {
    private let client: Client
    private let logger: Logger

    init(client: Client, logger: Logger) {
        self.client = client
        self.logger = logger
    }

    /// Loads vector images (SVG/PDF) from Figma.
    func loadVectorImages(
        fileId: String,
        frameName: String,
        pageName: String? = nil,
        params: FormatParams,
        filter: String?,
        onBatchProgress: @escaping BatchProgressCallback = { _, _ in }
    ) async throws -> [ImagePack] {
        var imagesDict = try await fetchImageComponents(
            fileId: fileId,
            frameName: frameName,
            pageName: pageName,
            filter: filter
        )

        guard !imagesDict.isEmpty else {
            throw ExFigError.componentsNotFound(frameName: frameName, pageName: pageName)
        }

        // Filter out empty names
        imagesDict = imagesDict.filter { (_: NodeId, component: Component) in
            !component.name.trimmingCharacters(in: .whitespaces).isEmpty
        }

        logger.info("Fetching \(imagesDict.count) images from '\(frameName)'...")
        let imageIdToImagePath = try await loadImages(
            fileId: fileId,
            imagesDict: imagesDict,
            params: params,
            onBatchProgress: onBatchProgress
        )

        // Remove components for which image file could not be fetched
        let badNodeIds = Set(imagesDict.keys).symmetricDifference(Set(imageIdToImagePath.keys))
        for nodeId in badNodeIds {
            imagesDict.removeValue(forKey: nodeId)
        }

        // Create image packs
        return imagesDict.compactMap { nodeId, component -> ImagePack? in
            guard let urlString = imageIdToImagePath[nodeId],
                  let url = URL(string: urlString)
            else {
                return nil
            }
            let image = Image(
                name: component.name,
                scale: .all,
                url: url,
                format: params.format
            )
            return ImagePack(name: component.name, images: [image], platform: nil)
        }
    }

    /// Loads raster images (PNG/JPG) from Figma at a specific scale.
    func loadRasterImages(
        fileId: String,
        frameName: String,
        pageName: String? = nil,
        scale: Double,
        format: String,
        filter: String?,
        onBatchProgress: @escaping BatchProgressCallback = { _, _ in }
    ) async throws -> [ImagePack] {
        let imagesDict = try await fetchImageComponents(
            fileId: fileId,
            frameName: frameName,
            pageName: pageName,
            filter: filter
        )

        guard !imagesDict.isEmpty else {
            throw ExFigError.componentsNotFound(frameName: frameName, pageName: pageName)
        }

        logger.info("Fetching \(imagesDict.count) images from '\(frameName)' at \(scale)x...")
        let params = FormatParams(scale: scale, format: format)
        let imageIdToImagePath = try await loadImages(
            fileId: fileId,
            imagesDict: imagesDict,
            params: params,
            onBatchProgress: onBatchProgress
        )

        // Create image packs
        return imagesDict.compactMap { nodeId, component -> ImagePack? in
            guard let urlString = imageIdToImagePath[nodeId],
                  let url = URL(string: urlString)
            else {
                return nil
            }

            let image = Image(
                name: component.name,
                scale: .individual(scale),
                url: url,
                format: format
            )
            return ImagePack(name: component.name, images: [image], platform: nil)
        }
    }

    // MARK: - Private Methods

    private func fetchImageComponents(
        fileId: String,
        frameName: String,
        pageName: String? = nil,
        filter: String?
    ) async throws -> [NodeId: Component] {
        let allComponents = try await loadComponents(fileId: fileId)
        var components = allComponents
            .filter {
                $0.containingFrame.name == frameName
                    && (pageName == nil || $0.containingFrame.pageName == pageName)
            }

        if let pageName, components.isEmpty {
            let frameComponents = allComponents.filter { $0.containingFrame.name == frameName }
            if !frameComponents.isEmpty {
                let availablePages = Set(frameComponents.compactMap(\.containingFrame.pageName))
                let pages = availablePages.sorted().joined(separator: ", ")
                logger.info(
                    "Page filter '\(pageName)' matched no components in frame '\(frameName)'. Available pages: \(pages)"
                )
            }
        }

        if let filter {
            let assetsFilter = AssetsFilter(filter: filter)
            components = components.filter { component -> Bool in
                assetsFilter.match(name: component.name)
            }
        }

        return Dictionary(uniqueKeysWithValues: components.map { ($0.nodeId, $0) })
    }

    private func loadComponents(fileId: String) async throws -> [Component] {
        // Check pre-fetched components first (batch optimization)
        if let preFetched = BatchContextStorage.context?.components,
           let components = preFetched.components(for: fileId)
        {
            return components
        }

        // Fall back to API request (standalone mode)
        let endpoint = ComponentsEndpoint(fileId: fileId)
        return try await client.request(endpoint)
    }

    private func loadImages(
        fileId: String,
        imagesDict: [NodeId: Component],
        params: FormatParams,
        onBatchProgress: @escaping BatchProgressCallback
    ) async throws -> [NodeId: ImagePath] {
        let batchSize = 100
        let maxConcurrentBatches = 3

        let nodeIds: [NodeId] = imagesDict.keys.map { $0 }
        let batches = nodeIds.chunked(into: batchSize)
        let totalBatches = batches.count

        let format = params.format
        let scale = params.scale

        // Thread-safe counter for completed batches
        let completedCounter = CompletedBatchCounter()

        let allResults = try await withThrowingTaskGroup(
            of: [(NodeId, ImagePath)].self
        ) { [self] group in
            var results: [[(NodeId, ImagePath)]] = []
            var activeTasks = 0

            for batch in batches {
                if activeTasks >= maxConcurrentBatches {
                    if let batchResult = try await group.next() {
                        results.append(batchResult)
                        activeTasks -= 1
                        let completed = completedCounter.increment()
                        onBatchProgress(completed, totalBatches)
                    }
                }

                group.addTask { [batch, fileId, format, scale, imagesDict] in
                    try await self.loadImageBatch(
                        fileId: fileId,
                        nodeIds: batch,
                        format: format,
                        scale: scale,
                        imagesDict: imagesDict
                    )
                }
                activeTasks += 1
            }

            for try await batchResult in group {
                results.append(batchResult)
                let completed = completedCounter.increment()
                onBatchProgress(completed, totalBatches)
            }

            return results.flatMap { $0 }
        }

        return Dictionary(uniqueKeysWithValues: allResults)
    }

    private func loadImageBatch(
        fileId: String,
        nodeIds: [NodeId],
        format: String,
        scale: Double?,
        imagesDict: [NodeId: Component]
    ) async throws -> [(NodeId, ImagePath)] {
        let params: FormatParams = switch format {
        case "svg": SVGParams()
        case "pdf": PDFParams()
        case "png" where scale != nil: PNGParams(scale: scale!)
        default: FormatParams(scale: scale, format: format)
        }

        let endpoint = ImageEndpoint(fileId: fileId, nodeIds: nodeIds, params: params)
        let dict = try await client.request(endpoint)

        return dict.compactMap { nodeId, imagePath in
            if let imagePath {
                return (nodeId, imagePath)
            } else {
                let componentName = imagesDict[nodeId]?.name ?? ""
                logger.error("Unable to get image for component '\(componentName)'. Skipping...")
                return nil
            }
        }
    }
}
