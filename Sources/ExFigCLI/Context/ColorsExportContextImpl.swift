import ExFigConfig
import ExFigCore
import FigmaAPI
import Foundation

/// Concrete implementation of `ColorsExportContext` for the ExFig CLI.
///
/// Bridges between the plugin system and ExFig's internal services:
/// - Uses `ColorsVariablesLoader` for Figma data loading
/// - Uses `ColorsProcessor` for platform-specific processing
/// - Uses `ExFigCommand.fileWriter` for file output
/// - Uses `TerminalUI` for progress and logging
struct ColorsExportContextImpl: ColorsExportContext {
    let client: Client
    let ui: TerminalUI
    let filter: String?
    let isBatchMode: Bool

    init(
        client: Client,
        ui: TerminalUI,
        filter: String? = nil,
        isBatchMode: Bool = false
    ) {
        self.client = client
        self.ui = ui
        self.filter = filter
        self.isBatchMode = isBatchMode
    }

    // MARK: - ExportContext

    func writeFiles(_ files: [FileContents]) throws {
        try ExFigCommand.fileWriter.write(files: files)
    }

    func info(_ message: String) {
        ui.info(message)
    }

    func warning(_ message: String) {
        ui.warning(message)
    }

    func success(_ message: String) {
        ui.success(message)
    }

    func withSpinner<T: Sendable>(
        _ message: String,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await ui.withSpinner(message, operation: operation)
    }

    // MARK: - ColorsExportContext

    func loadColors(from source: ColorsSourceInput) async throws -> ColorsLoadOutput {
        if let tokensFilePath = source.tokensFilePath {
            return try loadColorsFromTokensFile(path: tokensFilePath, groupFilter: source.tokensFileGroupFilter)
        }
        return try await loadColorsFromFigma(source: source)
    }

    private func loadColorsFromTokensFile(path: String, groupFilter: String?) throws -> ColorsLoadOutput {
        var source = try TokensFileSource.parse(fileAt: path)
        try source.resolveAliases()

        for warning in source.warnings {
            ui.warning(warning)
        }

        var colors = source.toColors()

        if let groupFilter {
            let prefix = groupFilter.replacingOccurrences(of: ".", with: "/") + "/"
            colors = colors.filter { $0.name.hasPrefix(prefix) }
        }

        return ColorsLoadOutput(light: colors)
    }

    private func loadColorsFromFigma(source: ColorsSourceInput) async throws -> ColorsLoadOutput {
        let variableParams = Common.VariablesColors(
            tokensFileId: source.tokensFileId,
            tokensCollectionName: source.tokensCollectionName,
            lightModeName: source.lightModeName,
            darkModeName: source.darkModeName,
            lightHCModeName: source.lightHCModeName,
            darkHCModeName: source.darkHCModeName,
            primitivesModeName: source.primitivesModeName,
            nameValidateRegexp: source.nameValidateRegexp,
            nameReplaceRegexp: source.nameReplaceRegexp
        )

        let loader = ColorsVariablesLoader(
            client: client,
            variableParams: variableParams,
            filter: filter
        )

        let result = try await loader.load()

        for warning in result.warnings {
            ui.warning(warning)
        }

        return ColorsLoadOutput(
            light: result.output.light,
            dark: result.output.dark ?? [],
            lightHC: result.output.lightHC ?? [],
            darkHC: result.output.darkHC ?? []
        )
    }

    func processColors(
        _ colors: ColorsLoadOutput,
        platform: Platform,
        nameValidateRegexp: String?,
        nameReplaceRegexp: String?,
        nameStyle: NameStyle
    ) throws -> ColorsProcessResult {
        let processor = ColorsProcessor(
            platform: platform,
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp,
            nameStyle: nameStyle
        )

        let result = processor.process(
            light: colors.light,
            dark: colors.dark.isEmpty ? nil : colors.dark,
            lightHC: colors.lightHC.isEmpty ? nil : colors.lightHC,
            darkHC: colors.darkHC.isEmpty ? nil : colors.darkHC
        )

        return try ColorsProcessResult(
            colorPairs: result.get(),
            warning: result.warning.map { WarningFormatter().format($0, compact: isBatchMode) }
        )
    }
}
