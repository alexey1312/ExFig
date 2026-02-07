// swiftlint:disable file_length

import AndroidExport
import ExFigCore
import Foundation
import SVGKit

/// Exports icons from Figma frames to Android vector drawables and Jetpack Compose code.
///
/// Supports two output formats:
/// - VectorDrawable XML files for `res/drawable/`
/// - Jetpack Compose ImageVector Kotlin files
public struct AndroidIconsExporter: IconsExporter {
    public typealias Entry = AndroidIconsEntry
    public typealias PlatformConfig = AndroidPlatformConfig

    public init() {}

    public func exportIcons(
        entries: [AndroidIconsEntry],
        platformConfig: AndroidPlatformConfig,
        context: some IconsExportContext
    ) async throws -> IconsExportResult {
        var totalCount = 0

        for entry in entries {
            totalCount += try await exportSingleEntry(
                entry: entry,
                platformConfig: platformConfig,
                context: context
            )
        }

        if !context.isBatchMode {
            context.success("Done! Exported \(totalCount) icons to Android project.")
        }

        return .simple(count: totalCount)
    }

    // MARK: - Private

    private func exportSingleEntry(
        entry: AndroidIconsEntry,
        platformConfig: AndroidPlatformConfig,
        context: some IconsExportContext
    ) async throws -> Int {
        let composeFormat = entry.effectiveComposeFormat

        if composeFormat == .imageVector {
            return try await exportAsImageVector(
                entry: entry,
                platformConfig: platformConfig,
                context: context
            )
        }

        return try await exportAsVectorDrawable(
            entry: entry,
            platformConfig: platformConfig,
            context: context
        )
    }
}

// MARK: - VectorDrawable Export

private extension AndroidIconsExporter {
    func exportAsVectorDrawable(
        entry: AndroidIconsEntry,
        platformConfig: AndroidPlatformConfig,
        context: some IconsExportContext
    ) async throws -> Int {
        let (iconPairs, tempDirs) = try await loadAndProcess(entry: entry, context: context)

        // Download SVG files
        let remoteFiles = AndroidIconsHelpers.makeSVGRemoteFiles(
            iconPairs: iconPairs,
            lightDir: tempDirs.light,
            darkDir: tempDirs.dark
        )
        let localFiles = try await context.downloadFiles(remoteFiles, progressTitle: "Downloading SVGs")

        try context.writeFiles(localFiles)

        // Convert SVG to VectorDrawable XML
        let rtlFileNames = Set(remoteFiles.filter(\.isRTL).map {
            $0.destination.file.deletingPathExtension().lastPathComponent
        })
        let converter = NativeVectorDrawableConverter(
            strictPathValidation: entry.strictPathValidation ?? false
        )

        try await context.withSpinner("Converting SVGs to vector drawables...") {
            if FileManager.default.fileExists(atPath: tempDirs.light.path) {
                try await converter.convertAsync(inputDirectoryUrl: tempDirs.light, rtlFiles: rtlFileNames)
            }
            if FileManager.default.fileExists(atPath: tempDirs.dark.path) {
                try await converter.convertAsync(inputDirectoryUrl: tempDirs.dark, rtlFiles: rtlFileNames)
            }
        }

        let (lightDir, darkDir) = AndroidIconsHelpers.outputDirectories(
            entry: entry, platformConfig: platformConfig
        )
        if context.filter == nil {
            try? FileManager.default.removeItem(atPath: lightDir.path)
            try? FileManager.default.removeItem(atPath: darkDir.path)
        }

        let xmlFiles = AndroidIconsHelpers.mapToXMLFiles(
            localFiles: localFiles, lightDir: lightDir, darkDir: darkDir
        )

        // Generate Compose extension if configured
        var allFiles = xmlFiles
        if let composeFile = try generateComposeExtension(
            iconPairs: iconPairs,
            localFiles: localFiles,
            entry: entry,
            platformConfig: platformConfig
        ) {
            allFiles.append(composeFile)
        }

        let filesToWrite = allFiles
        try await context.withSpinner("Writing files to Android project...") {
            try context.writeFiles(filesToWrite)
        }

        // Cleanup temp directories
        try? FileManager.default.removeItem(at: tempDirs.light)
        try? FileManager.default.removeItem(at: tempDirs.dark)

        return iconPairs.count
    }

