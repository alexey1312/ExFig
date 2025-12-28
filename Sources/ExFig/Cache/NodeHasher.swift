import ExFigKit
import FigmaAPI
import Foundation

/// Computes stable hashes for Figma node visual properties.
///
/// Combines `FNV1aHasher` with canonical JSON serialization of
/// `NodeHashableProperties` to produce deterministic hashes for
/// change detection.
///
/// Features:
/// - Sorted keys JSON for stable output
/// - Recursive hashing includes all children
/// - Float normalization handled at property creation time
enum NodeHasher {
    /// Computes a stable hash for the given node properties.
    ///
    /// The hash is computed from canonical JSON (sorted keys) of the
    /// visual properties using FNV-1a 64-bit. This produces a 16-character
    /// lowercase hex string suitable for cache storage.
    ///
    /// - Parameter properties: The hashable visual properties of a node.
    /// - Returns: 16-character lowercase hex string (e.g., "a1b2c3d4e5f67890").
    static func computeHash(_ properties: NodeHashableProperties) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        do {
            let data = try encoder.encode(properties)
            return FNV1aHasher.hashToHex(data)
        } catch {
            // Encoding should never fail for Encodable types
            // If it does, return a unique error hash to force re-export
            return "0000000000000000"
        }
    }
}
