import Foundation

public struct Destination: Equatable, Sendable {
    public let directory: URL
    public let file: URL

    public var url: URL {
        // URL(fileURLWithPath:) → absolute file URL, use lastPathComponent (just filename)
        // URL(string:) → relative URL, preserve full path including subdirectories
        let relativePath = file.isFileURL ? file.lastPathComponent : file.path
        return directory.appendingPathComponent(relativePath)
    }

    public init(directory: URL, file: URL) {
        precondition(!file.path.isEmpty, "Destination file URL must not have an empty path")
        self.directory = directory
        self.file = file
    }
}

public struct FileContents: Equatable, Sendable {
    /// Where to save file?
    public let destination: Destination

    /// Raw data (in-memory)
    public let data: Data?

    /// Raw data (on-disk)
    public let dataFile: URL?

    /// Where to fetch data?
    public let sourceURL: URL?

    public var dark: Bool = false
    public var scale: Double = 1.0
    public var isRTL: Bool = false

    /// In-memory file
    public init(destination: Destination, data: Data, scale: Double = 1.0, dark: Bool = false, isRTL: Bool = false) {
        self.destination = destination
        self.data = data
        dataFile = nil
        sourceURL = nil
        self.scale = scale
        self.dark = dark
        self.isRTL = isRTL
    }

    /// Remote file
    public init(
        destination: Destination,
        sourceURL: URL,
        scale: Double = 1.0,
        dark: Bool = false,
        isRTL: Bool = false
    ) {
        self.destination = destination
        data = nil
        dataFile = nil
        self.sourceURL = sourceURL
        self.scale = scale
        self.dark = dark
        self.isRTL = isRTL
    }

    /// On-disk file
    public init(destination: Destination, dataFile: URL, scale: Double = 1.0, dark: Bool = false, isRTL: Bool = false) {
        self.destination = destination
        data = nil
        self.dataFile = dataFile
        sourceURL = nil
        self.scale = scale
        self.dark = dark
        self.isRTL = isRTL
    }

    /// Make a copy with the @Nx scale suffix stripped from the filename.
    /// rasterizeSVGs adds iOS-style suffixes (e.g., "icon@2x.png") but Android uses
    /// directory-based scaling (drawable-xhdpi/) and Flutter uses "{scale}x/" directories.
    public func strippingScaleSuffix() -> FileContents {
        let strippedFile = destination.file.strippingScaleSuffix()
        let newDestination = Destination(directory: destination.directory, file: strippedFile)
        if let dataFile {
            return FileContents(destination: newDestination, dataFile: dataFile, scale: scale, dark: dark, isRTL: isRTL)
        } else if let data {
            return FileContents(destination: newDestination, data: data, scale: scale, dark: dark, isRTL: isRTL)
        } else if let sourceURL {
            return FileContents(
                destination: newDestination,
                sourceURL: sourceURL,
                scale: scale,
                dark: dark,
                isRTL: isRTL
            )
        } else {
            fatalError("FileContents has no data source")
        }
    }

    /// Make a copy of the FileContents with different file extension
    /// - Parameter newExtension: New file extension
    public func changingExtension(newExtension: String) -> FileContents {
        let newFileURL = destination.file
            .deletingPathExtension()
            .appendingPathExtension(newExtension)

        let newDestination = Destination(directory: destination.directory, file: newFileURL)

        if let sourceURL { // Remote file
            return FileContents(destination: newDestination, sourceURL: sourceURL, scale: scale, dark: dark)
        } else if let dataFile { // On-disk file - also update dataFile extension
            let newDataFileURL = dataFile
                .deletingPathExtension()
                .appendingPathExtension(newExtension)
            return FileContents(destination: newDestination, dataFile: newDataFileURL, scale: scale, dark: dark)
        } else if let data { // In-memory file
            return FileContents(destination: newDestination, data: data, scale: scale, dark: dark)
        } else {
            fatalError("Unable to change file extension.")
        }
    }
}

public extension URL {
    /// Strips iOS-style @Nx scale suffix from filename (e.g., "icon@2x.png" -> "icon.png").
    func strippingScaleSuffix() -> URL {
        let ext = pathExtension
        let baseName = deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: #"@\d+x$"#, with: "", options: .regularExpression)
        return URL(fileURLWithPath: "\(baseName).\(ext)")
    }
}
