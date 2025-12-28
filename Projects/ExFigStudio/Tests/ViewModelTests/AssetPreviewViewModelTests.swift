import Foundation
import Testing

@testable import ExFigStudio

@Suite("AssetPreviewViewModel Tests")
@MainActor
struct AssetPreviewViewModelTests {
    // MARK: - Helper

    private func makeAssets() -> [AssetItem] {
        [
            AssetItem(nodeId: "1:1", name: "ic_home", type: .icons, isSelected: true),
            AssetItem(nodeId: "1:2", name: "ic_settings", type: .icons, isSelected: true),
            AssetItem(nodeId: "2:1", name: "illustration_welcome", type: .images, isSelected: true),
            AssetItem(nodeId: "3:1", name: "Primary", type: .colors, isSelected: true),
            AssetItem(nodeId: "4:1", name: "Heading 1", type: .typography, isSelected: true),
        ]
    }

    // MARK: - Initialization Tests

    @Test("Initial state is idle")
    func initialState() {
        let viewModel = AssetPreviewViewModel()

        #expect(viewModel.state == .idle)
        #expect(viewModel.assets.isEmpty)
        #expect(viewModel.selectedAssetType == .icons)
        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.selectAll)
    }

    // MARK: - Filtering Tests

    @Test("Filtered assets returns only selected type")
    func filteredByType() {
        let viewModel = AssetPreviewViewModel()
        viewModel.assets = makeAssets()
        viewModel.selectedAssetType = .icons

        #expect(viewModel.filteredAssets.count == 2)
        for asset in viewModel.filteredAssets {
            #expect(asset.type == .icons)
        }
    }

    @Test("Filtered assets applies search text")
    func filteredBySearch() {
        let viewModel = AssetPreviewViewModel()
        viewModel.assets = makeAssets()
        viewModel.selectedAssetType = .icons
        viewModel.searchText = "home"

        #expect(viewModel.filteredAssets.count == 1)
        #expect(viewModel.filteredAssets.first?.name == "ic_home")
    }

    @Test("Search is case insensitive")
    func caseInsensitiveSearch() {
        let viewModel = AssetPreviewViewModel()
        viewModel.assets = makeAssets()
        viewModel.selectedAssetType = .icons
        viewModel.searchText = "HOME"

        #expect(viewModel.filteredAssets.count == 1)
    }

    // MARK: - Selection Tests

    @Test("Toggle selection changes asset selection")
    func toggleSelection() {
        let viewModel = AssetPreviewViewModel()
        viewModel.assets = makeAssets()

        let asset = viewModel.assets[0]
        #expect(asset.isSelected)

        viewModel.toggleSelection(for: asset)

        #expect(!viewModel.assets[0].isSelected)
    }

    @Test("Select all visible selects filtered assets")
    func selectAllVisible() {
        let viewModel = AssetPreviewViewModel()
        viewModel.assets = makeAssets()

        // Deselect all icons
        for i in viewModel.assets.indices where viewModel.assets[i].type == .icons {
            viewModel.assets[i].isSelected = false
        }

        viewModel.selectedAssetType = .icons
        viewModel.selectAllVisible()

        let icons = viewModel.assets.filter { $0.type == .icons }
        for icon in icons {
            #expect(icon.isSelected)
        }
    }

    @Test("Deselect all visible deselects filtered assets")
    func deselectAllVisible() {
        let viewModel = AssetPreviewViewModel()
        viewModel.assets = makeAssets()
        viewModel.selectedAssetType = .icons

        viewModel.deselectAllVisible()

        let icons = viewModel.assets.filter { $0.type == .icons }
        for icon in icons {
            #expect(!icon.isSelected)
        }
    }

    @Test("Select all toggle affects all assets")
    func selectAllToggle() {
        let viewModel = AssetPreviewViewModel()
        viewModel.assets = makeAssets()

        viewModel.selectAll = false

        for asset in viewModel.assets {
            #expect(!asset.isSelected)
        }
    }

    // MARK: - Computed Properties Tests

    @Test("Selected count returns correct number")
    func selectedCount() {
        let viewModel = AssetPreviewViewModel()
        viewModel.assets = makeAssets()

        #expect(viewModel.selectedCount == 5)

        viewModel.assets[0].isSelected = false
        viewModel.assets[1].isSelected = false

        #expect(viewModel.selectedCount == 3)
    }

    @Test("Total count returns all assets")
    func totalCount() {
        let viewModel = AssetPreviewViewModel()
        viewModel.assets = makeAssets()

        #expect(viewModel.totalCount == 5)
    }

    @Test("Assets by type groups correctly")
    func assetsByType() {
        let viewModel = AssetPreviewViewModel()
        viewModel.assets = makeAssets()

        let byType = viewModel.assetsByType

        #expect(byType[.icons]?.count == 2)
        #expect(byType[.images]?.count == 1)
        #expect(byType[.colors]?.count == 1)
        #expect(byType[.typography]?.count == 1)
    }

    @Test("Selected assets returns only selected")
    func selectedAssets() {
        let viewModel = AssetPreviewViewModel()
        viewModel.assets = makeAssets()
        viewModel.assets[0].isSelected = false
        viewModel.assets[2].isSelected = false

        let selected = viewModel.selectedAssets()

        #expect(selected.count == 3)
        for asset in selected {
            #expect(asset.isSelected)
        }
    }

    // MARK: - State Tests

    @Test("Loading state not configured without client")
    func loadingWithoutClient() async {
        let viewModel = AssetPreviewViewModel()

        await viewModel.loadAssets()

        if case let .error(message) = viewModel.state {
            #expect(message.contains("Not configured"))
        } else {
            Issue.record("Expected error state when not configured")
        }
    }
}

