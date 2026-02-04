import ExFig_Android
import ExFig_iOS
import ExFigCore
import FigmaAPI
import Foundation
import XcodeExport

// MARK: - Typography Export Input

/// Groups common parameters for typography export to reduce function parameter count.
struct TypographyExportInput {
    let figma: Params.Figma?
    let common: Params.Common?
    let client: Client
    let ui: TerminalUI
}

// MARK: - Plugin-based Typography Export

extension ExFigCommand.ExportTypography {
    /// Exports iOS typography using plugin architecture.
    ///
    /// This method uses `iOSTypographyExporter` from the plugin system instead of
    /// direct implementation. It handles both export and post-export tasks
    /// like Xcode project updates.
    ///
    /// - Parameters:
    ///   - entry: Params typography entry to convert and export.
    ///   - ios: iOS platform configuration from Params.
    ///   - input: Common export input (figma, common, client, ui).
    /// - Returns: Number of text styles exported.
    func exportiOSTypographyViaPlugin(
        entry: Params.iOS.Typography,
        ios: Params.iOS,
        input: TypographyExportInput
    ) async throws -> Int {
        // Convert Params to plugin types
        let pluginEntry = entry.toPluginEntry(common: input.common)
        let platformConfig = ios.platformConfig(figma: input.figma)

        // Create context
        let batchMode = BatchSharedState.current?.isBatchMode ?? false
        let context = TypographyExportContextImpl(
            client: input.client,
            ui: input.ui,
            filter: nil,
            isBatchMode: batchMode
        )

        // Export via plugin
        let exporter = iOSTypographyExporter()
        let count = try await exporter.exportTypography(
            entry: pluginEntry,
            platformConfig: platformConfig,
            context: context
        )

        // Post-export: update Xcode project (only if not in Swift Package)
        if ios.xcassetsInSwiftPackage != true {
            do {
                let xcodeProject = try XcodeProjectWriter(
                    xcodeProjPath: ios.xcodeprojPath,
                    target: ios.target
                )
                // Add Swift file references
                if let fontSwift = pluginEntry.fontSwift {
                    try xcodeProject.addFileReferenceToXcodeProj(fontSwift)
                }
                if let swiftUIFontSwift = pluginEntry.swiftUIFontSwift {
                    try xcodeProject.addFileReferenceToXcodeProj(swiftUIFontSwift)
                }
                if let labelStyleSwift = pluginEntry.labelStyleSwift {
                    try xcodeProject.addFileReferenceToXcodeProj(labelStyleSwift)
                }
                try xcodeProject.save()
            } catch {
                input.ui.warning(.xcodeProjectUpdateFailed)
            }
        }

        // Check for updates (only in standalone mode)
        if !batchMode {
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        return count
    }

    /// Exports Android typography using plugin architecture.
    func exportAndroidTypographyViaPlugin(
        entry: Params.Android.Typography,
        android: Params.Android,
        input: TypographyExportInput
    ) async throws -> Int {
        let pluginEntry = entry.toPluginEntry(common: input.common)
        let platformConfig = android.platformConfig(figma: input.figma)

        let batchMode = BatchSharedState.current?.isBatchMode ?? false
        let context = TypographyExportContextImpl(
            client: input.client,
            ui: input.ui,
            filter: nil,
            isBatchMode: batchMode
        )

        let exporter = AndroidTypographyExporter()
        let count = try await exporter.exportTypography(
            entry: pluginEntry,
            platformConfig: platformConfig,
            context: context
        )

        if !batchMode {
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        return count
    }
}
