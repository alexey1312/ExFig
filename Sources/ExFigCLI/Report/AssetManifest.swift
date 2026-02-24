import Foundation

/// Manifest of all files generated during an export.
struct AssetManifest: Encodable {
    /// List of generated file entries.
    let files: [ManifestEntry]
}

/// A single file entry in the asset manifest.
struct ManifestEntry: Encodable {
    /// Relative path to the file (relative to working directory).
    let path: String

    /// What happened to this file during export.
    let action: FileAction

    /// FNV-1a 64-bit content checksum (16-char hex), `nil` for deleted files.
    let checksum: String?

    /// Type of asset (e.g., "color", "icon", "image", "typography").
    let assetType: String
}

/// Classification of file write operations.
enum FileAction: String, Encodable {
    /// File did not exist before write.
    case created
    /// File existed but content changed.
    case modified
    /// File existed with identical content.
    case unchanged
    /// File existed in previous report but is no longer generated.
    case deleted
}
