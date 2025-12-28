import SwiftUI

// MARK: - Project Browser View

/// View for browsing and selecting Figma files.
struct ProjectBrowserView: View {
    @Bindable var viewModel: ProjectViewModel

    @State private var fileURLInput: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .navigationTitle("Project Browser")
        .task {
            viewModel.loadRecentFiles()
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $viewModel.selectedItem) {
            // Open file section
            Section("Open File") {
                HStack {
                    TextField("Figma file URL or key", text: $fileURLInput)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        Task {
                            await openFile()
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                        }
                    }
                    .buttonStyle(.borderless)
                    .disabled(fileURLInput.isEmpty || isLoading)
                }
            }

            // Recent files section
            if !viewModel.recentFiles.isEmpty {
                Section("Recent Files") {
                    ForEach(viewModel.recentFiles) { item in
                        RecentFileRow(item: item)
                            .tag(item)
                            .contextMenu {
                                Button("Remove from Recent") {
                                    viewModel.removeFromRecentFiles(item)
                                }
                            }
                    }
                }
            }

            // Search results
            if !viewModel.searchText.isEmpty {
                Section("Search Results") {
                    if viewModel.filteredProjects.isEmpty {
                        Text("No files found")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.filteredProjects) { item in
                            RecentFileRow(item: item)
                                .tag(item)
                        }
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search files")
        .frame(minWidth: 250)
    }

    // MARK: - Detail View

    @ViewBuilder
    private var detailView: some View {
        if let selected = viewModel.selectedItem {
            FileDetailView(item: selected)
        } else {
            ContentUnavailableView {
                Label("No File Selected", systemImage: "doc.text")
            } description: {
                Text("Enter a Figma file URL or select from recent files")
            }
        }
    }

    // MARK: - Actions

    private func openFile() async {
        guard !fileURLInput.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await viewModel.openFile(from: fileURLInput)
            fileURLInput = ""
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Recent File Row

struct RecentFileRow: View {
    let item: ProjectItem

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            Group {
                if let thumbnailURL = item.thumbnailURL {
                    AsyncImage(url: thumbnailURL) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            placeholderImage
                        case .empty:
                            ProgressView()
                                .controlSize(.small)
                        @unknown default:
                            placeholderImage
                        }
                    }
                } else {
                    placeholderImage
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .lineLimit(1)

                if let lastModified = item.lastModified {
                    Text(lastModified, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var placeholderImage: some View {
        Image(systemName: "doc.richtext")
            .font(.title2)
            .foregroundStyle(.secondary)
            .frame(width: 32, height: 32)
            .background(.quaternary)
    }
}

// MARK: - File Detail View

struct FileDetailView: View {
    let item: ProjectItem

    var body: some View {
        VStack(spacing: 20) {
            // Thumbnail
            Group {
                if let thumbnailURL = item.thumbnailURL {
                    AsyncImage(url: thumbnailURL) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure:
                            placeholderImage
                        case .empty:
                            ProgressView()
                        @unknown default:
                            placeholderImage
                        }
                    }
                } else {
                    placeholderImage
                }
            }
            .frame(maxWidth: 400, maxHeight: 300)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // File info
            VStack(spacing: 8) {
                Text(item.name)
                    .font(.title2)
                    .fontWeight(.semibold)

                if let fileKey = item.fileKey {
                    Text("File Key: \(fileKey)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                if let lastModified = item.lastModified {
                    Text("Last modified: \(lastModified, format: .dateTime)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Actions
            HStack(spacing: 16) {
                Button {
                    if let fileKey = item.fileKey {
                        // swiftlint:disable:next force_unwrapping
                        let url = URL(string: "https://www.figma.com/file/\(fileKey)")!
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("Open in Figma", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.bordered)

                Button {
                    // TODO: Navigate to asset browser
                } label: {
                    Label("Browse Assets", systemImage: "square.grid.2x2")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var placeholderImage: some View {
        Image(systemName: "doc.richtext")
            .font(.system(size: 64))
            .foregroundStyle(.secondary)
            .frame(width: 200, height: 150)
            .background(.quaternary)
    }
}

// MARK: - Preview

#Preview {
    ProjectBrowserView(viewModel: ProjectViewModel())
}
