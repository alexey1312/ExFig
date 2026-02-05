import ExFigCore
import FigmaAPI
import Foundation
import Logging

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
    private static let logger = Logger(label: "com.alexey1312.exfig.node-hasher")

    /// Computes a stable hash for the given node properties.
    ///
    /// The hash is computed from canonical JSON (sorted keys) of the
    /// visual properties using FNV-1a 64-bit. This produces a 16-character
    /// lowercase hex string suitable for cache storage.
    ///
    /// - Parameter properties: The hashable visual properties of a node.
    /// - Returns: 16-character lowercase hex string (e.g., "a1b2c3d4e5f67890").
    static func computeHash(_ properties: NodeHashableProperties) -> String {
        do {
            let data = try JSONCodec.encodeSorted(properties)
            return FNV1aHasher.hashToHex(data)
        } catch {
            // Log the error - this should never happen but needs visibility for debugging
            logger.warning(
                "NodeHasher encoding failed, returning zero hash to force re-export",
                metadata: [
                    "nodeType": "\(properties.type)",
                    "error": "\(error.localizedDescription)",
                ]
            )
            // Return error hash to force re-export rather than silently skip
            return "0000000000000000"
        }
    }
}
