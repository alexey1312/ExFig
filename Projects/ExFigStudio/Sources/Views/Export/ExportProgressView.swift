import SwiftUI

// MARK: - Export Progress View

/// View showing export progress with phases and logs.
struct ExportProgressView: View {
    @Bindable var viewModel: ExportViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header with overall progress
            headerView
                .padding()
                .background(.bar)

            Divider()

            // Content split view
            HSplitView {
                // Phases list
                phasesView
                    .frame(minWidth: 300)

                // Log view
                logView
                    .frame(minWidth: 400)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 16) {
            // Status icon
            statusIcon
                .font(.title)

            // Progress info
            VStack(alignment: .leading, spacing: 4) {
                Text(statusTitle)
                    .font(.headline)

                if viewModel.isExporting {
                    Text(viewModel.currentPhaseName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Progress bar
            if viewModel.isExporting {
                VStack(alignment: .trailing, spacing: 4) {
                    ProgressView(value: viewModel.overallProgress)
                        .frame(width: 200)

                    Text("\(Int(viewModel.overallProgress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Action button
            actionButton
        }
    }

    private var statusIcon: some View {
        Group {
            switch viewModel.state {
            case .idle:
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(.secondary)
            case .preparing:
                ProgressView()
                    .controlSize(.small)
            case .exporting:
                ProgressView()
                    .controlSize(.small)
            case let .completed(success, _):
                Image(systemName: success > 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(success > 0 ? .green : .red)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            case .cancelled:
                Image(systemName: "stop.circle.fill")
                    .foregroundStyle(.orange)
            }
        }
    }

    private var statusTitle: String {
        switch viewModel.state {
        case .idle:
            "Ready to Export"
        case .preparing:
            "Preparing..."
        case .exporting:
            "Exporting..."
        case let .completed(success, failed):
            "Completed (\(success) succeeded, \(failed) failed)"
        case let .failed(message):
            "Failed: \(message)"
        case .cancelled:
            "Cancelled"
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch viewModel.state {
        case .exporting, .preparing:
            Button("Cancel") {
                viewModel.cancelExport()
            }
            .buttonStyle(.bordered)
            .tint(.red)

        case .completed, .failed, .cancelled:
            Button("Reset") {
                viewModel.reset()
            }
            .buttonStyle(.bordered)

        default:
            EmptyView()
        }
    }

    // MARK: - Phases View

    private var phasesView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Export Phases")
                .font(.headline)
                .padding()

            Divider()

            if viewModel.phases.isEmpty {
                ContentUnavailableView {
                    Label("No Phases", systemImage: "list.bullet")
                } description: {
                    Text("Start an export to see phases")
                }
            } else {
                List {
                    ForEach(viewModel.phases) { phase in
                        PhaseRow(phase: phase)
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(.background)
    }

    // MARK: - Log View

    private var logView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Export Log")
                    .font(.headline)

                Spacer()

                Text("\(viewModel.logs.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            if viewModel.logs.isEmpty {
                ContentUnavailableView {
                    Label("No Logs", systemImage: "doc.text")
                } description: {
                    Text("Logs will appear here during export")
                }
            } else {
                ScrollViewReader { proxy in
                    List {
                        ForEach(viewModel.logs) { entry in
                            LogEntryRow(entry: entry)
                                .id(entry.id)
                        }
                    }
                    .listStyle(.plain)
                    .onChange(of: viewModel.logs.count) { _, _ in
                        if let lastEntry = viewModel.logs.last {
                            withAnimation {
                                proxy.scrollTo(lastEntry.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .background(.background)
    }
}

// MARK: - Phase Row

struct PhaseRow: View {
    let phase: ExportPhase

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            statusIndicator

            // Phase info
            VStack(alignment: .leading, spacing: 4) {
                Text(phase.name)
                    .font(.body)

                Text(phase.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Progress
            if phase.status == .inProgress {
                ProgressView(value: phase.progress)
                    .frame(width: 80)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch phase.status {
        case .pending:
            Image(systemName: "circle")
                .foregroundStyle(.secondary)
        case .inProgress:
            ProgressView()
                .controlSize(.small)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        case .cancelled:
            Image(systemName: "stop.circle.fill")
                .foregroundStyle(.orange)
        }
    }
}

// MARK: - Log Entry Row

struct LogEntryRow: View {
    let entry: ExportLogEntry

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: entry.level.icon)
                .foregroundStyle(entry.level.color)
                .font(.caption)

            Text(entry.timestamp, format: .dateTime.hour().minute().second())
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)

            Text(entry.message)
                .font(.callout)
                .foregroundStyle(entry.level.color)

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#Preview {
    ExportProgressView(viewModel: {
        let vm = ExportViewModel()
        vm.phases = [
            ExportPhase(name: "Export iOS", status: .completed, progress: 1.0, message: "Completed"),
            ExportPhase(name: "Export Android", status: .inProgress, progress: 0.6, message: "Downloading icons..."),
            ExportPhase(name: "Export Flutter", status: .pending, progress: 0, message: "Waiting..."),
        ]
        vm.logs = [
            ExportLogEntry(timestamp: Date(), level: .info, message: "Starting export..."),
            ExportLogEntry(timestamp: Date(), level: .success, message: "iOS export completed"),
            ExportLogEntry(timestamp: Date(), level: .info, message: "Starting Android export..."),
        ]
        vm.state = .exporting
        vm.overallProgress = 0.5
        vm.currentPhaseName = "Export Android"
        return vm
    }())
        .frame(width: 900, height: 500)
}
