import ExFigCore
import Foundation

public final class WebImagesExporter: WebExporter {
    private let output: WebOutput
    private let generateReactComponents: Bool

    public init(output: WebOutput, generateReactComponents: Bool) {
        self.output = output
        self.generateReactComponents = generateReactComponents
        super.init(templatesPath: output.templatesPath)
    }

    public struct ExportResult {
        public let componentFiles: [FileContents]
        public let assetFiles: [FileContents]
        public let barrelFile: FileContents?
    }

    /// Exports images as SVG/PNG assets + React TSX components.
    ///
    /// - Parameters:
    ///   - images: Image asset pairs to export (may be filtered subset for granular cache).
    ///   - allImageNames: Optional complete list of all image names for barrel file generation.
    ///                    When provided, barrel file includes all images even if only a subset is exported.
    /// - Returns: ExportResult containing component files, asset files, and barrel file.
    public func export(
        images: [AssetPair<ImagePack>],
        allImageNames: [String]? = nil
    ) throws -> ExportResult {
        var componentFiles: [FileContents] = []
        var assetFiles: [FileContents] = []

        // Generate asset files
        assetFiles = makeImagesAssetFiles(images: images)

        // Generate React components if requested
        if generateReactComponents {
            componentFiles = try makeReactComponents(images: images)
        }

        // Generate barrel file
        let barrelFile = try makeBarrelFile(images: images, allImageNames: allImageNames)

        return ExportResult(
            componentFiles: componentFiles,
            assetFiles: assetFiles,
            barrelFile: barrelFile
        )
    }

    // MARK: - Asset Files

    private func makeImagesAssetFiles(images: [AssetPair<ImagePack>]) -> [FileContents] {
        guard let assetsDirectory = output.imagesAssetsDirectory else {
            return []
        }

        var files: [FileContents] = []

        for imagePair in images {
            // Light image
            if let image = imagePair.light.images.first {
                let snakeName = imagePair.light.name.snakeCased()
                let ext = image.format.isEmpty ? "svg" : image.format
                let fileName = "\(snakeName).\(ext)"
                if let fileURL = URL(string: fileName) {
                    let file = FileContents(
                        destination: Destination(directory: assetsDirectory, file: fileURL),
                        sourceURL: image.url
                    )
                    files.append(file)
                }
            }

            // Dark image
            if let dark = imagePair.dark, let image = dark.images.first {
                let snakeName = dark.name.snakeCased()
                let ext = image.format.isEmpty ? "svg" : image.format
                let fileName = "\(snakeName)_dark.\(ext)"
                if let fileURL = URL(string: fileName) {
                    let file = FileContents(
                        destination: Destination(directory: assetsDirectory, file: fileURL),
                        sourceURL: image.url,
                        dark: true
                    )
                    files.append(file)
                }
            }
        }

        return files
    }

    // MARK: - React Components

    private func makeReactComponents(images: [AssetPair<ImagePack>]) throws -> [FileContents] {
        var files: [FileContents] = []

        for imagePair in images {
            let componentName = imagePair.light.name.camelCased()
            let fileName = componentName

            let image = imagePair.light.images.first
            let ext = image?.format.isEmpty == false ? image!.format : "svg"
            let snakeName = imagePair.light.name.snakeCased()

            let context: [String: Any] = [
                "componentName": componentName,
                "name": imagePair.light.name,
                "assetPath": "'\(snakeName).\(ext)'",
            ]

            let fullContext = try contextWithHeader(context)
            let content = try renderTemplate(name: "Image.tsx.jinja", context: fullContext)

            guard let fileURL = URL(string: "\(fileName).tsx") else {
                continue
            }

            let file = try makeFileContents(
                for: content,
                directory: output.outputDirectory,
                file: fileURL
            )
            files.append(file)
        }

        return files
    }

    // MARK: - Barrel File

    private func makeBarrelFile(
        images: [AssetPair<ImagePack>],
        allImageNames: [String]? = nil
    ) throws -> FileContents {
        // Use allImageNames if provided, otherwise derive from images
        let imagesList: [[String: String]] = if let allNames = allImageNames {
            allNames.sorted().map { name in
                let componentName = name.camelCased()
                return [
                    "componentName": componentName,
                    "fileName": componentName,
                ]
            }
        } else {
            images.sorted { $0.light.name < $1.light.name }.map { imagePair in
                let componentName = imagePair.light.name.camelCased()
                return [
                    "componentName": componentName,
                    "fileName": componentName,
                ]
            }
        }

        let context: [String: Any] = [
            "images": imagesList,
        ]

        let fullContext = try contextWithHeader(context)
        let content = try renderTemplate(name: "ImageIndex.ts.jinja", context: fullContext)

        guard let fileURL = URL(string: "index.ts") else {
            throw WebExportError.invalidFileName(name: "index.ts")
        }

        return try makeFileContents(
            for: content,
            directory: output.outputDirectory,
            file: fileURL
        )
    }
}
