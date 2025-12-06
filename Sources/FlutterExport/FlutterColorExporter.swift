import ExFigCore
import Foundation
import Stencil

public final class FlutterColorExporter: FlutterExporter {
    private let output: FlutterOutput
    private let outputFileName: String

    public init(output: FlutterOutput, outputFileName: String?) {
        self.output = output
        self.outputFileName = outputFileName ?? "colors.dart"
        super.init(templatesPath: output.templatesPath)
    }

    public func export(colorPairs: [AssetPair<Color>]) throws -> [FileContents] {
        let lightFile = try makeColorsFileContents(colorPairs: colorPairs)
        return [lightFile]
    }

    private func makeColorsFileContents(colorPairs: [AssetPair<Color>]) throws -> FileContents {
        let contents = try makeColorsContents(colorPairs)

        guard let fileURL = URL(string: outputFileName) else {
            fatalError("Invalid file URL: \(outputFileName)")
        }

        return try makeFileContents(for: contents, directory: output.outputDirectory, file: fileURL)
    }

    private func makeColorsContents(_ colorPairs: [AssetPair<Color>]) throws -> String {
        let hasDarkColors = colorPairs.contains { $0.dark != nil }
        let className = output.colorsClassName ?? "AppColors"

        let lightColors: [[String: String]] = colorPairs.map { colorPair in
            [
                "name": colorPair.light.name.lowerCamelCased(),
                "hex": colorPair.light.flutterHex,
            ]
        }

        var darkColors: [[String: String]] = []
        if hasDarkColors {
            darkColors = colorPairs.compactMap { colorPair -> [String: String]? in
                guard let dark = colorPair.dark else { return nil }
                return [
                    "name": dark.name.lowerCamelCased(),
                    "hex": dark.flutterHex,
                ]
            }
        }

        let context: [String: Any] = [
            "className": className,
            "colors": lightColors,
            "hasDarkColors": hasDarkColors,
            "darkColors": darkColors,
        ]

        let env = makeEnvironment()
        return try env.renderTemplate(name: "colors.dart.stencil", context: context)
    }
}

private extension Color {
    private func doubleToHex(_ double: Double) -> String {
        String(format: "%02X", arguments: [Int((double * 255).rounded())])
    }

    /// Flutter color format: 0xAARRGGBB
    var flutterHex: String {
        let aa = doubleToHex(alpha)
        let rr = doubleToHex(red)
        let gg = doubleToHex(green)
        let bb = doubleToHex(blue)
        return "0x\(aa)\(rr)\(gg)\(bb)"
    }
}
