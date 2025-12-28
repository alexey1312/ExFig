import Foundation
import Testing

@testable import ExFigStudio

@Suite("ExportHistoryViewModel Tests")
@MainActor
struct ExportHistoryViewModelTests {
    // MARK: - Helper

    private func makeEntry(
        fileName: String = "Test File",
        fileKey: String = "abc123",
        status: ExportHistoryEntry.Status = .success,
        timestamp: Date = Date()
    ) -> ExportHistoryEntry {
        ExportHistoryEntry(
            timestamp: timestamp,
            fileName: fileName,
            fileKey: fileKey,
            platforms: ["iOS"],
            assetCounts: .init(colors: 10, icons: 20, images: 5, typography: 3),
            duration: 30.0,
            status: status
        )
    }

    // MARK: - Initialization Tests

    @Test("Initial state has empty entries")
    func initialState() {
        let viewModel = ExportHistoryViewModel()

        #expect(viewModel.entries.isEmpty)
        #expect(viewModel.selectedEntry == nil)
        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.filterStatus == nil)
    }

    // MARK: - Add Entry Tests

    @Test("Add entry inserts at beginning")
    func addEntryOrder() {
        let viewModel = ExportHistoryViewModel()

        let entry1 = makeEntry(fileName: "First")
        let entry2 = makeEntry(fileName: "Second")

        viewModel.addEntry(entry1)
        viewModel.addEntry(entry2)

        #expect(viewModel.entries.count == 2)
        #expect(viewModel.entries.first?.fileName == "Second")
    }

    @Test("Add entry trims to max entries")
    func addEntryTrimsToMax() {
        let viewModel = ExportHistoryViewModel()

        // Add more than 100 entries
        for i in 1 ... 110 {
            let entry = makeEntry(fileName: "File \(i)")
            viewModel.addEntry(entry)
        }

        #expect(viewModel.entries.count == 100)
        #expect(viewModel.entries.first?.fileName == "File 110")
    }

    // MARK: - Remove Entry Tests

    @Test("Remove entry removes correct entry")
    func removeEntry() {
        let viewModel = ExportHistoryViewModel()

        let entry1 = makeEntry(fileName: "Keep")
        let entry2 = makeEntry(fileName: "Remove")

        viewModel.addEntry(entry1)
        viewModel.addEntry(entry2)

        viewModel.removeEntry(entry2)

        #expect(viewModel.entries.count == 1)
        #expect(viewModel.entries.first?.fileName == "Keep")
    }

    // MARK: - Clear History Tests

    @Test("Clear history removes all entries")
    func clearHistory() {
        let viewModel = ExportHistoryViewModel()

        viewModel.addEntry(makeEntry())
        viewModel.addEntry(makeEntry())

        viewModel.clearHistory()

        #expect(viewModel.entries.isEmpty)
    }

    // MARK: - Filter Tests

    @Test("Filter by status returns matching entries")
    func filterByStatus() {
        let viewModel = ExportHistoryViewModel()

        viewModel.entries = [
            makeEntry(fileName: "Success 1", status: .success),
            makeEntry(fileName: "Failed 1", status: .failed),
            makeEntry(fileName: "Success 2", status: .success),
        ]

        viewModel.filterStatus = .success

        #expect(viewModel.filteredEntries.count == 2)
        for entry in viewModel.filteredEntries {
            #expect(entry.status == .success)
        }
    }

    @Test("Filter by search text returns matching entries")
    func filterBySearchText() {
        let viewModel = ExportHistoryViewModel()

        viewModel.entries = [
            makeEntry(fileName: "Design System"),
            makeEntry(fileName: "Icons"),
            makeEntry(fileName: "Design Tokens"),
        ]

        viewModel.searchText = "Design"

        #expect(viewModel.filteredEntries.count == 2)
    }

    @Test("Search includes platform names")
    func searchIncludesPlatforms() {
        let viewModel = ExportHistoryViewModel()

        let entry = ExportHistoryEntry(
            fileName: "Test",
            fileKey: "abc",
            platforms: ["Android", "Flutter"],
            assetCounts: .init(colors: 0, icons: 0, images: 0, typography: 0),
            duration: 1.0,
            status: .success
        )

        viewModel.entries = [entry]
        viewModel.searchText = "Android"

        #expect(viewModel.filteredEntries.count == 1)
    }

    @Test("No filter returns all entries")
    func noFilterReturnsAll() {
        let viewModel = ExportHistoryViewModel()

        viewModel.entries = [
            makeEntry(fileName: "File 1"),
            makeEntry(fileName: "File 2"),
            makeEntry(fileName: "File 3"),
        ]

        #expect(viewModel.filteredEntries.count == 3)
    }

    // MARK: - Grouping Tests

    @Test("Grouped by date groups entries correctly")
    func groupedByDate() {
        let viewModel = ExportHistoryViewModel()

        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        viewModel.entries = [
            makeEntry(fileName: "Today 1", timestamp: today),
            makeEntry(fileName: "Today 2", timestamp: today),
            makeEntry(fileName: "Yesterday", timestamp: yesterday),
        ]

        let grouped = viewModel.groupedByDate

        #expect(grouped.count == 2)
    }

    @Test("Grouped by date sorts by date descending")
    func groupedByDateSortOrder() {
        let viewModel = ExportHistoryViewModel()

        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        viewModel.entries = [
            makeEntry(fileName: "Yesterday", timestamp: yesterday),
            makeEntry(fileName: "Today", timestamp: today),
        ]

        let grouped = viewModel.groupedByDate

        #expect(grouped.first?.date == Calendar.current.startOfDay(for: today))
    }

    @Test("Entries within group are sorted by time descending")
    func entriesInGroupSortOrder() {
        let viewModel = ExportHistoryViewModel()

        let earlier = Date()
        let later = earlier.addingTimeInterval(3600)

        viewModel.entries = [
            makeEntry(fileName: "Earlier", timestamp: earlier),
            makeEntry(fileName: "Later", timestamp: later),
        ]

        let grouped = viewModel.groupedByDate
        let entries = grouped.first?.entries ?? []

        #expect(entries.first?.fileName == "Later")
    }
}

