import ExFigCore
import Foundation
import Stencil

public final class FlutterImagesExporter: FlutterExporter {
    private let output: FlutterOutput
    private let outputFileName: String
    private let scales: [Double]
    private let format: String
    private let nameStyle: NameStyle

    public init(
        output: FlutterOutput,
        outputFileName: String?,
        scales: [Double]?,
        format: String?,
        nameStyle: NameStyle = .snakeCase
    ) {
        self.output = output
        self.outputFileName = outputFileName ?? "images.dart"
        self.scales = scales ?? [1, 2, 3]
        self.format = format ?? "png"
        self.nameStyle = nameStyle
        super.init(templatesPath: output.templatesPath)
    }

    /// Transforms a name according to the configured naming style.
    private func transformName(_ name: String) -> String {
        switch nameStyle {
        case .camelCase:
            name.lowerCamelCased()
        case .snakeCase:
            name.snakeCased()
        case .pascalCase:
            name.camelCased()
        case .kebabCase:
            name.kebabCased()
        case .screamingSnakeCase:
            name.screamingSnakeCased()
        }
    }

    /// Exports images as multi-scale assets + Dart constants file.
    ///
    /// - Parameters:
    ///   - images: Image asset pairs to export (may be filtered subset for granular cache).
    ///   - allImageNames: Optional complete list of all image names for Dart file generation.
    ///                    When provided, Dart file includes all images even if only a subset is exported.
    ///                    Note: When using allImageNames, dark mode variants are not included.
    ///   - assetsPath: Optional relative path for generated Dart code (e.g., "assets/images").
    ///                 When provided, overrides the path extracted from imagesAssetsDirectory URL.
    /// - Returns: FileContents for both the Dart file and the image asset files.
    public func export(
        images: [AssetPair<ImagePack>],
        allImageNames: [String]? = nil,
        assetsPath: String? = nil
    ) throws -> (dartFile: FileContents, assetFiles: [FileContents]) {
        let dartFile = try makeImagesDartFileContents(
            images: images,
            allImageNames: allImageNames,
            assetsPath: assetsPath
        )
        let assetFiles = makeImagesAssetFiles(images: images)
        return (dartFile, assetFiles)
    }

    private func makeImagesDartFileContents(
        images: [AssetPair<ImagePack>],
        allImageNames: [String]? = nil,
        assetsPath: String? = nil
    ) throws -> FileContents {
        let contents = try makeImagesDartContents(images, allImageNames: allImageNames, assetsPath: assetsPath)

        guard let fileURL = URL(string: outputFileName) else {
            fatalError("Invalid file URL: \(outputFileName)")
        }

        return try makeFileContents(for: contents, directory: output.outputDirectory, file: fileURL)
    }

    private func makeImagesDartContents(
        _ images: [AssetPair<ImagePack>],
        allImageNames: [String]? = nil,
        assetsPath: String? = nil
    ) throws -> String {
        let className = output.imagesClassName ?? "AppImages"

        guard let assetsDirectory = output.imagesAssetsDirectory else {
            fatalError("imagesAssetsDirectory is required for image export")
        }

        let relativePath = assetsPath ?? assetsDirectory.path

        // Use allImageNames if provided (for granular cache), otherwise derive from images
        let imagesList: [[String: Any]] = if let allNames = allImageNames {
            // When using allImageNames, dark mode is not tracked (simplified for granular cache)
            allNames.map { name in
                let camelName = name.lowerCamelCased()
                let styledName = transformName(name)
                return [
                    "name": camelName,
                    "lightPath": "\(relativePath)/\(styledName).\(format)",
                    "hasDark": false,
                ] as [String: Any]
            }
        } else {
            images.map { imagePair in
                let name = imagePair.light.name.lowerCamelCased()
                let styledName = transformName(imagePair.light.name)
                let hasDark = imagePair.dark != nil

                var result: [String: Any] = [
                    "name": name,
                    "lightPath": "\(relativePath)/\(styledName).\(format)",
                    "hasDark": hasDark,
                ]

                if hasDark {
                    result["darkPath"] = "\(relativePath)/\(styledName)\(nameStyle.darkSuffix).\(format)"
                }

                return result
            }
        }

        let context: [String: Any] = [
            "className": className,
            "images": imagesList,
        ]

        let env = makeEnvironment()
        return try env.renderTemplate(name: "images.dart.stencil", context: context)
    }

    private func makeImagesAssetFiles(images: [AssetPair<ImagePack>]) -> [FileContents] {
        guard let assetsDirectory = output.imagesAssetsDirectory else {
            return []
        }

        var files: [FileContents] = []

        for imagePair in images {
            // Light images at different scales
            files.append(contentsOf: makeScaledImageFiles(
                imagePack: imagePair.light,
                assetsDirectory: assetsDirectory,
                isDark: false
            ))

            // Dark images at different scales
            if let dark = imagePair.dark {
                files.append(contentsOf: makeScaledImageFiles(
                    imagePack: dark,
                    assetsDirectory: assetsDirectory,
                    isDark: true
                ))
            }
        }

        return files
    }

    private func makeScaledImageFiles(
        imagePack: ImagePack,
        assetsDirectory: URL,
        isDark: Bool
    ) -> [FileContents] {
        var files: [FileContents] = []

        for scale in scales {
            let scaleImages = imagePack.images.filter { matchesScale($0.scale, targetScale: scale) }

            for image in scaleImages {
                if let file = makeImageFile(
                    imagePack: imagePack,
                    image: image,
                    scale: scale,
                    assetsDirectory: assetsDirectory,
                    isDark: isDark
                ) {
                    files.append(file)
                }
            }
        }

        return files
    }

    private func matchesScale(_ imageScale: Scale, targetScale: Double) -> Bool {
        switch imageScale {
        case .all:
            targetScale == 1
        case let .individual(value):
            value == targetScale
        }
    }

    private func makeImageFile(
        imagePack: ImagePack,
        image: Image,
        scale: Double,
        assetsDirectory: URL,
        isDark: Bool
    ) -> FileContents? {
        let styledName = transformName(imagePack.name)
        let suffix = isDark ? nameStyle.darkSuffix : ""
        let fileName = "\(styledName)\(suffix).\(format)"

        // Flutter scale directories: 1x at root, 2x at 2.0x/, 3x at 3.0x/
        let scaleDirectory = scale == 1
            ? assetsDirectory
            : assetsDirectory.appendingPathComponent("\(scale)x")

        guard let fileURL = URL(string: fileName) else {
            return nil
        }

        return FileContents(
            destination: Destination(directory: scaleDirectory, file: fileURL),
            sourceURL: image.url,
            scale: scale,
            dark: isDark
        )
    }
}
