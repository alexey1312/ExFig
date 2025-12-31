import SwiftUI

// MARK: - Asset Preview Grid

/// Grid view for previewing and selecting assets.
struct AssetPreviewGrid: View {
    @Bindable var viewModel: AssetPreviewViewModel

    @State private var gridColumns = 4

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar
                .padding()
                .background(.bar)

            Divider()

            // Content
            contentView
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 16) {
            // Asset type filter
            Picker("Asset Type", selection: $viewModel.selectedAssetType) {
                ForEach(AssetType.allCases) { type in
                    Label(type.rawValue, systemImage: type.systemImage)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 400)

            Spacer()

            // Selection controls
            HStack(spacing: 8) {
                Text("\(viewModel.selectedCount)/\(viewModel.totalCount) selected")
                    .foregroundStyle(.secondary)
                    .font(.callout)

                Button("Select All") {
                    viewModel.selectAllVisible()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Deselect All") {
                    viewModel.deselectAllVisible()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Divider()
                .frame(height: 20)

            // Grid size control
            HStack(spacing: 4) {
                Image(systemName: "square.grid.2x2")
                    .foregroundStyle(.secondary)

                Slider(value: Binding(
                    get: { Double(gridColumns) },
                    set: { gridColumns = Int($0) }
                ), in: 2 ... 8, step: 1)
                    .frame(width: 80)
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView {
                Label("No Assets", systemImage: "photo.on.rectangle.angled")
            } description: {
                Text("Select a Figma file to load assets")
            }

        case let .loading(progress):
            VStack(spacing: 16) {
                ProgressView(value: progress)
                    .frame(width: 200)
                Text("Loading assets...")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded:
            if viewModel.filteredAssets.isEmpty {
                ContentUnavailableView {
                    Label(
                        "No \(viewModel.selectedAssetType.rawValue)",
                        systemImage: viewModel.selectedAssetType.systemImage
                    )
                } description: {
                    if viewModel.searchText.isEmpty {
                        Text("No \(viewModel.selectedAssetType.rawValue.lowercased()) found in this file")
                    } else {
                        Text("No results for \"\(viewModel.searchText)\"")
                    }
                }
            } else {
                assetGrid
            }

        case let .error(message):
            ContentUnavailableView {
                Label("Error", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") {
                    Task {
                        await viewModel.loadAssets()
                    }
                }
            }
        }
    }

    // MARK: - Asset Grid

    private var assetGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: gridColumns),
                spacing: 12
            ) {
                ForEach(viewModel.filteredAssets) { asset in
                    AssetGridItem(asset: asset) {
                        viewModel.toggleSelection(for: asset)
                    }
                }
            }
            .padding()
        }
        .searchable(text: $viewModel.searchText, prompt: "Search \(viewModel.selectedAssetType.rawValue.lowercased())")
    }
}

// MARK: - Asset Grid Item

struct AssetGridItem: View {
    let asset: AssetItem
    let onToggle: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 8) {
            // Thumbnail
            ZStack(alignment: .topTrailing) {
                thumbnailView
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Selection indicator
                if asset.isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white, .blue)
                        .padding(6)
                }
            }

            // Name
            Text(asset.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 32)
        }
        .padding(8)
        .background(asset.isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(asset.isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onTapGesture(perform: onToggle)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let url = asset.thumbnailURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    placeholderView
                case .empty:
                    ProgressView()
                        .controlSize(.small)
                @unknown default:
                    placeholderView
                }
            }
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        Image(systemName: asset.type.systemImage)
            .font(.largeTitle)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Preview

#Preview {
    AssetPreviewGrid(viewModel: {
        let vm = AssetPreviewViewModel()
        // Add sample assets
        vm.assets = [
            AssetItem(nodeId: "1", name: "Icon Home", type: .icons),
            AssetItem(nodeId: "2", name: "Icon Settings", type: .icons),
            AssetItem(nodeId: "3", name: "Icon Profile", type: .icons),
            AssetItem(nodeId: "4", name: "Hero Image", type: .images),
            AssetItem(nodeId: "5", name: "Primary Color", type: .colors),
        ]
        vm.state = .loaded(count: 5)
        return vm
    }())
        .frame(width: 800, height: 600)
}
