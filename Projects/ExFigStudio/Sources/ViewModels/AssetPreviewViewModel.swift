import FigmaAPI
import Foundation
import SwiftUI

// MARK: - Asset Type

/// Type of asset in Figma.
enum AssetType: String, CaseIterable, Identifiable {
    case icons = "Icons"
    case images = "Images"
    case colors = "Colors"
    case typography = "Typography"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .icons: "square.on.circle"
        case .images: "photo"
        case .colors: "paintpalette"
        case .typography: "textformat"
        }
    }
}

// MARK: - Asset Item

/// Represents a single asset in the preview grid.
struct AssetItem: Identifiable, Hashable, Sendable {
    let id: String
    let nodeId: String
    let name: String
    let type: AssetType
    let thumbnailURL: URL?
    var isSelected: Bool

    init(
        id: String = UUID().uuidString,
        nodeId: String,
        name: String,
        type: AssetType,
        thumbnailURL: URL? = nil,
        isSelected: Bool = true
    ) {
        self.id = id
        self.nodeId = nodeId
        self.name = name
        self.type = type
        self.thumbnailURL = thumbnailURL
        self.isSelected = isSelected
    }
}

// MARK: - Asset Preview State

/// Loading state for asset preview.
enum AssetPreviewState: Equatable {
    case idle
    case loading(progress: Double)
    case loaded(count: Int)
    case error(String)
}

// MARK: - Asset Preview View Model

/// View model for the asset preview grid.
@MainActor
@Observable
final class AssetPreviewViewModel {
    // MARK: - State

    var state: AssetPreviewState = .idle
    var assets: [AssetItem] = []
    var selectedAssetType: AssetType = .icons
    var searchText: String = ""

    // Selection state
    var selectAll: Bool = true {
        didSet {
            if selectAll != oldValue {
                for i in assets.indices {
                    assets[i].isSelected = selectAll
                }
            }
        }
    }

    // MARK: - Dependencies

    private var client: Client?
    private var fileKey: String?

    // Thumbnail cache
    private var thumbnailCache = NSCache<NSString, NSImage>()

    // MARK: - Computed Properties

    var filteredAssets: [AssetItem] {
        var result = assets.filter { $0.type == selectedAssetType }

        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var selectedCount: Int {
        assets.filter(\.isSelected).count
    }

    var totalCount: Int {
        assets.count
    }

    var assetsByType: [AssetType: [AssetItem]] {
        Dictionary(grouping: assets, by: \.type)
    }

    // MARK: - Configuration

    func configure(with auth: FigmaAuth, fileKey: String) {
        client = auth.makeClient()
        self.fileKey = fileKey
    }

    // MARK: - Loading

    /// Load assets from the Figma file.
    func loadAssets() async {
        guard let client, let fileKey else {
            state = .error("Not configured - please select a file first")
            return
        }

        state = .loading(progress: 0)
        assets = []

        do {
            // Fetch file metadata to get top-level structure
            let endpoint = FileMetadataEndpoint(fileId: fileKey)
            _ = try await client.request(endpoint)

            state = .loading(progress: 0.3)

            // For now, create placeholder assets since we need the full file structure
            // In production, we would use ComponentsEndpoint or StylesEndpoint
            // to get the actual components and styles from the file

            // Placeholder demonstration
            let placeholderAssets: [AssetItem] = [
                AssetItem(nodeId: "1:1", name: "ic_home", type: .icons),
                AssetItem(nodeId: "1:2", name: "ic_settings", type: .icons),
                AssetItem(nodeId: "1:3", name: "ic_profile", type: .icons),
                AssetItem(nodeId: "2:1", name: "illustration_welcome", type: .images),
                AssetItem(nodeId: "2:2", name: "illustration_empty", type: .images),
                AssetItem(nodeId: "3:1", name: "Primary", type: .colors),
                AssetItem(nodeId: "3:2", name: "Secondary", type: .colors),
                AssetItem(nodeId: "4:1", name: "Heading 1", type: .typography),
                AssetItem(nodeId: "4:2", name: "Body", type: .typography),
            ]

            state = .loading(progress: 0.6)

            // Load thumbnails for icons
            let iconNodeIds = placeholderAssets
                .filter { $0.type == .icons }
                .map(\.nodeId)

            if !iconNodeIds.isEmpty {
                await loadThumbnails(for: iconNodeIds, fileKey: fileKey)
            }

            assets = placeholderAssets
            state = .loaded(count: placeholderAssets.count)

        } catch {
            state = .error("Failed to load assets: \(error.localizedDescription)")
        }
    }

    /// Categorize a document based on its name and properties.
    private func categorizeDocument(_ doc: Document) -> AssetType {
        let name = doc.name.lowercased()

        // Simple heuristics for categorization
        if name.contains("icon") || name.hasPrefix("ic_") || name.hasSuffix("_icon") {
            return .icons
        } else if name.contains("image") || name.contains("illustration") || name.contains("photo") {
            return .images
        } else if name.contains("color") || name.contains("fill") || name.contains("palette") {
            return .colors
        } else if name.contains("text") || name.contains("font") || name.contains("typography") {
            return .typography
        }

        // Default to icons for components
        return .icons
    }

    /// Load thumbnails for a batch of nodes.
    private func loadThumbnails(for nodeIds: [String], fileKey: String) async {
        guard let client, !nodeIds.isEmpty else { return }

        do {
            let endpoint = ImageEndpoint(
                fileId: fileKey,
                nodeIds: nodeIds,
                params: PNGParams(scale: 0.5)
            )
            let response = try await client.request(endpoint)

            // Update assets with thumbnail URLs
            for (nodeId, urlString) in response {
                if let urlString,
                   let url = URL(string: urlString),
                   let index = assets.firstIndex(where: { $0.nodeId == nodeId })
                {
                    assets[index] = AssetItem(
                        id: assets[index].id,
                        nodeId: nodeId,
                        name: assets[index].name,
                        type: assets[index].type,
                        thumbnailURL: url,
                        isSelected: assets[index].isSelected
                    )
                }
            }
        } catch {
            // Ignore thumbnail loading errors
        }
    }

    // MARK: - Selection

    /// Toggle selection for an asset.
    func toggleSelection(for asset: AssetItem) {
        if let index = assets.firstIndex(where: { $0.id == asset.id }) {
            assets[index].isSelected.toggle()
            updateSelectAllState()
        }
    }

    /// Select all visible assets.
    func selectAllVisible() {
        for asset in filteredAssets {
            if let index = assets.firstIndex(where: { $0.id == asset.id }) {
                assets[index].isSelected = true
            }
        }
        updateSelectAllState()
    }

    /// Deselect all visible assets.
    func deselectAllVisible() {
        for asset in filteredAssets {
            if let index = assets.firstIndex(where: { $0.id == asset.id }) {
                assets[index].isSelected = false
            }
        }
        updateSelectAllState()
    }

    private func updateSelectAllState() {
        selectAll = assets.allSatisfy(\.isSelected)
    }

    // MARK: - Export

    /// Get all selected assets for export.
    func selectedAssets() -> [AssetItem] {
        assets.filter(\.isSelected)
    }
}
