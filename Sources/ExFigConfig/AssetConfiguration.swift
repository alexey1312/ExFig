import Foundation

/// Generic configuration that supports both single object and array formats.
///
/// This enum enables backward compatibility with legacy single-object configs
/// while supporting new multi-entry array configs.
///
/// Example PKL:
/// ```pkl
/// // Single (legacy)
/// colors {
///   output = "/path"
/// }
///
/// // Multiple (new)
/// colors = [
///   { output = "/path/one" },
///   { output = "/path/two" }
/// ]
/// ```
public enum AssetConfiguration<Entry: Decodable & Sendable>: Decodable, Sendable {
    /// Single configuration object (legacy format).
    case single(Entry)

    /// Multiple configuration entries (new format).
    case multiple([Entry])

    public init(from decoder: Decoder) throws {
        // Try decoding as array first (new format)
        if let array = try? [Entry](from: decoder) {
            self = .multiple(array)
            return
        }
        // Fallback to single object (legacy format)
        let single = try Entry(from: decoder)
        self = .single(single)
    }

    /// Returns all entries as an array.
    /// For single case, wraps the entry in an array.
    public var entries: [Entry] {
        switch self {
        case let .single(entry):
            [entry]
        case let .multiple(entries):
            entries
        }
    }

    /// Returns true if this is a multiple-entry configuration.
    public var isMultiple: Bool {
        if case .multiple = self { return true }
        return false
    }

    /// Returns the first entry, if any.
    public var first: Entry? {
        entries.first
    }

    /// Returns the number of entries.
    public var count: Int {
        entries.count
    }
}

// MARK: - Sequence Conformance

extension AssetConfiguration: Sequence {
    public func makeIterator() -> IndexingIterator<[Entry]> {
        entries.makeIterator()
    }
}

// MARK: - Collection Conformance

extension AssetConfiguration: Collection {
    public typealias Index = Int
    public typealias Element = Entry

    public var startIndex: Index {
        entries.startIndex
    }

    public var endIndex: Index {
        entries.endIndex
    }

    public subscript(position: Index) -> Entry {
        entries[position]
    }

    public func index(after i: Index) -> Index {
        entries.index(after: i)
    }
}
