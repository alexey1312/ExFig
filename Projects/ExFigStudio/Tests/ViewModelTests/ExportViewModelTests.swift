import Foundation
import Testing

@testable import ExFigStudio

@Suite("ExportViewModel Tests")
@MainActor
struct ExportViewModelTests {
    // MARK: - Initialization Tests

    @Test("Initial state is idle")
    func initialState() {
        let viewModel = ExportViewModel()

        if case .idle = viewModel.state {
            // Expected
        } else {
            Issue.record("Expected idle state")
        }

        #expect(viewModel.phases.isEmpty)
        #expect(viewModel.logs.isEmpty)
        #expect(!viewModel.isExporting)
    }

    // MARK: - Export State Tests

    @Test("Cancel sets cancelled state")
    func cancelExport() {
        let viewModel = ExportViewModel()
        viewModel.state = .exporting

        viewModel.cancelExport()

        if case .cancelled = viewModel.state {
            // Expected
        } else {
            Issue.record("Expected cancelled state")
        }
    }

    @Test("Cancel adds warning log")
    func cancelAddsLog() {
        let viewModel = ExportViewModel()
        viewModel.state = .exporting

        viewModel.cancelExport()

        #expect(viewModel.logs.contains { $0.level == .warning && $0.message.contains("cancelled") })
    }

    @Test("Reset clears all state")
    func resetClearsState() {
        let viewModel = ExportViewModel()
        viewModel.state = .completed(success: 5, failed: 2)
        viewModel.phases = [ExportPhase(name: "Test", status: .completed, progress: 1.0, message: "Done")]
        viewModel.logs = [ExportLogEntry(timestamp: Date(), level: .info, message: "Test")]
        viewModel.overallProgress = 0.75
        viewModel.currentPhaseName = "Exporting"

        viewModel.reset()

        if case .idle = viewModel.state {
            // Expected
        } else {
            Issue.record("Expected idle state after reset")
        }
        #expect(viewModel.phases.isEmpty)
        #expect(viewModel.logs.isEmpty)
        #expect(viewModel.overallProgress == 0)
        #expect(viewModel.currentPhaseName.isEmpty)
    }

    // MARK: - isExporting Tests

    @Test("isExporting returns true for active states")
    func isExportingForActiveStates() {
        let viewModel = ExportViewModel()

        viewModel.state = .idle
        #expect(!viewModel.isExporting)

        viewModel.state = .preparing
        #expect(viewModel.isExporting)

        viewModel.state = .exporting
        #expect(viewModel.isExporting)

        viewModel.state = .completed(success: 1, failed: 0)
        #expect(!viewModel.isExporting)

        viewModel.state = .failed("Error")
        #expect(!viewModel.isExporting)

        viewModel.state = .cancelled
        #expect(!viewModel.isExporting)
    }
}

// MARK: - ExportState Tests

@Suite("ExportState Tests")
struct ExportStateTests {
    @Test("States are equatable")
    func statesEquatable() {
        #expect(ExportState.idle == ExportState.idle)
        #expect(ExportState.preparing == ExportState.preparing)
        #expect(ExportState.exporting == ExportState.exporting)
        #expect(ExportState.completed(success: 2, failed: 1) == ExportState.completed(success: 2, failed: 1))
        #expect(ExportState.failed("Error") == ExportState.failed("Error"))
        #expect(ExportState.cancelled == ExportState.cancelled)

        #expect(ExportState.completed(success: 2, failed: 1) != ExportState.completed(success: 3, failed: 1))
        #expect(ExportState.failed("Error 1") != ExportState.failed("Error 2"))
    }
}

// MARK: - ExportPhase Tests

@Suite("ExportPhase Tests")
struct ExportPhaseTests {
    @Test("Phase has correct initial values")
    func initialValues() {
        let phase = ExportPhase(name: "Test Phase", status: .pending, progress: 0, message: "Waiting")

        #expect(phase.name == "Test Phase")
        #expect(phase.status == .pending)
        #expect(phase.progress == 0.0)
        #expect(phase.message == "Waiting")
    }

    @Test("Phase status values exist")
    func statusValues() {
        _ = ExportPhase.Status.pending
        _ = ExportPhase.Status.inProgress
        _ = ExportPhase.Status.completed
        _ = ExportPhase.Status.failed
        _ = ExportPhase.Status.cancelled
    }
}

// MARK: - ExportLogEntry Tests

@Suite("ExportLogEntry Tests")
struct ExportLogEntryTests {
    @Test("Log entry has correct timestamp")
    func timestamp() {
        let now = Date()
        let entry = ExportLogEntry(timestamp: now, level: .info, message: "Test")

        #expect(entry.timestamp == now)
    }

    @Test("Log entry is identifiable")
    func identifiable() {
        let entry1 = ExportLogEntry(timestamp: Date(), level: .info, message: "Test 1")
        let entry2 = ExportLogEntry(timestamp: Date(), level: .info, message: "Test 2")

        #expect(entry1.id != entry2.id)
    }

    @Test("Log levels have icons")
    func levelIcons() {
        #expect(ExportLogEntry.Level.info.icon == "info.circle")
        #expect(ExportLogEntry.Level.warning.icon == "exclamationmark.triangle")
        #expect(ExportLogEntry.Level.error.icon == "xmark.circle")
        #expect(ExportLogEntry.Level.success.icon == "checkmark.circle")
        #expect(ExportLogEntry.Level.debug.icon == "ant")
    }

    @Test("Log levels have colors")
    func levelColors() {
        for level in [ExportLogEntry.Level.info, .warning, .error, .success, .debug] {
            // Just verify the color property exists and doesn't crash
            _ = level.color
        }
    }
}
