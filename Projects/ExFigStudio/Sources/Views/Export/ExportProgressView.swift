// swiftlint:disable file_length type_body_length
import ExFigCore
import ExFigKit
import FigmaAPI
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Export Progress View

/// View showing export progress with phases and logs.
struct ExportProgressView: View {
    @Bindable var appState: AppState

    // Convenience accessors
    private var viewModel: ExportViewModel { appState.exportViewModel }
    private var configViewModel: ConfigViewModel { appState.configViewModel }

    // State for directory picker
    @State private var showingDirectoryPicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with overall progress
            headerView
                .padding()
                .background(.bar)

            Divider()

            // Content based on state
            if case .idle = viewModel.state {
                // Show export setup when idle
                exportSetupView
            } else {
                // Content split view during/after export
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
        .fileImporter(
            isPresented: $showingDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case let .success(urls) = result, let url = urls.first {
                // Start accessing security-scoped resource for initial validation
                let didStartAccessing = url.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                configViewModel.outputDirectory = url
            }
        }
    }

    // MARK: - Export Setup View

    private var exportSetupView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "square.and.arrow.up.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            // Title
            Text("Ready to Export")
                .font(.largeTitle)
                .fontWeight(.medium)

            // Validation status
            validationStatusView

            // Output directory picker
            outputDirectorySection

            // Enabled platforms summary
            platformsSummaryView

            // Start button
            startExportButton

            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var validationStatusView: some View {
        if !configViewModel.isValid {
            VStack(spacing: 8) {
                ForEach(configViewModel.validationErrors, id: \.self) { error in
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var outputDirectorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Output Directory")
                .font(.headline)

            HStack {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.secondary)

                Text(configViewModel.outputDirectory.path)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Button("Choose...") {
                    showingDirectoryPicker = true
                }
            }
            .padding()
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: 500)
    }

    private var platformsSummaryView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enabled Platforms")
                .font(.headline)

            if configViewModel.enabledPlatforms.isEmpty {
                Text("No platforms enabled")
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 16) {
                    ForEach(configViewModel.enabledPlatforms) { config in
                        VStack(spacing: 4) {
                            Image(systemName: config.platform.iconName)
                                .font(.title2)
                            Text(config.platform.rawValue)
                                .font(.caption)
                        }
                        .padding(12)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    private var startExportButton: some View {
        Button {
            startExport()
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Start Export")
            }
            .frame(minWidth: 150)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!configViewModel.isValid || appState.figmaAuth == nil)
        .padding(.top, 16)
    }

    private func startExport() {
        guard let figmaAuth = appState.figmaAuth else {
            viewModel.state = .failed("Not authenticated")
            return
        }

        Task {
            do {
                let params = try configViewModel.buildParams(outputDirectory: configViewModel.outputDirectory)
                let enabledAssets = getEnabledAssetTypes()

                await viewModel.startExport(
                    params: params,
                    platforms: configViewModel.platforms,
                    selectedAssets: enabledAssets,
                    figmaAuth: figmaAuth
                )
            } catch {
                viewModel.state = .failed(error.localizedDescription)
            }
        }
    }

    private func getEnabledAssetTypes() -> Set<AssetType> {
        var types: Set<AssetType> = []
        for platform in configViewModel.enabledPlatforms {
            if platform.colorsEnabled { types.insert(.colors) }
            if platform.iconsEnabled { types.insert(.icons) }
            if platform.imagesEnabled { types.insert(.images) }
            if platform.typographyEnabled { types.insert(.typography) }
        }
        return types
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

#Preview("Idle State") {
    ExportProgressView(appState: {
        let state = AppState()
        state.isAuthenticated = true
        state.configViewModel.fileKey = "abc123"
        state.configViewModel.platforms[0].isEnabled = true // iOS
        return state
    }())
        .frame(width: 900, height: 500)
}

#Preview("Exporting") {
    ExportProgressView(appState: {
        let state = AppState()
        state.isAuthenticated = true
        state.exportViewModel.phases = [
            ExportPhase(name: "Export iOS", status: .completed, progress: 1.0, message: "Completed"),
            ExportPhase(name: "Export Android", status: .inProgress, progress: 0.6, message: "Downloading icons..."),
            ExportPhase(name: "Export Flutter", status: .pending, progress: 0, message: "Waiting..."),
        ]
        state.exportViewModel.logs = [
            ExportLogEntry(timestamp: Date(), level: .info, message: "Starting export..."),
            ExportLogEntry(timestamp: Date(), level: .success, message: "iOS export completed"),
            ExportLogEntry(timestamp: Date(), level: .info, message: "Starting Android export..."),
        ]
        state.exportViewModel.state = .exporting
        state.exportViewModel.overallProgress = 0.5
        state.exportViewModel.currentPhaseName = "Export Android"
        return state
    }())
        .frame(width: 900, height: 500)
}
