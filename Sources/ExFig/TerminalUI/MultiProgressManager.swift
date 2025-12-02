import Foundation
import Rainbow

/// Manages multiple concurrent progress indicators
actor MultiProgressManager {
    /// State of a single progress item
    struct ProgressState: Sendable {
        let id: UUID
        var label: String
        var current: Int
        var total: Int?
        var status: Status
        let startTime: Date

        enum Status: Sendable {
            case running
            case succeeded
            case failed
        }
    }

    private var progressItems: [UUID: ProgressState] = [:]
    private var lineCount: Int = 0
    private let useColors: Bool
    private let useAnimations: Bool

    init(useColors: Bool = true, useAnimations: Bool = true) {
        self.useColors = useColors
        self.useAnimations = useAnimations
    }

    /// Create a new progress item
    func createProgress(label: String, total: Int? = nil) -> UUID {
        let id = UUID()
        progressItems[id] = ProgressState(
            id: id,
            label: label,
            current: 0,
            total: total,
            status: .running,
            startTime: Date()
        )
        render()
        return id
    }

    /// Update progress for an item
    func update(id: UUID, current: Int, message: String? = nil) {
        guard var item = progressItems[id] else { return }
        item.current = current
        if let msg = message {
            item.label = msg
        }
        progressItems[id] = item
        render()
    }

    /// Mark an item as completed
    func complete(id: UUID, success: Bool, message: String? = nil) {
        guard var item = progressItems[id] else { return }
        item.status = success ? .succeeded : .failed
        if let msg = message {
            item.label = msg
        }
        progressItems[id] = item
        render()
    }

    /// Remove a completed item from tracking
    func remove(id: UUID) {
        progressItems.removeValue(forKey: id)
        render()
    }

    /// Clear all progress items
    func clear() {
        if useAnimations, lineCount > 0 {
            // Move up and clear all lines
            for _ in 0 ..< lineCount {
                print(ANSICodes.cursorUp(1), terminator: "")
                print(ANSICodes.clearLine, terminator: "")
            }
        }
        progressItems.removeAll()
        lineCount = 0
        ANSICodes.flushStdout()
    }

    /// Render all progress items
    private func render() {
        guard useAnimations else {
            // Plain mode: don't render multi-line progress
            return
        }

        // Move cursor up to clear previous render
        if lineCount > 0 {
            print(ANSICodes.cursorUp(lineCount), terminator: "")
        }

        let sortedItems = progressItems.values.sorted { $0.id.uuidString < $1.id.uuidString }

        for item in sortedItems {
            print(ANSICodes.clearLine, terminator: "")

            let icon: String = switch item.status {
            case .running:
                useColors ? "⠸".cyan : "⠸"
            case .succeeded:
                useColors ? "✓".green : "✓"
            case .failed:
                useColors ? "✗".red : "✗"
            }

            if let total = item.total, total > 0 {
                let percentage = Double(item.current) / Double(total) * 100
                print("\(icon) \(item.label) [\(item.current)/\(total)] \(String(format: "%.0f%%", percentage))")
            } else {
                print("\(icon) \(item.label)")
            }
        }

        lineCount = sortedItems.count
        ANSICodes.flushStdout()
    }
}
