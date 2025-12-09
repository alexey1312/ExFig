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
}
