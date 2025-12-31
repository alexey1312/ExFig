import ArgumentParser
import ExFigKit
import Foundation
import Logging
import Rainbow
import SVGKit

@main
struct ExFigCommand: AsyncParsableCommand {
    static let version = "v1.2.16"

    static let svgFileConverter = NativeVectorDrawableConverter()
    static let fileWriter = FileWriter()
    static let logger = Logger(label: "com.alexey1312.exfig")

    /// Shared terminal UI instance (initialized by subcommands)
    nonisolated(unsafe) static var terminalUI: TerminalUI!

    static let configuration = CommandConfiguration(
        commandName: "exfig",
        abstract: "Exports resources from Figma",
        discussion: """
        Version: \(version)

        Exports resources (colors, icons, images) from Figma to Xcode / Android Studio / Flutter project.

        Requires FIGMA_PERSONAL_TOKEN environment variable to be set.
        """,
        version: version,
        subcommands: [
            ExportColors.self,
            ExportIcons.self,
            ExportImages.self,
            ExportTypography.self,
            GenerateConfigFile.self,
            FetchImages.self,
            Download.self,
            Batch.self,
            MigrateConfig.self,
        ],
        defaultSubcommand: ExportColors.self
    )
}

// MARK: - TerminalUI Initialization

extension ExFigCommand {
    /// Initialize TerminalUI with global options
    static func initializeTerminalUI(verbose: Bool, quiet: Bool) {
        let outputMode = TTYDetector.effectiveMode(verbose: verbose, quiet: quiet)

        // Bootstrap logging system to use our custom handler
        // This ensures all Logger output goes through TerminalOutputManager
        ExFigLogging.bootstrap(outputMode: outputMode)

        terminalUI = TerminalUI(outputMode: outputMode)
        terminalUI.installSignalHandlers()
    }
}