// MARK: - ExportHistoryEntry Tests

@Suite("ExportHistoryEntry Tests")
struct ExportHistoryEntryTests {
    @Test("Entry is Identifiable")
    func identifiable() {
        let entry = ExportHistoryEntry(
            fileName: "Test",
            fileKey: "abc",
            platforms: ["iOS"],
            assetCounts: .init(colors: 0, icons: 0, images: 0, typography: 0),
            duration: 1.0,
            status: .success
        )

        #expect(!entry.id.uuidString.isEmpty)
    }

    @Test("Entry is Codable")
    func codable() throws {
        let entry = ExportHistoryEntry(
            fileName: "Test",
            fileKey: "abc",
            platforms: ["iOS", "Android"],
            assetCounts: .init(colors: 10, icons: 20, images: 5, typography: 3),
            duration: 45.5,
            status: .success,
            configPath: "/path/to/config.yaml"
        )

        let encoded = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(ExportHistoryEntry.self, from: encoded)

        #expect(decoded.fileName == entry.fileName)
        #expect(decoded.fileKey == entry.fileKey)
        #expect(decoded.platforms == entry.platforms)
        #expect(decoded.assetCounts.colors == entry.assetCounts.colors)
        #expect(decoded.duration == entry.duration)
        #expect(decoded.status == entry.status)
        #expect(decoded.configPath == entry.configPath)
    }

    @Test("AssetCounts total is sum of all")
    func assetCountsTotal() {
        let counts = ExportHistoryEntry.AssetCounts(
            colors: 10,
            icons: 20,
            images: 5,
            typography: 3
        )

        #expect(counts.total == 38)
    }
}

// MARK: - ExportHistoryEntry.Status Tests

@Suite("ExportHistoryEntry.Status Tests")
struct ExportHistoryEntryStatusTests {
    @Test("Status has colors")
    func statusColors() {
        for status in [
            ExportHistoryEntry.Status.success,
            .partialSuccess,
            .failed,
            .cancelled,
        ] {
            _ = status.color // Verify doesn't crash
        }
    }

    @Test("Status has icons")
    func statusIcons() {
        #expect(!ExportHistoryEntry.Status.success.icon.isEmpty)
        #expect(!ExportHistoryEntry.Status.partialSuccess.icon.isEmpty)
        #expect(!ExportHistoryEntry.Status.failed.icon.isEmpty)
        #expect(!ExportHistoryEntry.Status.cancelled.icon.isEmpty)
    }

    @Test("Status has labels")
    func statusLabels() {
        #expect(ExportHistoryEntry.Status.success.label == "Success")
        #expect(ExportHistoryEntry.Status.partialSuccess.label == "Partial")
        #expect(ExportHistoryEntry.Status.failed.label == "Failed")
        #expect(ExportHistoryEntry.Status.cancelled.label == "Cancelled")
    }

    @Test("Status is Hashable")
    func statusHashable() {
        let status1 = ExportHistoryEntry.Status.success
        let status2 = ExportHistoryEntry.Status.success

        #expect(status1.hashValue == status2.hashValue)
    }
}
