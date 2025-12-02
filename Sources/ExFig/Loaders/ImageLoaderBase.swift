import ExFigCore
import FigmaAPI
import Foundation
import Logging

/// Base class for loading images from Figma.
/// Provides shared functionality for IconsLoader and ImagesLoader.
class ImageLoaderBase: @unchecked Sendable {
    let client: Client
    let params: Params
    let platform: Platform
    let logger: Logger

    init(client: Client, params: Params, platform: Platform, logger: Logger) {
        self.client = client
        self.params = params
        self.platform = platform
        self.logger = logger
    }

    // MARK: - Component Loading

    /// Fetches image components from a Figma file filtered by frame name and platform.
    func fetchImageComponents(
        fileId: String,
        frameName: String,
        filter: String? = nil
    ) async throws -> [NodeId: Component] {
        var components = try await loadComponents(fileId: fileId)
            .filter {
                $0.containingFrame.name == frameName && $0.useForPlatform(platform)
            }

        if let filter {
            let assetsFilter = AssetsFilter(filter: filter)
            components = components.filter { component -> Bool in
                assetsFilter.match(name: component.name)
            }
        }

        return Dictionary(uniqueKeysWithValues: components.map { ($0.nodeId, $0) })
    }

    /// Loads vector images (SVG/PDF) from Figma.
    func loadVectorImages(
        fileId: String,
        frameName: String,
        params: FormatParams,
        filter: String? = nil
    ) async throws -> [ImagePack] {
        var imagesDict = try await fetchImageComponents(fileId: fileId, frameName: frameName, filter: filter)

        guard !imagesDict.isEmpty else {
            throw ExFigError.componentsNotFound
        }

        // Component name must not be empty
        imagesDict = imagesDict.filter { (_: NodeId, component: Component) in
            if component.name.trimmingCharacters(in: .whitespaces).isEmpty {
                logger.warning("""
                Found a component with empty name.
                Page name: \(component.containingFrame.pageName)
                Frame: \(component.containingFrame.name ?? "nil")
                Description: \(component.description ?? "nil")
                The component wont be exported. Fix component name in the Figma file and try again.
                """)
                return false
            }
            return true
        }

        logger.info("Fetching vector images...")
        let imageIdToImagePath = try await loadImages(fileId: fileId, imagesDict: imagesDict, params: params)

        // Remove components for which image file could not be fetched
        let badNodeIds = Set(imagesDict.keys).symmetricDifference(Set(imageIdToImagePath.keys))
        for nodeId in badNodeIds {
            imagesDict.removeValue(forKey: nodeId)
        }

        // Group images by name
        let groups = Dictionary(grouping: imagesDict) { $1.name.parseNameAndIdiom(platform: platform).name }

        // Create image packs for groups
        let imagePacks = groups.compactMap { packName, components -> ImagePack? in
            let packImages = components.compactMap { nodeId, component -> Image? in
                guard let urlString = imageIdToImagePath[nodeId], let url = URL(string: urlString) else {
                    return nil
                }
                let (name, idiom) = component.name.parseNameAndIdiom(platform: platform)
                let isRTL = component.useRTL()
                return Image(name: name, scale: .all, idiom: idiom, url: url, format: params.format, isRTL: isRTL)
            }
            return ImagePack(name: packName, images: packImages, platform: platform)
        }
        return imagePacks
    }

    /// Loads PNG images from Figma at multiple scales.
    func loadPNGImages(
        fileId: String,
        frameName: String,
        filter: String? = nil,
        scales: [Double]
    ) async throws -> [ImagePack] {
        let imagesDict = try await fetchImageComponents(fileId: fileId, frameName: frameName, filter: filter)

        guard !imagesDict.isEmpty else {
            throw ExFigError.componentsNotFound
        }

        // Parallel fetch for all scales (3x speedup for iOS with 3 scales)
        logger.info("Fetching PNG images for scales \(scales) in parallel...")
        let images = try await loadImagesForAllScales(
            fileId: fileId,
            imagesDict: imagesDict,
            scales: scales
        )

        // Group images by name
        let groups = Dictionary(grouping: imagesDict) { $1.name.parseNameAndIdiom(platform: platform).name }

        // Create image packs for groups
        let imagePacks = groups.compactMap { packName, components -> ImagePack? in
            let packImages = components.flatMap { nodeId, component -> [Image] in
                let (name, idiom) = component.name.parseNameAndIdiom(platform: platform)
                return scales.compactMap { scale -> Image? in
                    guard let urlString = images[scale]?[nodeId], let url = URL(string: urlString) else {
                        return nil
                    }
                    return Image(name: name, scale: .individual(scale), idiom: idiom, url: url, format: "png")
                }
            }
            return ImagePack(name: packName, images: packImages, platform: platform)
        }
        return imagePacks
    }

    // MARK: - Scale Helpers

