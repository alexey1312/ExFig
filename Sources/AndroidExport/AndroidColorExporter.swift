import ExFigCore
import Foundation
import PathKit
import Stencil

public final class AndroidColorExporter: AndroidExporter {
    private let output: AndroidOutput
    private let xmlOutputFileName: String

    public init(output: AndroidOutput, xmlOutputFileName: String?) {
        self.output = output
        self.xmlOutputFileName = xmlOutputFileName ?? "colors.xml"
        super.init(templatesPath: output.templatesPath)
    }

    public func export(colorPairs: [AssetPair<Color>]) throws -> [FileContents] {
        // values/colors.xml
        let lightFile = try makeColorsFileContents(colorPairs: colorPairs, dark: false)
        var result = [lightFile]

        // values-night/colors.xml
        if colorPairs.contains(where: { $0.dark != nil }) {
            let darkFile = try makeColorsFileContents(colorPairs: colorPairs, dark: true)
            result.append(darkFile)
        }

        // Colors.kt (custom path or computed from package)
        if let colorKotlinURL = output.colorKotlinURL,
           let packageName = output.packageName
        {
            // Custom colorKotlin path: use it directly
            let composeFile = try makeComposeColorsFileContents(
                colorPairs: colorPairs,
                package: packageName,
                xmlResourcePackage: output.xmlResourcePackage,
                colorKotlinURL: colorKotlinURL
            )
            result.append(composeFile)
        } else if let packageName = output.packageName,
                  let outputDirectory = output.composeOutputDirectory,
                  let xmlResourcePackage = output.xmlResourcePackage
        {
            // Legacy behavior: compute path from mainSrc + package
            let composeFile = try makeComposeColorsFileContents(
                colorPairs: colorPairs,
                package: packageName,
                xmlResourcePackage: xmlResourcePackage,
                outputDirectory: outputDirectory
            )
            result.append(composeFile)
        }

        return result
    }

    private func makeColorsFileContents(colorPairs: [AssetPair<Color>], dark: Bool) throws -> FileContents {
        let contents = try makeColorsContents(colorPairs, dark: dark)

        let directoryURL = output.xmlOutputDirectory.appendingPathComponent(dark ? "values-night" : "values")
        guard let fileURL = URL(string: xmlOutputFileName) else {
            fatalError("Invalid file URL: \(xmlOutputFileName)")
        }

        return try makeFileContents(for: contents, directory: directoryURL, file: fileURL)
    }

    private func makeColorsContents(_ colorPairs: [AssetPair<Color>], dark: Bool) throws -> String {
        let colors: [[String: String]] = colorPairs.map { colorPair in
            [
                "name": colorPair.light.name,
                "hex": (dark ? colorPair.dark?.hex : nil) ?? colorPair.light.hex,
            ]
        }
        let context: [String: Any] = [
            "colors": colors,
        ]

        let env = makeEnvironment()
        return try env.renderTemplate(name: "colors.xml.stencil", context: context)
    }

    private func makeComposeColorsFileContents(
        colorPairs: [AssetPair<Color>],
        package: String,
        xmlResourcePackage: String,
        outputDirectory: URL
    ) throws -> FileContents {
        try makeComposeColorsFileContentsInternal(
            colorPairs: colorPairs,
            package: package,
            xmlResourcePackage: xmlResourcePackage,
            outputDirectory: outputDirectory,
            fileName: "Colors.kt"
        )
    }

    private func makeComposeColorsFileContents(
        colorPairs: [AssetPair<Color>],
        package: String,
        xmlResourcePackage: String?,
        colorKotlinURL: URL
    ) throws -> FileContents {
        let outputDirectory = colorKotlinURL.deletingLastPathComponent()
        let fileName = colorKotlinURL.lastPathComponent
        return try makeComposeColorsFileContentsInternal(
            colorPairs: colorPairs,
            package: package,
            xmlResourcePackage: xmlResourcePackage,
            outputDirectory: outputDirectory,
            fileName: fileName
        )
    }

    private func makeComposeColorsFileContentsInternal(
        colorPairs: [AssetPair<Color>],
        package: String,
        xmlResourcePackage: String?,
        outputDirectory: URL,
        fileName: String
    ) throws -> FileContents {
        let colors: [[String: String]] = colorPairs.map { colorPair in
            let lightKotlinHex = colorPair.light.kotlinHex
            let darkKotlinHex = colorPair.dark?.kotlinHex ?? lightKotlinHex
            return [
                "functionName": colorPair.light.name.lowerCamelCased(),
                "name": colorPair.light.name,
                "lightHex": lightKotlinHex,
                "darkHex": darkKotlinHex,
                "lightHexRaw": String(lightKotlinHex.dropFirst(2)),
                "darkHexRaw": String(darkKotlinHex.dropFirst(2)),
            ]
        }

        var context: [String: Any] = [
            "package": package,
            "colors": colors,
        ]
        if let xmlResourcePackage {
            context["xmlResourcePackage"] = xmlResourcePackage
        }

        let env = makeEnvironment()
        let string = try env.renderTemplate(name: "Colors.kt.stencil", context: context)

        guard let fileURL = URL(string: fileName) else {
            fatalError("Invalid file URL: \(fileName)")
        }
        return try makeFileContents(for: string, directory: outputDirectory, file: fileURL)
    }
}

extension Color {
    func doubleToHex(_ double: Double) -> String {
        String(format: "%02X", arguments: [Int((double * 255).rounded())])
    }

    var hex: String {
        let rr = doubleToHex(red)
        let gg = doubleToHex(green)
        let bb = doubleToHex(blue)
        var result = "#\(rr)\(gg)\(bb)"
        if alpha != 1.0 {
            let aa = doubleToHex(alpha)
            result = "#\(aa)\(rr)\(gg)\(bb)"
        }
        return result
    }

    /// Hex color value in Kotlin format (0xAARRGGBB).
    var kotlinHex: String {
        let rr = doubleToHex(red)
        let gg = doubleToHex(green)
        let bb = doubleToHex(blue)
        if alpha != 1.0 {
            let aa = doubleToHex(alpha)
            return "0x\(aa)\(rr)\(gg)\(bb)"
        }
        return "0xFF\(rr)\(gg)\(bb)"
    }
}
