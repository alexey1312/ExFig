import ArgumentParser
import Foundation
import Logging
import Rainbow
import SVGKit

enum ExFigError: LocalizedError {
    case invalidFileName(String)
    case stylesNotFound
    case componentsNotFound
    case accessTokenNotFound
    case colorsAssetsFolderNotSpecified
    case configurationError(String)
    case custom(errorString: String)

    var errorDescription: String? {
        switch self {
        case let .invalidFileName(name):
            "File name is invalid: \(name)"
        case .stylesNotFound:
            "Color/Text styles not found in the Figma file. Have you published Styles to the Library?"
        case .componentsNotFound:
            "Components not found in the Figma file. Have you published Components to the Library?"
        case .accessTokenNotFound:
            "Environment variable FIGMA_PERSONAL_TOKEN not specified."
        case .colorsAssetsFolderNotSpecified:
            "Option ios.colors.assetsFolder not specified in configuration file."
        case let .configurationError(message):
            "Configuration error: \(message)"
        case let .custom(errorString):
            errorString
        }
    }
}

@main
struct ExFigCommand: AsyncParsableCommand {
    static let version = "1.0.1"

    static let svgFileConverter = NativeVectorDrawableConverter()
    static let fileWriter = FileWriter()
    static let fileDownloader = FileDownloader()
    static let logger = Logger(label: "com.alexey1312.exfig")

    /// Shared terminal UI instance (initialized by subcommands)
    nonisolated(unsafe) static var terminalUI: TerminalUI!

    static let configuration = CommandConfiguration(
        commandName: "exfig",
        abstract: "Exports resources from Figma",
        discussion: """
        Exports resources (colors, icons, images) from Figma to Xcode / Android Studio project.

        Requires FIGMA_PERSONAL_TOKEN environment variable to be set.
        """,
        version: version,
        subcommands: [
            ExportColors.self,
            ExportIcons.self,
            ExportImages.self,
            ExportTypography.self,
            GenerateConfigFile.self,
        ],
        defaultSubcommand: ExportColors.self
    )
}

// MARK: - TerminalUI Initialization

extension ExFigCommand {
    /// Initialize TerminalUI with global options
    static func initializeTerminalUI(verbose: Bool, quiet: Bool) {
        terminalUI = TerminalUI.create(verbose: verbose, quiet: quiet)
        terminalUI.installSignalHandlers()
    }
}
