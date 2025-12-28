import ExFigKit

//
//  BatchProgressViewStorage.swift
//  ExFig
//
//  Created by ExFig on 2025-12-09.
//

import Foundation

/// TaskLocal storage for injecting BatchProgressView during batch processing.
/// This follows the same pattern as InjectedClientStorage and SharedDownloadQueueStorage
/// to enable batch-aware UI suppression in individual export commands.
enum BatchProgressViewStorage {
    /// TaskLocal variable to inject batch progress view into export command context.
    /// When set, individual export commands suppress their spinners and progress bars
    /// to prevent corruption of the multi-line batch progress display.
    @TaskLocal static var progressView: BatchProgressView?

    /// Callback type for reporting incremental download progress.
    typealias DownloadProgressCallback = @Sendable (Int, Int) async -> Void

    /// TaskLocal callback for download progress updates.
    /// Export files report progress through this callback when in batch mode.
    @TaskLocal static var downloadProgressCallback: DownloadProgressCallback?

    /// Current asset type being processed (icons, images, colors, typography).
    /// Used to route progress updates to the correct field in BatchProgressView.
    enum AssetType: String, Sendable {
        case colors
        case icons
        case images
        case typography
    }

    /// TaskLocal to track which asset type is currently being processed.
    @TaskLocal static var currentAssetType: AssetType?
}
