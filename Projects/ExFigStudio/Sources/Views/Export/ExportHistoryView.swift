import SwiftUI

// MARK: - Export History View

/// View showing export history with filtering and quick re-run.
struct ExportHistoryView: View {
    @Bindable var viewModel: ExportHistoryViewModel

    @State private var showClearConfirmation = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .navigationTitle("Export History")
        .searchable(text: $viewModel.searchText, prompt: "Search exports")
        .toolbar {
            ToolbarItemGroup {
                // Filter menu
                Menu {
                    Button("All") {
                        viewModel.filterStatus = nil
                    }
                    Divider()
                    ForEach(
                        [ExportHistoryEntry.Status.success, .partialSuccess, .failed, .cancelled],
                        id: \.self
                    ) { status in
                        Button {
                            viewModel.filterStatus = status
                        } label: {
                            Label(status.label, systemImage: status.icon)
                        }
                    }
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }

                // Clear history
                Button {
                    showClearConfirmation = true
                } label: {
                    Label("Clear History", systemImage: "trash")
                }
                .disabled(viewModel.entries.isEmpty)
            }
        }
        .task {
            viewModel.loadHistory()
        }
        .confirmationDialog(
            "Clear Export History?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) {
                viewModel.clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all export history entries.")
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        Group {
            if viewModel.entries.isEmpty {
                emptyStateView
            } else if viewModel.filteredEntries.isEmpty {
                noResultsView
            } else {
                historyListView
            }
        }
        .frame(minWidth: 300)
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Export History", systemImage: "clock.arrow.circlepath")
        } description: {
            Text("Completed exports will appear here")
        }
    }

    private var noResultsView: some View {
        ContentUnavailableView {
            Label("No Results", systemImage: "magnifyingglass")
        } description: {
            Text("No exports match your search")
        }
    }

    private var historyListView: some View {
        List(selection: $viewModel.selectedEntry) {
            ForEach(viewModel.groupedByDate, id: \.date) { group in
                historySection(for: group)
            }
        }
        .listStyle(.sidebar)
    }

    private func historySection(for group: (date: Date, entries: [ExportHistoryEntry])) -> some View {
        Section(header: Text(group.date, format: .dateTime.month().day().year())) {
            ForEach(group.entries) { entry in
                historyRowWithContext(entry: entry)
            }
        }
    }

    private func historyRowWithContext(entry: ExportHistoryEntry) -> some View {
        HistoryRow(entry: entry)
            .tag(entry)
            .contextMenu {
                Button {
                    Task {
                        await viewModel.rerunExport(entry)
                    }
                } label: {
                    Label("Re-run Export", systemImage: "arrow.clockwise")
                }

                Divider()

                Button(role: .destructive) {
                    viewModel.removeEntry(entry)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }

    // MARK: - Detail View

    @ViewBuilder
    private var detailView: some View {
        if let entry = viewModel.selectedEntry {
            HistoryDetailView(entry: entry) {
                Task {
                    await viewModel.rerunExport(entry)
                }
            }
        } else {
            ContentUnavailableView {
                Label("Select an Export", systemImage: "sidebar.left")
            } description: {
                Text("Choose an export from the sidebar to view details")
            }
        }
    }
}

// MARK: - History Row

struct HistoryRow: View {
    let entry: ExportHistoryEntry

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Image(systemName: entry.status.icon)
                .foregroundStyle(entry.status.color)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.fileName)
                    .font(.body)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(entry.platforms.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text("\(entry.assetCounts.total) assets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Time
            Text(entry.timestamp, format: .dateTime.hour().minute())
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - History Detail View

struct HistoryDetailView: View {
    let entry: ExportHistoryEntry
    let onRerun: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.fileName)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(entry.timestamp, format: .dateTime)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Status badge
                    HStack(spacing: 4) {
                        Image(systemName: entry.status.icon)
                        Text(entry.status.label)
                    }
                    .foregroundStyle(entry.status.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(entry.status.color.opacity(0.1), in: Capsule())
                }

                Divider()

                // Stats
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 16) {
                    StatCard(title: "Colors", value: "\(entry.assetCounts.colors)", icon: "paintpalette")
                    StatCard(title: "Icons", value: "\(entry.assetCounts.icons)", icon: "square.on.circle")
                    StatCard(title: "Images", value: "\(entry.assetCounts.images)", icon: "photo")
                    StatCard(title: "Typography", value: "\(entry.assetCounts.typography)", icon: "textformat")
                }

                // Details
                GroupBox("Details") {
                    VStack(alignment: .leading, spacing: 8) {
                        DetailRow(label: "File Key", value: entry.fileKey)
                        DetailRow(label: "Platforms", value: entry.platforms.joined(separator: ", "))
                        DetailRow(label: "Duration", value: formatDuration(entry.duration))

                        if let configPath = entry.configPath {
                            DetailRow(label: "Config", value: configPath)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Actions
                HStack(spacing: 16) {
                    Button {
                        if let url = URL(string: "https://www.figma.com/file/\(entry.fileKey)") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Label("Open in Figma", systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        onRerun()
                    } label: {
                        Label("Re-run Export", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return String(format: "%.1fs", duration)
        } else {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return "\(minutes)m \(seconds)s"
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .textSelection(.enabled)
        }
        .font(.callout)
    }
}

// MARK: - Preview

#Preview {
    ExportHistoryView(viewModel: {
        let vm = ExportHistoryViewModel()
        vm.entries = [
            ExportHistoryEntry(
                fileName: "Design System",
                fileKey: "abc123",
                platforms: ["iOS", "Android"],
                assetCounts: .init(colors: 24, icons: 156, images: 12, typography: 8),
                duration: 45.2,
                status: .success
            ),
            ExportHistoryEntry(
                timestamp: Date().addingTimeInterval(-3600),
                fileName: "App Icons",
                fileKey: "def456",
                platforms: ["iOS"],
                assetCounts: .init(colors: 0, icons: 32, images: 0, typography: 0),
                duration: 12.8,
                status: .success
            ),
            ExportHistoryEntry(
                timestamp: Date().addingTimeInterval(-86400),
                fileName: "Marketing Assets",
                fileKey: "ghi789",
                platforms: ["Web"],
                assetCounts: .init(colors: 8, icons: 0, images: 24, typography: 0),
                duration: 30.5,
                status: .partialSuccess
            ),
        ]
        return vm
    }())
        .frame(width: 900, height: 600)
}