    func generateComposeExtension(
        iconPairs: [AssetPair<ImagePack>],
        localFiles: [FileContents],
        entry: AndroidIconsEntry,
        platformConfig: AndroidPlatformConfig
    ) throws -> FileContents? {
        let output = AndroidOutput(
            xmlOutputDirectory: platformConfig.mainRes,
            xmlResourcePackage: platformConfig.resourcePackage,
            srcDirectory: platformConfig.mainSrc,
            packageName: entry.composePackageName,
            colorKotlinURL: nil,
            templatesPath: platformConfig.templatesPath
        )
        let composeExporter = AndroidComposeIconExporter(output: output)
        let iconNames = Set(localFiles.filter { !$0.dark }.map {
            $0.destination.file.deletingPathExtension().lastPathComponent
        })
        return try composeExporter.exportIcons(
            iconNames: Array(iconNames).sorted(),
            allIconNames: nil
        )
    }
}

// MARK: - ImageVector Export

private extension AndroidIconsExporter {
    func exportAsImageVector(
        entry: AndroidIconsEntry,
        platformConfig: AndroidPlatformConfig,
        context: some IconsExportContext
    ) async throws -> Int {
        guard let packageName = entry.composePackageName else {
            throw AndroidIconsExportError.missingComposePackageName
        }

        guard let srcDirectory = platformConfig.mainSrc else {
            throw AndroidIconsExportError.missingMainSrc
        }

        let (iconPairs, tempDirs) = try await loadAndProcess(entry: entry, context: context)

        // Download SVG files (light only for ImageVector)
        let remoteFiles = iconPairs.flatMap { pair -> [FileContents] in
            pair.light.images.compactMap { image -> FileContents? in
                guard let fileURL = URL(string: "\(image.name).svg") else { return nil }
                let dest = Destination(directory: tempDirs.light, file: fileURL)
                return FileContents(destination: dest, sourceURL: image.url, isRTL: image.isRTL)
            }
        }
        let localFiles = try await context.downloadFiles(remoteFiles, progressTitle: "Downloading SVGs")
        try context.writeFiles(localFiles)

        // Convert SVGs to ImageVector Kotlin files
        let kotlinFiles = try await context.withSpinner("Converting SVGs to ImageVector...") {
            let outputDirectory = srcDirectory.appendingPathComponent(
                packageName.replacingOccurrences(of: ".", with: "/")
            )

            let exporter = AndroidImageVectorExporter(
                outputDirectory: outputDirectory,
                config: .init(
                    packageName: packageName,
                    extensionTarget: entry.composeExtensionTarget,
                    generatePreview: true,
                    colorMappings: [:],
                    strictPathValidation: entry.strictPathValidation ?? false
                )
            )

            // Collect SVG data
            var svgFiles: [String: Data] = [:]
            for file in localFiles {
                let iconName = file.destination.file.deletingPathExtension().lastPathComponent
                do {
                    let data = try Data(contentsOf: file.destination.url)
                    svgFiles[iconName] = data
                } catch {
                    context.warning("Failed to read SVG file '\(iconName)': \(error.localizedDescription)")
                }
            }

            if context.filter == nil {
                try? FileManager.default.removeItem(atPath: outputDirectory.path)
            }

            return try await exporter.exportAsync(svgFiles: svgFiles)
        }

        try await context.withSpinner("Writing Kotlin files to Android project...") {
            try context.writeFiles(kotlinFiles)
        }

        // Cleanup
        try? FileManager.default.removeItem(at: tempDirs.light)
        try? FileManager.default.removeItem(at: tempDirs.dark)

        return kotlinFiles.count
    }
}

