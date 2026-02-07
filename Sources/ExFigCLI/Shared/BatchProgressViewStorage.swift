//
//  BatchProgressViewStorage.swift
//  ExFig
//
//  Created by ExFig on 2025-12-09.
//

import Foundation

/// Compatibility shim for BatchProgressView access.
///
/// Reads progress view from `BatchSharedState.current`.
/// This avoids nested TaskLocal.withValue() calls which cause Swift runtime crashes on Linux.
/// See: https://github.com/swiftlang/swift/issues/75501
///
/// ## Usage
///
/// ```swift
/// // Read progress view (shim to BatchSharedState)
/// if let progressView = BatchProgressViewStorage.progressView { ... }
///
/// // Direct access (preferred)
/// if let progressView = BatchSharedState.current?.progressView { ... }
/// ```
///
/// ## Note
///
/// `downloadProgressCallback` and `currentAssetType` are now passed via
/// `ConfigExecutionContext` parameter, not via TaskLocal.
enum BatchProgressViewStorage {
    // MARK: - Types

    /// Callback type for reporting incremental download progress.
    typealias DownloadProgressCallback = @Sendable (Int, Int) async -> Void

    /// Current asset type being processed (icons, images, colors, typography).
    /// @deprecated Use `ConfigExecutionContext.AssetType` instead.
    enum AssetType: String, Sendable {
        case colors
        case icons
        case images
        case typography
    }

    // MARK: - Accessors (Shim to BatchSharedState)

    /// Get batch progress view from BatchSharedState.
    static var progressView: BatchProgressView? {
        BatchSharedState.current?.progressView
    }

    /// Download progress callback (deprecated - use ConfigExecutionContext).
    /// Returns nil - callbacks are now passed explicitly.
    static var downloadProgressCallback: DownloadProgressCallback? {
        nil
    }

    /// Current asset type (deprecated - use ConfigExecutionContext.assetType).
    /// Returns nil - asset type is now passed explicitly.
    static var currentAssetType: AssetType? {
        nil
    }
}
