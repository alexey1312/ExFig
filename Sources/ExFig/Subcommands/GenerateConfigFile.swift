import ArgumentParser
import ExFigCore
import ExFigKit
import Foundation

extension Platform: ExpressibleByArgument {}

extension ExFigCommand {
    struct GenerateConfigFile: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "init",
            abstract: "Generates config file",
            discussion: """
            Generates exfig.yaml config file in the current directory.

            Examples:
              exfig init -p ios       Generate iOS config
              exfig init -p android   Generate Android config
            """
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @Option(name: .shortAndLong, help: "Platform: ios or android.")
        var platform: Platform

        func run() async throws {
            ExFigCommand.initializeTerminalUI(verbose: globalOptions.verbose, quiet: globalOptions.quiet)
            let ui = ExFigCommand.terminalUI!

            let fileContents: String = switch platform {
            case .android:
                androidConfigFileContents
            case .ios:
                iosConfigFileContents
            case .flutter:
                flutterConfigFileContents
            case .web:
                webConfigFileContents
            }

            let destination = FileManager.default.currentDirectoryPath + "/" + ExFigOptions.defaultConfigFilename

            // Remove existing file if present
            if FileManager.default.fileExists(atPath: destination) {
                do {
                    try FileManager.default.removeItem(atPath: destination)
                    ui.debug("Removed existing config file at: \(destination)")
                } catch {
                    let message = "Failed to remove existing config file: \(error.localizedDescription)"
                    throw ExFigError.custom(errorString: message)
                }
            }

            // Write new config file
            guard let fileData = fileContents.data(using: .utf8) else {
                throw ExFigError.custom(errorString: "Failed to encode config file contents")
            }

            let success = FileManager.default.createFile(atPath: destination, contents: fileData, attributes: nil)
            if success {
                ui.success("Config file generated: \(destination)")
                ui.info("Edit the file with your Figma file IDs and project paths, then run:")
                ui.info("  exfig colors    Export colors")
                ui.info("  exfig icons     Export icons")
                ui.info("  exfig images    Export images")
                ui.info("  exfig typography    Export typography")
            } else {
                throw ExFigError.custom(errorString: "Unable to create config file at: \(destination)")
            }
        }
    }
}
