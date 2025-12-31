import Foundation
import SwiftUI

// MARK: - Export History Entry

/// A single export history entry.
struct ExportHistoryEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let timestamp: Date
    let fileName: String
    let fileKey: String
    let platforms: [String]
    let assetCounts: AssetCounts
    let duration: TimeInterval
    let status: Status
    let configPath: String?

    struct AssetCounts: Codable, Hashable {
        let colors: Int
        let icons: Int
        let images: Int
        let typography: Int

        var total: Int { colors + icons + images + typography }
    }

    enum Status: String, Codable, Hashable {
        case success
        case partialSuccess
        case failed
        case cancelled

        var color: Color {
            switch self {
            case .success: .green
            case .partialSuccess: .orange
            case .failed: .red
            case .cancelled: .secondary
            }
        }

        var icon: String {
            switch self {
            case .success: "checkmark.circle.fill"
            case .partialSuccess: "exclamationmark.circle.fill"
            case .failed: "xmark.circle.fill"
            case .cancelled: "stop.circle.fill"
            }
        }

        var label: String {
            switch self {
            case .success: "Success"
            case .partialSuccess: "Partial"
            case .failed: "Failed"
            case .cancelled: "Cancelled"
            }
        }
    }

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        fileName: String,
        fileKey: String,
        platforms: [String],
        assetCounts: AssetCounts,
        duration: TimeInterval,
        status: Status,
        configPath: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.fileName = fileName
        self.fileKey = fileKey
        self.platforms = platforms
        self.assetCounts = assetCounts
        self.duration = duration
        self.status = status
        self.configPath = configPath
    }
}

// MARK: - Export History View Model

/// View model for export history.
@MainActor
@Observable
final class ExportHistoryViewModel {
    // MARK: - State

    var entries: [ExportHistoryEntry] = []
    var selectedEntry: ExportHistoryEntry?
    var searchText: String = ""
    var filterStatus: ExportHistoryEntry.Status?

    // MARK: - Storage

    private let storageKey = "exportHistory"
    private let maxEntries = 100

    // MARK: - Computed Properties

    var filteredEntries: [ExportHistoryEntry] {
        var result = entries

        // Filter by status
        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter {
                $0.fileName.localizedCaseInsensitiveContains(searchText) ||
                    $0.platforms.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var groupedByDate: [(date: Date, entries: [ExportHistoryEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }

        return grouped
            .map { (date: $0.key, entries: $0.value.sorted { $0.timestamp > $1.timestamp }) }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Actions

    /// Load history from storage.
    func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            entries = []
            return
        }

        do {
            let decoded = try JSONDecoder().decode([ExportHistoryEntry].self, from: data)
            entries = decoded.sorted { $0.timestamp > $1.timestamp }
        } catch {
            entries = []
        }
    }

    /// Save history to storage.
    func saveHistory() {
        do {
            let encoded = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(encoded, forKey: storageKey)
        } catch {
            // Ignore save errors
        }
    }

    /// Add a new export entry.
    func addEntry(_ entry: ExportHistoryEntry) {
        entries.insert(entry, at: 0)

        // Trim to max entries
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }

        saveHistory()
    }

    /// Remove an entry.
    func removeEntry(_ entry: ExportHistoryEntry) {
        entries.removeAll { $0.id == entry.id }
        saveHistory()
    }

    /// Clear all history.
    func clearHistory() {
        entries = []
        saveHistory()
    }

    /// Re-run an export from history.
    func rerunExport(_ entry: ExportHistoryEntry) async {
        // This would trigger a new export with the same configuration
        // For now, just select the entry
        selectedEntry = entry
    }
}