// MARK: - Load & Process

private extension AndroidIconsExporter {
    func loadAndProcess(
        entry: AndroidIconsEntry,
        context: some IconsExportContext
    ) async throws -> ([AssetPair<ImagePack>], (light: URL, dark: URL)) {
        let icons = try await context.withSpinner("Fetching icons from Figma (\(entry.output))...") {
            try await context.loadIcons(from: entry.iconsSourceInput())
        }

        let processResult = try await context.withSpinner("Processing icons for Android...") {
            try context.processIcons(
                icons,
                platform: .android,
                nameValidateRegexp: entry.nameValidateRegexp,
                nameReplaceRegexp: entry.nameReplaceRegexp,
                nameStyle: entry.effectiveNameStyle
            )
        }

        if let warning = processResult.warning {
            context.warning(warning)
        }

        let tempLight = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let tempDark = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        return (processResult.iconPairs, (light: tempLight, dark: tempDark))
    }
}

// MARK: - Static Helpers

private enum AndroidIconsHelpers {
    static func makeSVGRemoteFiles(
        iconPairs: [AssetPair<ImagePack>],
        lightDir: URL,
        darkDir: URL
    ) -> [FileContents] {
        var files: [FileContents] = []

        for pair in iconPairs {
            for image in pair.light.images {
                guard let fileURL = URL(string: "\(image.name).svg") else { continue }
                files.append(FileContents(
                    destination: Destination(directory: lightDir, file: fileURL),
                    sourceURL: image.url,
                    isRTL: image.isRTL
                ))
            }

            if let dark = pair.dark {
                for image in dark.images {
                    guard let fileURL = URL(string: "\(image.name).svg") else { continue }
                    files.append(FileContents(
                        destination: Destination(directory: darkDir, file: fileURL),
                        sourceURL: image.url,
                        dark: true,
                        isRTL: image.isRTL
                    ))
                }
            }
        }

        return files
    }

    static func outputDirectories(
        entry: AndroidIconsEntry,
        platformConfig: AndroidPlatformConfig
    ) -> (light: URL, dark: URL) {
        let lightDir = platformConfig.mainRes
            .appendingPathComponent(entry.output)
            .appendingPathComponent("drawable", isDirectory: true)
        let darkDir = platformConfig.mainRes
            .appendingPathComponent(entry.output)
            .appendingPathComponent("drawable-night", isDirectory: true)
        return (lightDir, darkDir)
    }

    static func mapToXMLFiles(
        localFiles: [FileContents],
        lightDir: URL,
        darkDir: URL
    ) -> [FileContents] {
        localFiles.map { fileContents -> FileContents in
            let directory = fileContents.dark ? darkDir : lightDir
            let source = fileContents.destination.url
                .deletingPathExtension()
                .appendingPathExtension("xml")
            let fileURL = fileContents.destination.file
                .deletingPathExtension()
                .appendingPathExtension("xml")
            return FileContents(
                destination: Destination(directory: directory, file: fileURL),
                dataFile: source
            )
        }
    }
}

// MARK: - Errors

/// Errors that can occur during Android icons export.
public enum AndroidIconsExportError: LocalizedError {
    /// composePackageName is required for ImageVector output.
    case missingComposePackageName

    /// mainSrc directory is required for ImageVector output.
    case missingMainSrc

    public var errorDescription: String? {
        switch self {
        case .missingComposePackageName:
            "composePackageName is required for ImageVector output"
        case .missingMainSrc:
            "mainSrc is required for ImageVector output"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .missingComposePackageName:
            "Add 'composePackageName' to your Android icons entry"
        case .missingMainSrc:
            "Add 'mainSrc' to your Android platform configuration"
        }
    }
}

// swiftlint:enable file_length