// MARK: - AssetType Tests

@Suite("AssetType Tests")
struct AssetTypeTests {
    @Test("All asset types have system images")
    func allTypesHaveImages() {
        for type in AssetType.allCases {
            #expect(!type.systemImage.isEmpty)
        }
    }

    @Test("All asset types have unique IDs")
    func uniqueIds() {
        let ids = AssetType.allCases.map(\.id)
        #expect(Set(ids).count == AssetType.allCases.count)
    }
}

// MARK: - AssetItem Tests

@Suite("AssetItem Tests")
struct AssetItemTests {
    @Test("AssetItem is Hashable")
    func itemIsHashable() {
        let item1 = AssetItem(nodeId: "1:1", name: "test", type: .icons)
        let item2 = AssetItem(id: item1.id, nodeId: "1:1", name: "test", type: .icons)

        #expect(item1.hashValue == item2.hashValue)
    }

    @Test("AssetItem defaults to selected")
    func defaultSelected() {
        let item = AssetItem(nodeId: "1:1", name: "test", type: .icons)

        #expect(item.isSelected)
    }

    @Test("AssetItem can have thumbnail URL")
    func thumbnailURL() {
        let url = URL(string: "https://example.com/thumb.png")
        let item = AssetItem(nodeId: "1:1", name: "test", type: .icons, thumbnailURL: url)

        #expect(item.thumbnailURL == url)
    }
}

// MARK: - AssetPreviewState Tests

@Suite("AssetPreviewState Tests")
struct AssetPreviewStateTests {
    @Test("States are equatable")
    func statesEquatable() {
        #expect(AssetPreviewState.idle == AssetPreviewState.idle)
        #expect(AssetPreviewState.loading(progress: 0.5) == AssetPreviewState.loading(progress: 0.5))
        #expect(AssetPreviewState.loaded(count: 10) == AssetPreviewState.loaded(count: 10))
        #expect(AssetPreviewState.error("Error") == AssetPreviewState.error("Error"))

        #expect(AssetPreviewState.loading(progress: 0.5) != AssetPreviewState.loading(progress: 0.7))
        #expect(AssetPreviewState.loaded(count: 10) != AssetPreviewState.loaded(count: 20))
    }
}
