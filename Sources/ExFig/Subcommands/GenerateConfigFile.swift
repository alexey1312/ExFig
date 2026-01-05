import ArgumentParser
import ExFigCore
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
        var platform: Platform?

        func run() async throws {
            ExFigCommand.initializeTerminalUI(verbose: globalOptions.verbose, quiet: globalOptions.quiet)
            let ui = ExFigCommand.terminalUI!

            let selectedPlatform: Platform
            if let platform {
                selectedPlatform = platform
            } else {
                if !TTYDetector.isTTY {
                    throw ValidationError("Missing required argument: --platform <ios|android|flutter|web>")
                }
                selectedPlatform = try promptForPlatform(ui: ui)
            }

            let fileContents: String = switch selectedPlatform {
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

            // Check if file exists and ask for confirmation
            if FileManager.default.fileExists(atPath: destination) {
                let result = try handleExistingFile(at: destination, ui: ui)
                if !result { return }
            }

            // Write new config file
            try writeConfigFile(contents: fileContents, to: destination, ui: ui)
        }

        /// Handles existing file: prompts for confirmation and removes if approved.
        /// - Returns: `true` to proceed with overwrite, `false` if user cancelled
        private func handleExistingFile(at destination: String, ui: TerminalUI) throws -> Bool {
            if !TTYDetector.isTTY {
                ui.error("Config file already exists at: \(destination)")
                throw ExFigError
                    .custom(
                        errorString: "Config file already exists. Delete it manually or run in interactive mode."
                    )
            }

            ui.warning("Config file already exists at: \(destination)")
            TerminalOutputManager.shared.writeDirect("Overwrite? [y/N] ")
            ANSICodes.flushStdout()

            guard let input = readLine() else {
                TerminalOutputManager.shared.writeDirect("\n")
                ui.error("Operation cancelled.")
                return false
            }

            let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if trimmed != "y", trimmed != "yes" {
                ui.info("Operation cancelled.")
                return false
            }

            // Remove existing file
            do {
                try FileManager.default.removeItem(atPath: destination)
                ui.debug("Removed existing config file at: \(destination)")
            } catch {
                let message = "Failed to remove existing config file: \(error.localizedDescription)"
                throw ExFigError.custom(errorString: message)
            }

            return true
        }

        private func writeConfigFile(contents: String, to destination: String, ui: TerminalUI) throws {
            guard let fileData = contents.data(using: .utf8) else {
                throw ExFigError.custom(errorString: "Failed to encode config file contents")
            }

            let success = FileManager.default.createFile(atPath: destination, contents: fileData, attributes: nil)
            if success {
                ui.success("Config file generated: \(destination)")

                ui.info("")
                ui.info("👉 Next Steps:")
                ui.info("1. Edit \(ExFigOptions.defaultConfigFilename) with your Figma file IDs")

                if ProcessInfo.processInfo.environment["FIGMA_PERSONAL_TOKEN"] == nil {
                    ui.info("2. Set your Figma token (missing):")
                    ui.info("   export FIGMA_PERSONAL_TOKEN=your_token_here")
                } else {
                    ui.info("2. Figma token detected in environment ✅")
                }

                ui.info("3. Run export commands:")
                ui.info("   exfig colors")
                ui.info("   exfig icons")
                ui.info("   exfig images")
                ui.info("   exfig typography")
            } else {
                throw ExFigError.custom(errorString: "Unable to create config file at: \(destination)")
            }
        }

        private func promptForPlatform(ui: TerminalUI) throws -> Platform {
            ui.info("Select a platform to generate config for:")
            let platforms = Platform.allCases
            for (index, platform) in platforms.enumerated() {
                ui.info("\(index + 1). \(platform.rawValue)")
            }

            while true {
                TerminalOutputManager.shared.writeDirect("Enter number [1-\(platforms.count)]: ")
                ANSICodes.flushStdout()

                guard let input = readLine(),
                      let index = Int(input.trimmingCharacters(in: .whitespacesAndNewlines)),
                      index > 0, index <= platforms.count
                else {
                    ui.error("Invalid selection. Please enter a number between 1 and \(platforms.count).")
                    continue
                }

                return platforms[index - 1]
            }
        }
    }
}
