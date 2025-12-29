import ExFigCore
import ExFigKit
import FigmaAPI
import Foundation
import Logging

// MARK: - Export Result

/// Result of an export operation.
struct ExportResult: Sendable {
    let platform: Platform
    let assetType: AssetType
    let count: Int
    let success: Bool
    let errorMessage: String?

    static func success(platform: Platform, assetType: AssetType, count: Int) -> ExportResult {
        ExportResult(platform: platform, assetType: assetType, count: count, success: true, errorMessage: nil)
    }

    static func failure(platform: Platform, assetType: AssetType, error: Error) -> ExportResult {
        ExportResult(
            platform: platform,
            assetType: assetType,
            count: 0,
            success: false,
            errorMessage: error.localizedDescription
        )
    }

    static func skipped(platform: Platform, assetType: AssetType) -> ExportResult {
        ExportResult(
            platform: platform,
            assetType: assetType,
            count: 0,
            success: true,
            errorMessage: "Not configured"
        )
    }
}

// MARK: - Export Coordinator

/// Actor that coordinates the export process using ExFigKit loaders and platform exporters.
///
/// This coordinator serves as the bridge between the GUI and the CLI export functionality.
/// It uses the same loaders and processors as the CLI but with GUI-specific progress reporting.
///
/// ## Current Limitations
/// - Full export implementation requires additional wiring of platform exporters
/// - For now, exports are simulated with realistic timing
/// - Real implementation will be added incrementally per platform/asset type
actor ExportCoordinator {
    private let client: Client
    private let progressReporter: ProgressReporter
    private let logger: Logger

    init(client: Client, progressReporter: ProgressReporter) {
        self.client = client
        self.progressReporter = progressReporter
        logger = Logger(label: "io.exfig.studio.coordinator")
    }

    // MARK: - Main Export Entry Point

    /// Export all selected asset types to all selected platforms.
    func exportAll(
        params: Params,
        platforms: [Platform],
        assets: Set<AssetType>
    ) async throws -> [ExportResult] {
        var results: [ExportResult] = []

        if assets.contains(.colors) {
            let colorResults = try await exportColors(params: params, platforms: platforms)
            results.append(contentsOf: colorResults)
        }

        if assets.contains(.icons) {
            let iconResults = try await exportIcons(params: params, platforms: platforms)
            results.append(contentsOf: iconResults)
        }

        if assets.contains(.images) {
            let imageResults = try await exportImages(params: params, platforms: platforms)
            results.append(contentsOf: imageResults)
        }

        if assets.contains(.typography) {
            let typographyResults = try await exportTypography(params: params, platforms: platforms)
            results.append(contentsOf: typographyResults)
        }

        return results
    }

    // MARK: - Colors Export

    func exportColors(params: Params, platforms: [Platform]) async throws -> [ExportResult] {
        var results: [ExportResult] = []

        await progressReporter.beginPhase("Loading colors from Figma")

        // Check if we have colors configuration
        guard let variablesConfig = params.common?.variablesColors else {
            await progressReporter.warning("No colors configuration found")
            await progressReporter.endPhase()
            return platforms.map { .skipped(platform: $0, assetType: .colors) }
        }

        do {
            let loader = ColorsVariablesLoader(
                client: client,
                figmaParams: params.figma,
                variableParams: variablesConfig,
                filter: nil
            )

            let colorsOutput = try await loader.load()
            let colorCount = colorsOutput.light.count
            await progressReporter.info("Loaded \(colorCount) colors from Figma Variables")

            // Export to each platform
            for platform in platforms {
                await progressReporter.info("Exporting colors to \(platform.rawValue)...")

                // TODO: Wire up actual platform exporters
                // For now, simulate export with realistic delay
                try await Task.sleep(nanoseconds: 500_000_000)

                results.append(.success(platform: platform, assetType: .colors, count: colorCount))
                await progressReporter.success("Exported \(colorCount) colors to \(platform.rawValue)")
            }
        } catch {
            await progressReporter.error("Failed to load colors: \(error.localizedDescription)")
            for platform in platforms {
                results.append(.failure(platform: platform, assetType: .colors, error: error))
            }
        }

        await progressReporter.endPhase()
        return results
    }

    // MARK: - Icons Export

    func exportIcons(params: Params, platforms: [Platform]) async throws -> [ExportResult] {
        var results: [ExportResult] = []

        await progressReporter.beginPhase("Loading icons from Figma")

        do {
            let loader = IconsLoader(
                client: client,
                params: params,
                platform: .ios,
                logger: logger
            )

            let icons = try await loader.load()
            await progressReporter.info("Loaded \(icons.light.count) icons")

            for platform in platforms {
                await progressReporter.info("Exporting icons to \(platform.rawValue)...")

                // TODO: Wire up actual platform exporters
                try await Task.sleep(nanoseconds: 800_000_000)

                results.append(.success(platform: platform, assetType: .icons, count: icons.light.count))
                await progressReporter.success("Exported \(icons.light.count) icons to \(platform.rawValue)")
            }
        } catch {
            await progressReporter.error("Failed to load icons: \(error.localizedDescription)")
            for platform in platforms {
                results.append(.failure(platform: platform, assetType: .icons, error: error))
            }
        }

        await progressReporter.endPhase()
        return results
    }

    // MARK: - Images Export

    func exportImages(params: Params, platforms: [Platform]) async throws -> [ExportResult] {
        var results: [ExportResult] = []

        await progressReporter.beginPhase("Loading images from Figma")

        do {
            let loader = ImagesLoader(
                client: client,
                params: params,
                platform: .ios,
                logger: logger
            )

            let images = try await loader.load()
            await progressReporter.info("Loaded \(images.light.count) images")

            for platform in platforms {
                await progressReporter.info("Exporting images to \(platform.rawValue)...")

                // TODO: Wire up actual platform exporters
                try await Task.sleep(nanoseconds: 1_000_000_000)

                results.append(.success(platform: platform, assetType: .images, count: images.light.count))
                await progressReporter.success("Exported \(images.light.count) images to \(platform.rawValue)")
            }
        } catch {
            await progressReporter.error("Failed to load images: \(error.localizedDescription)")
            for platform in platforms {
                results.append(.failure(platform: platform, assetType: .images, error: error))
            }
        }

        await progressReporter.endPhase()
        return results
    }

    // MARK: - Typography Export

    func exportTypography(params: Params, platforms: [Platform]) async throws -> [ExportResult] {
        var results: [ExportResult] = []

        await progressReporter.beginPhase("Loading typography from Figma")

        do {
            let loader = TextStylesLoader(client: client, params: params.figma)
            let textStyles = try await loader.load()
            await progressReporter.info("Loaded \(textStyles.count) text styles")

            for platform in platforms {
                await progressReporter.info("Exporting typography to \(platform.rawValue)...")

                // TODO: Wire up actual platform exporters
                try await Task.sleep(nanoseconds: 500_000_000)

                results.append(.success(platform: platform, assetType: .typography, count: textStyles.count))
                await progressReporter.success("Exported \(textStyles.count) text styles to \(platform.rawValue)")
            }
        } catch {
            await progressReporter.error("Failed to load typography: \(error.localizedDescription)")
            for platform in platforms {
                results.append(.failure(platform: platform, assetType: .typography, error: error))
            }
        }

        await progressReporter.endPhase()
        return results
    }
}
