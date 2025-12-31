import ExFigKit
import FigmaAPI
import Foundation

/// Utilities for merging and converting node hash dictionaries.
enum HashMerger {
    /// Merges two hash maps, with values from `new` taking precedence on conflicts.
    /// - Parameters:
    ///   - existing: The base hash map.
    ///   - new: The hash map to merge in.
    /// - Returns: A new hash map containing all entries from both maps.
    static func merge(
        _ existing: [String: [NodeId: String]],
        _ new: [String: [NodeId: String]]
    ) -> [String: [NodeId: String]] {
        var result = existing
        for (fileId, hashes) in new {
            if let existingHashes = result[fileId] {
                result[fileId] = existingHashes.merging(hashes) { _, new in new }
            } else {
                result[fileId] = hashes
            }
        }
        return result
    }

    /// Converts NodeId keys to String keys for batch result compatibility.
    /// - Parameter hashes: Hash map with NodeId keys.
    /// - Returns: Hash map with String keys.
    static func convertToStringKeys(
        _ hashes: [String: [NodeId: String]]
    ) -> [String: [String: String]] {
        hashes.mapValues { nodeHashes in
            nodeHashes.reduce(into: [String: String]()) { result, pair in
                result[pair.key] = pair.value
            }
        }
    }
}
