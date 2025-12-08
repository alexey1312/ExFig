import ExFigCore
import Foundation
import Stencil

public final class AndroidComposeIconExporter: AndroidExporter {
    private let output: AndroidOutput

    public init(output: AndroidOutput) {
        self.output = output
        super.init(templatesPath: output.templatesPath)
    }

    /// Exports icons to Compose Kotlin file.
    ///
    /// - Parameters:
    ///   - iconNames: Icon names derived from exported assets.
    ///   - allIconNames: Optional complete list of all icon names for Kotlin file generation.
    ///                   When provided, generated file includes all icons even if only a subset is exported.
    /// - Returns: File contents to write, or nil if output configuration is missing.
    public func exportIcons(iconNames: [String], allIconNames: [String]? = nil) throws -> FileContents? {
        guard
            let outputDirectory = output.composeOutputDirectory,
            let packageName = output.packageName,
            let package = output.xmlResourcePackage
        else {
            return nil
        }
        guard let fileURL = URL(string: "Icons.kt") else {
            fatalError("Invalid file URL: Icons.kt")
        }
        // Use allIconNames if provided, otherwise use iconNames
        let namesForTemplate = allIconNames ?? iconNames
        let contents = try makeComposeIconsContents(namesForTemplate, package: packageName, xmlResourcePackage: package)
        return try makeFileContents(for: contents, directory: outputDirectory, file: fileURL)
    }

    private func makeComposeIconsContents(
        _ iconNames: [String],
        package: String,
        xmlResourcePackage: String
    ) throws -> String {
        let icons: [[String: String]] = iconNames.map {
            ["name": $0, "functionName": $0.camelCased()]
        }
        let context: [String: Any] = [
            "package": package,
            "xmlResourcePackage": xmlResourcePackage,
            "icons": icons,
        ]
        let env = makeEnvironment()
        return try env.renderTemplate(name: "Icons.kt.stencil", context: context)
    }
}
