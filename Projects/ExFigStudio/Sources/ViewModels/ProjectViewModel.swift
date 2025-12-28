import FigmaAPI
import Foundation
import SwiftUI

// MARK: - Project Item

/// Represents a Figma file or folder in the project browser.
struct ProjectItem: Identifiable, Hashable {
    let id: String
    let name: String
    let type: ItemType
    let lastModified: Date?
    let thumbnailURL: URL?

    enum ItemType: Hashable {
        case file(fileKey: String)
        case folder(projectId: String)
    }

    var isFile: Bool {
        if case .file = type { return true }
        return false
    }

    var fileKey: String? {
        if case let .file(key) = type { return key }
        return nil
    }
}

// MARK: - Project Browser State

/// Loading state for the project browser.
enum ProjectBrowserState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}

// MARK: - Project View Model

/// View model for the project browser.
@MainActor
@Observable
final class ProjectViewModel {
    // MARK: - State

    var state: ProjectBrowserState = .idle
    var projects: [ProjectItem] = []
    var selectedItem: ProjectItem?
    var searchText: String = ""

    // Recent files (stored in UserDefaults)
    var recentFiles: [ProjectItem] = []

    // MARK: - Dependencies

    private var client: Client?

    // MARK: - Computed Properties

    var filteredProjects: [ProjectItem] {
        guard !searchText.isEmpty else {
            return projects
        }
        return projects.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Configuration

    func configure(with auth: FigmaAuth) {
        client = auth.makeClient()
    }

    // MARK: - Loading

    /// Load recent files from storage.
    func loadRecentFiles() {
        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "recentFigmaFiles"),
           let decoded = try? JSONDecoder().decode([RecentFile].self, from: data)
        {
            recentFiles = decoded.map { file in
                ProjectItem(
                    id: file.fileKey,
                    name: file.name,
                    type: .file(fileKey: file.fileKey),
                    lastModified: file.lastAccessed,
                    thumbnailURL: file.thumbnailURL
                )
            }
        }
    }

    /// Add a file to recent files.
    func addToRecentFiles(_ item: ProjectItem) {
        guard let fileKey = item.fileKey else { return }

        // Remove if already exists
        recentFiles.removeAll { $0.id == item.id }

        // Insert at beginning
        recentFiles.insert(item, at: 0)

        // Keep only last 10
        if recentFiles.count > 10 {
            recentFiles = Array(recentFiles.prefix(10))
        }

        // Save to UserDefaults
        let toSave = recentFiles.compactMap { item -> RecentFile? in
            guard let key = item.fileKey else { return nil }
            return RecentFile(
                fileKey: key,
                name: item.name,
                lastAccessed: Date(),
                thumbnailURL: item.thumbnailURL
            )
        }

        if let encoded = try? JSONEncoder().encode(toSave) {
            UserDefaults.standard.set(encoded, forKey: "recentFigmaFiles")
        }
    }

    /// Open a Figma file by URL or file key.
    func openFile(from input: String) async throws -> ProjectItem {
        // Extract file key from URL or use directly
        let fileKey = extractFileKey(from: input)

        state = .loading

        do {
            // Fetch file metadata using existing FigmaAPI endpoint
            guard let client else {
                throw ProjectError.notAuthenticated
            }

            let endpoint = FileMetadataEndpoint(fileId: fileKey)
            let response = try await client.request(endpoint)

            // Parse lastModified string to Date
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let lastModified = formatter.date(from: response.lastModified)

            let item = ProjectItem(
                id: fileKey,
                name: response.name,
                type: .file(fileKey: fileKey),
                lastModified: lastModified,
                thumbnailURL: response.thumbnailUrl.flatMap { URL(string: $0) }
            )

            addToRecentFiles(item)
            selectedItem = item
            state = .loaded

            return item
        } catch {
            state = .error("Failed to open file: \(error.localizedDescription)")
            throw error
        }
    }

    /// Extract file key from Figma URL.
    private func extractFileKey(from input: String) -> String {
        // Try to parse as URL first
        if let url = URL(string: input),
           let pathComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)?.path
           .split(separator: "/")
        {
            // Figma URLs: https://www.figma.com/file/{key}/...
            // or https://www.figma.com/design/{key}/...
            if let index = pathComponents.firstIndex(where: { $0 == "file" || $0 == "design" }),
               pathComponents.count > index + 1
            {
                return String(pathComponents[index + 1])
            }
        }

        // Assume it's already a file key
        return input
    }

    /// Remove a file from recent files.
    func removeFromRecentFiles(_ item: ProjectItem) {
        recentFiles.removeAll { $0.id == item.id }

        // Update UserDefaults
        let toSave = recentFiles.compactMap { item -> RecentFile? in
            guard let key = item.fileKey else { return nil }
            return RecentFile(
                fileKey: key,
                name: item.name,
                lastAccessed: Date(),
                thumbnailURL: item.thumbnailURL
            )
        }

        if let encoded = try? JSONEncoder().encode(toSave) {
            UserDefaults.standard.set(encoded, forKey: "recentFigmaFiles")
        }
    }
}

// MARK: - Recent File Storage

private struct RecentFile: Codable {
    let fileKey: String
    let name: String
    let lastAccessed: Date
    let thumbnailURL: URL?
}

// MARK: - Project Errors

enum ProjectError: Error, LocalizedError {
    case notAuthenticated
    case fileNotFound
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            "Not authenticated - please sign in first"
        case .fileNotFound:
            "File not found"
        case .invalidURL:
            "Invalid Figma URL or file key"
        }
    }
}
