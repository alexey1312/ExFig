import Foundation
import Testing

@testable import ExFigStudio

@Suite("ProjectViewModel Tests")
@MainActor
struct ProjectViewModelTests {
    // MARK: - Initialization Tests

    @Test("Initial state is idle with empty projects")
    func initialState() {
        let viewModel = ProjectViewModel()

        #expect(viewModel.state == .idle)
        #expect(viewModel.projects.isEmpty)
        #expect(viewModel.selectedItem == nil)
        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.recentFiles.isEmpty)
    }

    // MARK: - Filtering Tests

    @Test("Filtered projects returns all when search is empty")
    func filteredProjectsNoSearch() {
        let viewModel = ProjectViewModel()
        viewModel.projects = [
            ProjectItem(
                id: "1",
                name: "Design System",
                type: .file(fileKey: "abc"),
                lastModified: nil,
                thumbnailURL: nil
            ),
            ProjectItem(
                id: "2",
                name: "Icons",
                type: .file(fileKey: "def"),
                lastModified: nil,
                thumbnailURL: nil
            ),
        ]

        #expect(viewModel.filteredProjects.count == 2)
    }

    @Test("Filtered projects filters by name")
    func filteredProjectsWithSearch() {
        let viewModel = ProjectViewModel()
        viewModel.projects = [
            ProjectItem(
                id: "1",
                name: "Design System",
                type: .file(fileKey: "abc"),
                lastModified: nil,
                thumbnailURL: nil
            ),
            ProjectItem(
                id: "2",
                name: "Icons",
                type: .file(fileKey: "def"),
                lastModified: nil,
                thumbnailURL: nil
            ),
        ]

        viewModel.searchText = "Design"

        #expect(viewModel.filteredProjects.count == 1)
        #expect(viewModel.filteredProjects.first?.name == "Design System")
    }

    @Test("Search is case insensitive")
    func caseInsensitiveSearch() {
        let viewModel = ProjectViewModel()
        viewModel.projects = [
            ProjectItem(
                id: "1",
                name: "Design System",
                type: .file(fileKey: "abc"),
                lastModified: nil,
                thumbnailURL: nil
            ),
        ]

        viewModel.searchText = "design"

        #expect(viewModel.filteredProjects.count == 1)
    }

    // MARK: - Recent Files Tests

    @Test("Add to recent files adds at beginning")
    func addToRecentFilesOrder() {
        let viewModel = ProjectViewModel()

        let item1 = ProjectItem(
            id: "1",
            name: "First",
            type: .file(fileKey: "abc"),
            lastModified: nil,
            thumbnailURL: nil
        )
        let item2 = ProjectItem(
            id: "2",
            name: "Second",
            type: .file(fileKey: "def"),
            lastModified: nil,
            thumbnailURL: nil
        )

        viewModel.addToRecentFiles(item1)
        viewModel.addToRecentFiles(item2)

        #expect(viewModel.recentFiles.count == 2)
        #expect(viewModel.recentFiles.first?.name == "Second")
    }

    @Test("Add to recent files removes duplicates")
    func addToRecentFilesNoDuplicates() {
        let viewModel = ProjectViewModel()

        let item = ProjectItem(
            id: "1",
            name: "Test",
            type: .file(fileKey: "abc"),
            lastModified: nil,
            thumbnailURL: nil
        )

        viewModel.addToRecentFiles(item)
        viewModel.addToRecentFiles(item)

        #expect(viewModel.recentFiles.count == 1)
    }

    @Test("Add to recent files limits to 10")
    func addToRecentFilesLimit() {
        let viewModel = ProjectViewModel()

        for i in 1 ... 15 {
            let item = ProjectItem(
                id: "\(i)",
                name: "File \(i)",
                type: .file(fileKey: "key\(i)"),
                lastModified: nil,
                thumbnailURL: nil
            )
            viewModel.addToRecentFiles(item)
        }

        #expect(viewModel.recentFiles.count == 10)
        #expect(viewModel.recentFiles.first?.name == "File 15")
    }

    @Test("Remove from recent files works")
    func removeFromRecentFiles() {
        let viewModel = ProjectViewModel()

        let item = ProjectItem(
            id: "1",
            name: "Test",
            type: .file(fileKey: "abc"),
            lastModified: nil,
            thumbnailURL: nil
        )

        viewModel.addToRecentFiles(item)
        #expect(viewModel.recentFiles.count == 1)

        viewModel.removeFromRecentFiles(item)
        #expect(viewModel.recentFiles.isEmpty)
    }

    @Test("Folder items are not added to recent files")
    func folderNotAddedToRecent() {
        let viewModel = ProjectViewModel()

        let folder = ProjectItem(
            id: "1",
            name: "Folder",
            type: .folder(projectId: "proj123"),
            lastModified: nil,
            thumbnailURL: nil
        )

        viewModel.addToRecentFiles(folder)

        #expect(viewModel.recentFiles.isEmpty)
    }
}

// MARK: - ProjectItem Tests

@Suite("ProjectItem Tests")
struct ProjectItemTests {
    @Test("File item has file key")
    func fileItemHasKey() {
        let item = ProjectItem(
            id: "1",
            name: "Test",
            type: .file(fileKey: "abc123"),
            lastModified: nil,
            thumbnailURL: nil
        )

        #expect(item.isFile)
        #expect(item.fileKey == "abc123")
    }

    @Test("Folder item has no file key")
    func folderItemNoKey() {
        let item = ProjectItem(
            id: "1",
            name: "Test",
            type: .folder(projectId: "proj123"),
            lastModified: nil,
            thumbnailURL: nil
        )

        #expect(!item.isFile)
        #expect(item.fileKey == nil)
    }

    @Test("ProjectItem is Hashable")
    func itemIsHashable() {
        let item1 = ProjectItem(
            id: "1",
            name: "Test",
            type: .file(fileKey: "abc"),
            lastModified: nil,
            thumbnailURL: nil
        )
        let item2 = ProjectItem(
            id: "1",
            name: "Test",
            type: .file(fileKey: "abc"),
            lastModified: nil,
            thumbnailURL: nil
        )

        #expect(item1 == item2)
        #expect(item1.hashValue == item2.hashValue)
    }
}

// MARK: - ProjectBrowserState Tests

@Suite("ProjectBrowserState Tests")
struct ProjectBrowserStateTests {
    @Test("States are equatable")
    func statesEquatable() {
        #expect(ProjectBrowserState.idle == ProjectBrowserState.idle)
        #expect(ProjectBrowserState.loading == ProjectBrowserState.loading)
        #expect(ProjectBrowserState.loaded == ProjectBrowserState.loaded)
        #expect(ProjectBrowserState.error("Error 1") == ProjectBrowserState.error("Error 1"))
        #expect(ProjectBrowserState.error("Error 1") != ProjectBrowserState.error("Error 2"))
    }
}

// MARK: - ProjectError Tests

@Suite("ProjectError Tests")
struct ProjectErrorTests {
    @Test("Errors have descriptions")
    func errorDescriptions() {
        #expect(ProjectError.notAuthenticated.errorDescription?.isEmpty == false)
        #expect(ProjectError.fileNotFound.errorDescription?.isEmpty == false)
        #expect(ProjectError.invalidURL.errorDescription?.isEmpty == false)
    }
}
