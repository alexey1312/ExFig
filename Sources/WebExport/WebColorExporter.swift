import ExFigCore
import Foundation
import Stencil

public final class WebColorExporter: WebExporter {
    private let output: WebOutput
    private let cssFileName: String
    private let tsFileName: String
    private let jsonFileName: String?

    public init(
        output: WebOutput,
        cssFileName: String?,
        tsFileName: String?,
        jsonFileName: String?
    ) {
        self.output = output
        self.cssFileName = cssFileName ?? "theme.css"
        self.tsFileName = tsFileName ?? "variables.ts"
        self.jsonFileName = jsonFileName
        super.init(templatesPath: output.templatesPath)
    }

    public func export(colorPairs: [AssetPair<Color>]) throws -> [FileContents] {
        var files: [FileContents] = []

        // Generate CSS file
        let cssFile = try makeCSSFileContents(colorPairs: colorPairs)
        files.append(cssFile)

        // Generate TypeScript file
        let tsFile = try makeTSFileContents(colorPairs: colorPairs)
        files.append(tsFile)

        // Generate JSON file if requested
        if jsonFileName != nil {
            let jsonFile = try makeJSONFileContents(colorPairs: colorPairs)
            files.append(jsonFile)
        }

        return files
    }

    // MARK: - CSS Generation

    private func makeCSSFileContents(colorPairs: [AssetPair<Color>]) throws -> FileContents {
        let contents = try makeCSSContents(colorPairs)

        guard let fileURL = URL(string: cssFileName) else {
            throw WebExportError.invalidFileName(name: cssFileName)
        }

        return try makeFileContents(for: contents, directory: output.outputDirectory, file: fileURL)
    }

    private func makeCSSContents(_ colorPairs: [AssetPair<Color>]) throws -> String {
        let hasDarkColors = colorPairs.contains { $0.dark != nil }

        let lightColors: [[String: String]] = colorPairs.map { colorPair in
            [
                "cssName": colorPair.light.name.kebabCased(),
                "value": colorPair.light.cssValue,
            ]
        }

        var darkColors: [[String: String]] = []
        if hasDarkColors {
            darkColors = colorPairs.compactMap { colorPair -> [String: String]? in
                guard let dark = colorPair.dark else { return nil }
                return [
                    "cssName": dark.name.kebabCased(),
                    "value": dark.cssValue,
                ]
            }
        }

        let context: [String: Any] = [
            "lightColors": lightColors,
            "hasDarkColors": hasDarkColors,
            "darkColors": darkColors,
        ]

        let env = makeEnvironment()
        return try env.renderTemplate(name: "theme.css.stencil", context: context)
    }

    // MARK: - TypeScript Generation

    private func makeTSFileContents(colorPairs: [AssetPair<Color>]) throws -> FileContents {
        let contents = try makeTSContents(colorPairs)

        guard let fileURL = URL(string: tsFileName) else {
            throw WebExportError.invalidFileName(name: tsFileName)
        }

        return try makeFileContents(for: contents, directory: output.outputDirectory, file: fileURL)
    }

    private func makeTSContents(_ colorPairs: [AssetPair<Color>]) throws -> String {
        let colors: [[String: String]] = colorPairs.map { colorPair in
            [
                "camelName": colorPair.light.name.lowerCamelCased(),
                "cssName": colorPair.light.name.kebabCased(),
            ]
        }

        let context: [String: Any] = [
            "colors": colors,
        ]

        let env = makeEnvironment()
        return try env.renderTemplate(name: "variables.ts.stencil", context: context)
    }

    // MARK: - JSON Generation

    private func makeJSONFileContents(colorPairs: [AssetPair<Color>]) throws -> FileContents {
        let contents = try makeJSONContents(colorPairs)

        guard let fileName = jsonFileName, let fileURL = URL(string: fileName) else {
            throw WebExportError.invalidFileName(name: jsonFileName ?? "nil")
        }

        return try makeFileContents(for: contents, directory: output.outputDirectory, file: fileURL)
    }

    private func makeJSONContents(_ colorPairs: [AssetPair<Color>]) throws -> String {
        let hasDarkColors = colorPairs.contains { $0.dark != nil }

        let lightColors: [[String: String]] = colorPairs.map { colorPair in
            [
                "cssName": colorPair.light.name.kebabCased(),
                "value": colorPair.light.cssValue,
            ]
        }

        var darkColors: [[String: String]] = []
        if hasDarkColors {
            darkColors = colorPairs.compactMap { colorPair -> [String: String]? in
                guard let dark = colorPair.dark else { return nil }
                return [
                    "cssName": dark.name.kebabCased(),
                    "value": dark.cssValue,
                ]
            }
        }

        let context: [String: Any] = [
            "lightColors": lightColors,
            "hasDarkColors": hasDarkColors,
            "darkColors": darkColors,
        ]

        let env = makeEnvironment()
        return try env.renderTemplate(name: "theme.json.stencil", context: context)
    }
}

// MARK: - Color Extension

private extension Color {
    /// CSS color value - hex for opaque colors, rgba for transparent
    var cssValue: String {
        if alpha >= 1.0 {
            hexValue
        } else {
            rgbaValue
        }
    }

    /// Hex color value: #RRGGBB
    var hexValue: String {
        let rr = String(format: "%02X", Int((red * 255).rounded()))
        let gg = String(format: "%02X", Int((green * 255).rounded()))
        let bb = String(format: "%02X", Int((blue * 255).rounded()))
        return "#\(rr)\(gg)\(bb)"
    }

    /// RGBA color value: rgba(r, g, b, a)
    var rgbaValue: String {
        let r = Int((red * 255).rounded())
        let g = Int((green * 255).rounded())
        let b = Int((blue * 255).rounded())
        return "rgba(\(r), \(g), \(b), \(alpha))"
    }
}
