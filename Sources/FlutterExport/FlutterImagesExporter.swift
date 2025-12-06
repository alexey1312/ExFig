import ExFigCore
import Foundation
import Stencil

public final class FlutterImagesExporter: FlutterExporter {
    private let output: FlutterOutput
    private let outputFileName: String
    private let scales: [Double]
    private let format: String

    public init(output: FlutterOutput, outputFileName: String?, scales: [Double]?, format: String?) {
        self.output = output
        self.outputFileName = outputFileName ?? "images.dart"
        self.scales = scales ?? [1, 2, 3]
        self.format = format ?? "png"
        super.init(templatesPath: output.templatesPath)
    }

    /// Exports images as multi-scale assets + Dart constants file
    /// Returns FileContents for both the Dart file and the image asset files
    public func export(images: [AssetPair<ImagePack>]) throws -> (dartFile: FileContents, assetFiles: [FileContents]) {
        let dartFile = try makeImagesDartFileContents(images: images)
        let assetFiles = makeImagesAssetFiles(images: images)
        return (dartFile, assetFiles)
    }

    private func makeImagesDartFileContents(images: [AssetPair<ImagePack>]) throws -> FileContents {
        let contents = try makeImagesDartContents(images)

        guard let fileURL = URL(string: outputFileName) else {
            fatalError("Invalid file URL: \(outputFileName)")
        }

        return try makeFileContents(for: contents, directory: output.outputDirectory, file: fileURL)
    }

    private func makeImagesDartContents(_ images: [AssetPair<ImagePack>]) throws -> String {
        let className = output.imagesClassName ?? "AppImages"

        guard let assetsDirectory = output.imagesAssetsDirectory else {
            fatalError("imagesAssetsDirectory is required for image export")
        }

        let relativePath = assetsDirectory.path

        let imagesList: [[String: Any]] = images.map { imagePair in
            let name = imagePair.light.name.lowerCamelCased()
            let snakeName = imagePair.light.name.snakeCased()
            let hasDark = imagePair.dark != nil

            var result: [String: Any] = [
                "name": name,
                "lightPath": "\(relativePath)/\(snakeName).\(format)",
                "hasDark": hasDark,
            ]

            if hasDark {
                result["darkPath"] = "\(relativePath)/\(snakeName)_dark.\(format)"
            }

            return result
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
        let snakeName = imagePack.name.snakeCased()
        let suffix = isDark ? "_dark" : ""
        let fileName = "\(snakeName)\(suffix).\(format)"

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
