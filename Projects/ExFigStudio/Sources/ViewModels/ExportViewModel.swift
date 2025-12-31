import ExFigCore
import ExFigKit
import FigmaAPI
import Foundation
import SwiftUI

// MARK: - Export Phase

/// Represents a phase in the export process.
struct ExportPhase: Identifiable, Sendable {
    let id = UUID()
    let name: String
    var status: Status
    var progress: Double
    var message: String

    enum Status: Sendable {
        case pending
        case inProgress
        case completed
        case failed
        case cancelled
    }
}

// MARK: - Export Log Entry

/// A single log entry during export.
struct ExportLogEntry: Identifiable, Sendable {
    let id = UUID()
    let timestamp: Date
    let level: Level
    let message: String

    enum Level: Sendable {
        case info
        case warning
        case error
        case success
        case debug

        var color: SwiftUI.Color {
            switch self {
            case .info: .primary
            case .warning: .orange
            case .error: .red
            case .success: .green
            case .debug: .secondary
            }
        }

        var icon: String {
            switch self {
            case .info: "info.circle"
            case .warning: "exclamationmark.triangle"
            case .error: "xmark.circle"
            case .success: "checkmark.circle"
            case .debug: "ant"
            }
        }
    }
}

// MARK: - Export State

/// Overall export state.
enum ExportState: Equatable {
    case idle
    case preparing
    case exporting
    case completed(success: Int, failed: Int)
    case failed(String)
    case cancelled
}

// MARK: - Export View Model

/// View model for the export progress view.
@MainActor
@Observable
final class ExportViewModel {
    // MARK: - State

    var state: ExportState = .idle
    var phases: [ExportPhase] = []
    var logs: [ExportLogEntry] = []
    var overallProgress: Double = 0
    var currentPhaseName: String = ""

    // Detailed progress
    var batchProgress: (completed: Int, total: Int) = (0, 0)
    var itemProgress: (completed: Int, total: Int) = (0, 0)

    // Export task
    private var exportTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var isExporting: Bool {
        if case .exporting = state { return true }
        if case .preparing = state { return true }
        return false
    }

    var canStart: Bool {
        switch state {
        case .idle, .cancelled, .completed, .failed:
            true
        case .preparing, .exporting:
            false
        }
    }

    // MARK: - Actions

    /// Start the export process using the real ExportCoordinator.
    ///
    /// - Parameters:
    ///   - params: Configuration parameters built from GUI settings.
    ///   - platforms: Platform configurations from ConfigViewModel.
    ///   - selectedAssets: Set of asset types to export.
    ///   - figmaAuth: Authentication for Figma API.
    func startExport(
        params: Params,
        platforms: [PlatformConfig],
        selectedAssets: Set<AssetType>,
        figmaAuth: FigmaAuth
    ) async {
        state = .preparing
        phases = []
        logs = []
        overallProgress = 0

        // Create phases for enabled platforms
        let enabledPlatforms = platforms.filter(\.isEnabled)
        for config in enabledPlatforms {
            phases.append(ExportPhase(
                name: "Export \(config.platform.rawValue)",
                status: .pending,
                progress: 0,
                message: "Waiting..."
            ))
        }

        state = .exporting

        exportTask = Task {
            let client = figmaAuth.makeClient()
            let reporter = GUIProgressReporter(viewModel: self)
            let coordinator = ExportCoordinator(client: client, progressReporter: reporter)

            // Convert GUI Platform to ExFigCore.Platform
            let corePlatforms = enabledPlatforms.compactMap { config -> ExFigCore.Platform? in
                ExFigCore.Platform(rawValue: config.platform.rawValue.lowercased())
            }

            do {
                let results = try await coordinator.exportAll(
                    params: params,
                    platforms: corePlatforms,
                    assets: selectedAssets
                )

                // Aggregate results
                let successCount = results.filter(\.success).count
                let failCount = results.filter { !$0.success }.count

                // Update phase statuses based on results
                for (index, result) in results.enumerated() where index < phases.count {
                    if result.success {
                        phases[index].status = .completed
                        phases[index].progress = 1.0
                        phases[index].message = "Exported \(result.count) items"
                    } else {
                        phases[index].status = .failed
                        phases[index].message = result.errorMessage ?? "Failed"
                    }
                }

                overallProgress = 1.0
                state = .completed(success: successCount, failed: failCount)
            } catch {
                state = .failed(error.localizedDescription)
                logs.append(ExportLogEntry(
                    timestamp: Date(),
                    level: .error,
                    message: error.localizedDescription
                ))
            }
        }

        await exportTask?.value
    }

    /// Cancel the current export.
    func cancelExport() {
        exportTask?.cancel()

        // Update any in-progress phases
        for index in phases.indices where phases[index].status == .inProgress {
            phases[index].status = .cancelled
            phases[index].message = "Cancelled"
        }

        state = .cancelled
        logs.append(ExportLogEntry(
            timestamp: Date(),
            level: .warning,
            message: "Export cancelled by user"
        ))
    }

    /// Reset to idle state.
    func reset() {
        exportTask?.cancel()
        exportTask = nil
        state = .idle
        phases = []
        logs = []
        overallProgress = 0
        batchProgress = (0, 0)
        itemProgress = (0, 0)
        currentPhaseName = ""
    }
}

// MARK: - GUI Progress Reporter

/// Progress reporter implementation for SwiftUI.
final class GUIProgressReporter: ProgressReporter, @unchecked Sendable {
    private let viewModel: ExportViewModel

    init(viewModel: ExportViewModel) {
        self.viewModel = viewModel
    }

    func beginPhase(_ name: String) async {
        await MainActor.run {
            viewModel.currentPhaseName = name
            viewModel.logs.append(ExportLogEntry(
                timestamp: Date(),
                level: .info,
                message: "Starting: \(name)"
            ))
        }
    }

    func endPhase() async {
        await MainActor.run {
            viewModel.currentPhaseName = ""
        }
    }

    func reportBatchProgress(completed: Int, total: Int) async {
        await MainActor.run {
            viewModel.batchProgress = (completed, total)
            if total > 0 {
                viewModel.overallProgress = Double(completed) / Double(total)
            }
        }
    }

    func reportItemProgress(completed: Int, total: Int) async {
        await MainActor.run {
            viewModel.itemProgress = (completed, total)
        }
    }

    func info(_ message: String) async {
        await MainActor.run {
            viewModel.logs.append(ExportLogEntry(
                timestamp: Date(),
                level: .info,
                message: message
            ))
        }
    }

    func warning(_ message: String) async {
        await MainActor.run {
            viewModel.logs.append(ExportLogEntry(
                timestamp: Date(),
                level: .warning,
                message: message
            ))
        }
    }

    func error(_ message: String) async {
        await MainActor.run {
            viewModel.logs.append(ExportLogEntry(
                timestamp: Date(),
                level: .error,
                message: message
            ))
        }
    }

    func success(_ message: String) async {
        await MainActor.run {
            viewModel.logs.append(ExportLogEntry(
                timestamp: Date(),
                level: .success,
                message: message
            ))
        }
    }

    func debug(_ message: String) async {
        await MainActor.run {
            viewModel.logs.append(ExportLogEntry(
                timestamp: Date(),
                level: .debug,
                message: message
            ))
        }
    }
}
