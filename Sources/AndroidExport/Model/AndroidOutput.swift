import Foundation

public struct AndroidOutput {
    let xmlOutputDirectory: URL
    let xmlResourcePackage: String?
    let composeOutputDirectory: URL?
    let colorKotlinURL: URL?
    let packageName: String?
    let templatesPath: URL?
    /// When true, skip XML generation entirely. Useful for Compose-only projects with custom templates.
    let xmlDisabled: Bool

    public init(
        xmlOutputDirectory: URL,
        xmlResourcePackage: String?,
        srcDirectory: URL?,
        packageName: String?,
        colorKotlinURL: URL?,
        templatesPath: URL?,
        xmlDisabled: Bool = false
    ) {
        self.xmlOutputDirectory = xmlOutputDirectory
        self.xmlResourcePackage = xmlResourcePackage
        self.colorKotlinURL = colorKotlinURL
        self.packageName = packageName
        self.templatesPath = templatesPath
        self.xmlDisabled = xmlDisabled
        if let srcDirectory, let packageName {
            composeOutputDirectory = srcDirectory.appendingPathComponent(packageName.replacingOccurrences(
                of: ".",
                with: "/"
            ))
        } else {
            composeOutputDirectory = nil
        }
    }
}
