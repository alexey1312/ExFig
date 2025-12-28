import ExFigKit
import Foundation
import SwiftUI

// MARK: - Export Phase

/// Represents a phase in the export process.
struct ExportPhase: Identifiable {
    let id = UUID()
    let name: String
    var status: Status
    var progress: Double
    var message: String

    enum Status {
        case pending
        case inProgress
        case completed
        case failed
        case cancelled
    }
}

// MARK: - Export Log Entry

/// A single log entry during export.
struct ExportLogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: Level
    let message: String

    enum Level {
        case info
        case warning
        case error
        case success
        case debug

        var color: Color {
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
        state == .idle || state == .cancelled || state == .completed(success: 0, failed: 0)
    }

    // MARK: - Actions

    /// Start the export process.
    func startExport(platforms: [Platform], assets: [AssetItem]) async {
        state = .preparing
        phases = []
        logs = []
        overallProgress = 0

        // Create phases for each platform
        for platform in platforms {
            phases.append(ExportPhase(
                name: "Export \(platform.rawValue)",
                status: .pending,
                progress: 0,
                message: "Waiting..."
            ))
        }

        state = .exporting

        // Simulate export process (replace with actual ExFigKit integration)
        exportTask = Task {
            var successCount = 0
            var failCount = 0

            for (index, platform) in platforms.enumerated() {
                guard !Task.isCancelled else {
                    state = .cancelled
                    return
                }

                // Update phase status
                phases[index].status = .inProgress
                phases[index].message = "Loading assets..."
                currentPhaseName = platform.rawValue

                // Simulate progress
                for step in stride(from: 0.0, to: 1.0, by: 0.1) {
                    guard !Task.isCancelled else { break }

                    try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                    phases[index].progress = step
                    overallProgress = (Double(index) + step) / Double(platforms.count)
                }

                if Task.isCancelled {
                    phases[index].status = .cancelled
                    phases[index].message = "Cancelled"
                } else {
                    phases[index].status = .completed
                    phases[index].progress = 1.0
                    phases[index].message = "Completed"
                    successCount += 1

                    logs.append(ExportLogEntry(
                        timestamp: Date(),
                        level: .success,
                        message: "\(platform.rawValue) export completed"
                    ))
                }
            }

            if !Task.isCancelled {
                overallProgress = 1.0
                state = .completed(success: successCount, failed: failCount)
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
    private let lock = NSLock()

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
