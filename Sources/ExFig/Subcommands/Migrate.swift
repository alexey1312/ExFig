import ArgumentParser
import Foundation
import Rainbow
import Yams

extension ExFigCommand {
    struct MigrateConfig: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "migrate",
            abstract: "Migrate figma-export config to ExFig format",
            discussion: """
            Migrates a figma-export.yaml configuration file to ExFig format,
            adding new features like version caching.

            Examples:
              exfig migrate                              Auto-detect figma-export.yaml
              exfig migrate figma-export.yaml            Migrate to exfig.yaml
              exfig migrate old.yaml -o new.yaml         Custom output path
              exfig migrate figma-export.yaml --force    Overwrite without confirmation
            """
        )

        @OptionGroup
        var globalOptions: GlobalOptions

        @Argument(help: "Input config file (default: figma-export.yaml)")
        var input: String?

        @Option(name: .shortAndLong, help: "Output file path (default: exfig.yaml)")
        var output: String = ExFigOptions.defaultConfigFilename

        @Flag(name: .shortAndLong, help: "Overwrite output file without confirmation")
        var force: Bool = false

        func run() async throws {
            ExFigCommand.initializeTerminalUI(verbose: globalOptions.verbose, quiet: globalOptions.quiet)
            let ui = ExFigCommand.terminalUI!

            // Resolve input file
            let inputPath = try resolveInputPath()
            ui.info("Reading: \(inputPath)")

            // Read and validate config
            let content = try readConfigFile(at: inputPath)
            let yaml = try validateConfig(content: content, ui: ui)
            ui.success("Configuration valid")

            // Check if cache section already exists
            if hasCacheSection(yaml: yaml) {
                ui.success("Config already has cache section. No migration needed.")
                return
            }

            // Generate migrated content
            let migratedContent = try addCacheSection(to: content, yaml: yaml)

            // Show diff
            showDiff(original: content, migrated: migratedContent, ui: ui)

            // Check output file and confirm
            let outputPath = resolveOutputPath()
            if FileManager.default.fileExists(atPath: outputPath), !force {
                ui.info("")
                ui.info("Output: \(output)")
                if !ui.confirm("File already exists. Overwrite?") {
                    ui.info("Migration cancelled.")
                    return
                }
            }

            // Write output file
            try writeConfigFile(content: migratedContent, to: outputPath)
            ui.success("Migration complete: \(output)")
            ui.info("")
            ui.info("New features available:")
            ui.info("  --cache                         Enable version tracking")
            ui.info("  --experimental-granular-cache   Track per-node changes")
            ui.info("  exfig batch                     Process multiple configs")
        }

        // MARK: - Private Methods

        private func resolveInputPath() throws -> String {
            if let userPath = input {
                guard FileManager.default.fileExists(atPath: userPath) else {
                    throw ExFigError.custom(errorString: "File not found: \(userPath)")
                }
                return userPath
            }

            // Auto-detect figma-export.yaml
            let defaultInput = "figma-export.yaml"
            if FileManager.default.fileExists(atPath: defaultInput) {
                return defaultInput
            }

            throw ExFigError.custom(
                errorString: "No input file specified and figma-export.yaml not found in current directory"
            )
        }

        private func readConfigFile(at path: String) throws -> String {
            guard let data = FileManager.default.contents(atPath: path),
                  let content = String(data: data, encoding: .utf8)
            else {
                throw ExFigError.custom(errorString: "Unable to read file: \(path)")
            }
            return content
        }

        private func resolveOutputPath() -> String {
            // Handle absolute paths
            if output.hasPrefix("/") || output.hasPrefix("~") {
                return (output as NSString).expandingTildeInPath
            }
            return FileManager.default.currentDirectoryPath + "/" + output
        }

        private func validateConfig(content: String, ui: TerminalUI) throws -> [String: Any] {
            ui.info("Validating configuration...")

            // Parse as YAML dictionary to check structure
            guard let yaml = try Yams.load(yaml: content) as? [String: Any] else {
                throw ExFigError.custom(errorString: "Invalid YAML format")
            }

            // Check for required 'figma' section
            guard yaml["figma"] != nil else {
                throw ExFigError.custom(errorString: "Missing required 'figma' section")
            }

            // Validate 'figma.lightFileId'
            if let figma = yaml["figma"] as? [String: Any] {
                guard figma["lightFileId"] != nil else {
                    throw ExFigError.custom(errorString: "Missing required 'figma.lightFileId'")
                }
            }

            return yaml
        }

        private func hasCacheSection(yaml: [String: Any]) -> Bool {
            guard let common = yaml["common"] as? [String: Any] else {
                return false
            }
            return common["cache"] != nil
        }

        private func addCacheSection(to content: String, yaml: [String: Any]) throws -> String {
            // Detect indentation from existing content
            let indent = detectIndentation(in: content)
            let cacheBlock = """
            \(indent)cache:
            \(indent)\(indent)enabled: true
            \(indent)\(indent)path: ".exfig-cache.json"
            """

            // If common section exists, add cache to it
            if yaml["common"] != nil {
                return insertCacheIntoCommon(content: content, cacheBlock: cacheBlock, indent: indent)
            }

            // No common section - add it after figma section
            return insertCommonSection(content: content, cacheBlock: cacheBlock)
        }

        private func detectIndentation(in content: String) -> String {
            // Find first indented line to detect indent style
            for line in content.components(separatedBy: "\n") {
                let leadingSpaces = line.prefix(while: { $0 == " " })
                if !leadingSpaces.isEmpty, line.trimmingCharacters(in: .whitespaces).contains(":") {
                    return String(leadingSpaces)
                }
            }
            return "  " // Default to 2 spaces
        }

        private func insertCacheIntoCommon(content: String, cacheBlock: String, indent: String) -> String {
            let lines = content.components(separatedBy: "\n")
            var result: [String] = []
            var inCommonSection = false
            var commonIndentLevel = 0
            var insertedCache = false

            for line in lines {
                // Detect common: section start
                if line.trimmingCharacters(in: .whitespaces).hasPrefix("common:") {
                    inCommonSection = true
                    commonIndentLevel = line.prefix(while: { $0 == " " }).count
                    result.append(line)

                    // Insert cache block right after common:
                    result.append(cacheBlock)
                    insertedCache = true
                    continue
                }

                // Skip if we're past common section (found next top-level key)
                if inCommonSection, !insertedCache {
                    let currentIndent = line.prefix(while: { $0 == " " }).count
                    let trimmed = line.trimmingCharacters(in: .whitespaces)

                    if currentIndent <= commonIndentLevel, !trimmed.isEmpty, !trimmed.hasPrefix("#") {
                        inCommonSection = false
                    }
                }

                result.append(line)
            }

            return result.joined(separator: "\n")
        }

        private func insertCommonSection(content: String, cacheBlock: String) -> String {
            let lines = content.components(separatedBy: "\n")
            var result: [String] = []
            var afterFigmaSection = false
            var figmaIndentLevel = 0
            var insertedCommon = false

            for line in lines {
                // Detect figma: section start
                if line.trimmingCharacters(in: .whitespaces).hasPrefix("figma:") {
                    afterFigmaSection = true
                    figmaIndentLevel = line.prefix(while: { $0 == " " }).count
                    result.append(line)
                    continue
                }

                // Find end of figma section (next top-level key)
                if afterFigmaSection, !insertedCommon {
                    let currentIndent = line.prefix(while: { $0 == " " }).count
                    let trimmed = line.trimmingCharacters(in: .whitespaces)

                    if currentIndent <= figmaIndentLevel, !trimmed.isEmpty, !trimmed.hasPrefix("#") {
                        // Insert common section before next top-level key
                        result.append("")
                        result.append("common:")
                        result.append(cacheBlock)
                        result.append("")
                        insertedCommon = true
                        afterFigmaSection = false
                    }
                }

                result.append(line)
            }

            // If figma was last section, append common at end
            if !insertedCommon {
                result.append("")
                result.append("common:")
                result.append(cacheBlock)
            }

            return result.joined(separator: "\n")
        }

        private func showDiff(original: String, migrated: String, ui: TerminalUI) {
            ui.info("")
            ui.info("Changes to apply:")

            let originalLines = Set(original.components(separatedBy: "\n"))
            let migratedLines = migrated.components(separatedBy: "\n")

            let useColors = ui.outputMode.useColors && TTYDetector.colorsEnabled

            for line in migratedLines where !originalLines.contains(line) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    let formatted = "  + \(line)"
                    if useColors {
                        TerminalOutputManager.shared.print(formatted.green)
                    } else {
                        TerminalOutputManager.shared.print(formatted)
                    }
                }
            }

            ui.info("")
        }

        private func writeConfigFile(content: String, to path: String) throws {
            // Remove existing file if present
            if FileManager.default.fileExists(atPath: path) {
                try FileManager.default.removeItem(atPath: path)
            }

            guard let data = content.data(using: .utf8) else {
                throw ExFigError.custom(errorString: "Failed to encode config content")
            }

            let success = FileManager.default.createFile(atPath: path, contents: data, attributes: nil)
            guard success else {
                throw ExFigError.custom(errorString: "Unable to create file: \(path)")
            }
        }
    }
}
