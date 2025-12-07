/// Unified warning types for ExFig CLI output with TOON formatting support.
enum ExFigWarning: Sendable {
    // MARK: - Configuration Warnings

    /// Platform/asset type configuration is missing from config file.
    case configMissing(platform: String, assetType: String)

    // MARK: - Asset Discovery Warnings

    /// No assets found in the specified Figma frame.
    case noAssetsFound(assetType: String, frameName: String)

    // MARK: - Xcode Project Warnings

    /// Failed to add some file references to Xcode project.
    case xcodeProjectUpdateFailed

    // MARK: - Compose Configuration Warnings

    /// Required Compose configuration is missing for ImageVector export.
    case composeRequirementMissing(requirement: String)

    // MARK: - Batch Processing Warnings

    /// No config files found in specified paths.
    case noConfigsFound

    /// Some config files were invalid and skipped.
    case invalidConfigsSkipped(count: Int)

    /// No valid ExFig config files found.
    case noValidConfigs

    /// Checkpoint is expired (older than 24h).
    case checkpointExpired

    /// Checkpoint paths don't match current request.
    case checkpointPathMismatch

    // MARK: - Retry Warnings

    /// Retrying a failed request.
    case retrying(attempt: Int, maxAttempts: Int, error: String, delay: String)
}
