import Foundation

/// FNV-1a 64-bit hash implementation.
/// Pure Swift, no external dependencies, cross-platform compatible.
///
/// FNV-1a is a non-cryptographic hash function suitable for:
/// - Hash tables and data structures
/// - Change detection (comparing data for modifications)
/// - Checksums where security is not required
///
/// Performance: ~2 GB/s on modern hardware.
/// Collision probability: negligible for change detection (see design.md).
public enum FNV1aHasher {
    /// FNV-1a 64-bit offset basis.
    private static let offsetBasis: UInt64 = 0xCBF2_9CE4_8422_2325

    /// FNV-1a 64-bit prime.
    private static let prime: UInt64 = 0x100_0000_01B3

    /// Computes FNV-1a 64-bit hash of the given data.
    ///
    /// Algorithm:
    /// 1. Start with offset basis
    /// 2. For each byte: XOR with byte, then multiply by prime
    ///
    /// - Parameter data: The data to hash.
    /// - Returns: 64-bit hash value.
    public static func hash(_ data: Data) -> UInt64 {
        var hash = offsetBasis
        for byte in data {
            hash ^= UInt64(byte)
            hash &*= prime
        }
        return hash
    }

    /// Computes FNV-1a 64-bit hash and returns as 16-character hex string.
    ///
    /// - Parameter data: The data to hash.
    /// - Returns: 16-character lowercase hex string (e.g., "cbf29ce484222325").
    public static func hashToHex(_ data: Data) -> String {
        let hashValue = hash(data)
        return String(format: "%016llx", hashValue)
    }
}