    /// Returns valid scales for the given platform, optionally filtered by custom scales.
    func getScales(customScales: [Double]?) -> [Double] {
        let validScales: [Double] = platform == .android ? [1, 2, 3, 1.5, 4.0] : [1, 2, 3]
        let filtered = customScales?.filter { validScales.contains($0) } ?? []
        return filtered.isEmpty ? validScales : filtered
    }

    // MARK: - Dark Mode Helpers

    /// Splits image packs into light and dark based on suffix.
    func splitByDarkMode(
        _ packs: [ImagePack],
        darkSuffix: String
    ) -> (light: [ImagePack], dark: [ImagePack]) {
        let lightPacks = packs.filter { !$0.name.hasSuffix(darkSuffix) }
        let darkPacks = packs
            .filter { $0.name.hasSuffix(darkSuffix) }
            .map { pack -> ImagePack in
                var newPack = pack
                newPack.name = String(pack.name.dropLast(darkSuffix.count))
                return newPack
            }
        return (lightPacks, darkPacks)
    }

    // MARK: - Private Figma API Methods

    private func loadComponents(fileId: String) async throws -> [Component] {
        let endpoint = ComponentsEndpoint(fileId: fileId)
        return try await client.request(endpoint)
    }

    /// Loads images for all scales in parallel.
    private func loadImagesForAllScales(
        fileId: String,
        imagesDict: [NodeId: Component],
        scales: [Double]
    ) async throws -> [Double: [NodeId: ImagePath]] {
        try await withThrowingTaskGroup(
            of: (Double, [NodeId: ImagePath]).self
        ) { [self] group in
            for scale in scales {
                group.addTask { [fileId, imagesDict] in
                    let result = try await self.loadImages(
                        fileId: fileId,
                        imagesDict: imagesDict,
                        params: PNGParams(scale: scale)
                    )
                    return (scale, result)
                }
            }
            var results: [Double: [NodeId: ImagePath]] = [:]
            for try await (scale, dict) in group {
                results[scale] = dict
            }
            return results
        }
    }

    private func loadImages(
        fileId: String,
        imagesDict: [NodeId: Component],
        params: FormatParams
    ) async throws -> [NodeId: ImagePath] {
        let batchSize = 100
        // Conservative concurrency limit to respect Figma API rate limits
        // (10-20 requests/min depending on plan)
        let maxConcurrentBatches = 3

        let nodeIds: [NodeId] = imagesDict.keys.map { $0 }
        let batches = nodeIds.chunked(into: batchSize)

        // Capture format info for thread-safe closure (FormatParams is a class)
        let format = params.format
        let scale = params.scale

        // Load batches in parallel with limited concurrency
        let allResults = try await withThrowingTaskGroup(
            of: [(NodeId, ImagePath)].self
        ) { [self] group in
            var results: [[(NodeId, ImagePath)]] = []
            var activeTasks = 0

            for batch in batches {
                // If we've reached max concurrency, wait for one to complete
                if activeTasks >= maxConcurrentBatches {
                    if let batchResult = try await group.next() {
                        results.append(batchResult)
                        activeTasks -= 1
                    }
                }

                // Start new batch task
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

            // Collect remaining results
            for try await batchResult in group {
                results.append(batchResult)
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
        // Recreate FormatParams inside task to avoid Sendable issues
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
                let errorMsg = "Unable to get image for node with id = \(nodeId). " +
                    "Please check that component \(componentName) in the Figma file is not empty. Skipping..."
                logger.error("\(errorMsg)")
                return nil
            }
        }
    }
}

// MARK: - String Utils

extension String {
    /// Cached regex for parsing idiom suffix (e.g., "icon~ipad" -> name: "icon", idiom: "ipad")
    private static let idiomRegex: NSRegularExpression? = try? NSRegularExpression(pattern: "(.*)~(.*)$")

    func parseNameAndIdiom(platform: Platform) -> (name: String, idiom: String) {
        switch platform {
        case .android:
            return (self, "")
        case .ios:
            guard let regex = Self.idiomRegex,
                  let match = regex.firstMatch(in: self, range: NSRange(startIndex..., in: self)),
                  let name = Range(match.range(at: 1), in: self),
                  let idiom = Range(match.range(at: 2), in: self)
            else {
                return (self, "")
            }
            return (String(self[name]), String(self[idiom]))
        }
    }
}

// MARK: - Component Extensions

public extension Component {
    /// Checks if component should be used for the specified platform based on its description.
    func useForPlatform(_ platform: Platform) -> Bool {
        guard let description, !description.isEmpty else {
            return true
        }

        let keywords = ["ios", "android", "none"]

        let hasNotKeywords = keywords.allSatisfy { !description.contains($0) }
        if hasNotKeywords {
            return true
        }

        if (description.contains("ios") && platform == .ios)
            || (description.contains("android") && platform == .android)
        {
            return true
        }

        return false
    }

    /// Checks if component should use RTL layout based on its description.
    func useRTL() -> Bool {
        guard let description, !description.isEmpty else { return false }
        return description.localizedCaseInsensitiveContains("rtl")
    }
}
