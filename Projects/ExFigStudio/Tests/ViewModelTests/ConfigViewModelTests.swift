import Foundation
import Testing

@testable import ExFigStudio

@Suite("ConfigViewModel Tests")
@MainActor
struct ConfigViewModelTests {
    // MARK: - Initialization Tests

    @Test("Initial state has all platforms disabled")
    func initialState() {
        let viewModel = ConfigViewModel()

        #expect(viewModel.fileKey.isEmpty)
        #expect(viewModel.figmaFrameName == "Icons")
        #expect(viewModel.platforms.count == 4)
        #expect(viewModel.enabledPlatforms.isEmpty)
        #expect(viewModel.nameStyle == .original)
    }

    // MARK: - Validation Tests

    @Test("Empty file key fails validation")
    func emptyFileKey() {
        let viewModel = ConfigViewModel()
        viewModel.fileKey = ""
        viewModel.togglePlatform(.ios)

        #expect(!viewModel.isValid)
        #expect(viewModel.validationErrors.contains { $0.contains("file key") })
    }

    @Test("No platforms enabled fails validation")
    func noPlatformsEnabled() {
        let viewModel = ConfigViewModel()
        viewModel.fileKey = "abc123"

        #expect(!viewModel.isValid)
        #expect(viewModel.validationErrors.contains { $0.contains("platform") })
    }

    @Test("Platform with no asset types enabled fails validation")
    func noAssetTypesEnabled() {
        let viewModel = ConfigViewModel()
        viewModel.fileKey = "abc123"

        // Enable iOS platform
        if let index = viewModel.platforms.firstIndex(where: { $0.platform == .ios }) {
            viewModel.platforms[index].isEnabled = true
            viewModel.platforms[index].colorsEnabled = false
            viewModel.platforms[index].iconsEnabled = false
            viewModel.platforms[index].imagesEnabled = false
            viewModel.platforms[index].typographyEnabled = false
        }

        #expect(!viewModel.isValid)
        #expect(viewModel.validationErrors.contains { $0.contains("iOS") && $0.contains("asset type") })
    }

    @Test("Valid configuration passes validation")
    func validConfiguration() {
        let viewModel = ConfigViewModel()
        viewModel.fileKey = "abc123"
        viewModel.togglePlatform(.ios)

        #expect(viewModel.isValid)
        #expect(viewModel.validationErrors.isEmpty)
    }

    // MARK: - Platform Toggle Tests

    @Test("Toggle platform enables/disables it")
    func togglePlatform() {
        let viewModel = ConfigViewModel()

        #expect(!viewModel.platforms.first { $0.platform == .ios }!.isEnabled)

        viewModel.togglePlatform(.ios)
        #expect(viewModel.platforms.first { $0.platform == .ios }!.isEnabled)

        viewModel.togglePlatform(.ios)
        #expect(!viewModel.platforms.first { $0.platform == .ios }!.isEnabled)
    }

    @Test("Enabled platforms returns only enabled ones")
    func enabledPlatforms() {
        let viewModel = ConfigViewModel()

        viewModel.togglePlatform(.ios)
        viewModel.togglePlatform(.android)

        #expect(viewModel.enabledPlatforms.count == 2)
        #expect(viewModel.enabledPlatforms.contains { $0.platform == .ios })
        #expect(viewModel.enabledPlatforms.contains { $0.platform == .android })
        #expect(!viewModel.enabledPlatforms.contains { $0.platform == .flutter })
    }

    // MARK: - YAML Export Tests

    @Test("Export to YAML includes file key")
    func exportYAMLFileKey() {
        let viewModel = ConfigViewModel()
        viewModel.fileKey = "test-file-key"

        let yaml = viewModel.exportToYAML()

        #expect(yaml.contains("fileId: \"test-file-key\""))
    }

    @Test("Export to YAML includes enabled platforms")
    func exportYAMLPlatforms() {
        let viewModel = ConfigViewModel()
        viewModel.fileKey = "test-key"
        viewModel.togglePlatform(.ios)

        let yaml = viewModel.exportToYAML()

        #expect(yaml.contains("ios:"))
    }

    @Test("Export to YAML includes figma frame name")
    func exportYAMLFrameName() {
        let viewModel = ConfigViewModel()
        viewModel.fileKey = "test-key"
        viewModel.figmaFrameName = "MyIcons"

        let yaml = viewModel.exportToYAML()

        #expect(yaml.contains("figmaFrameName: \"MyIcons\""))
    }

    // MARK: - YAML Import Tests

    @Test("Import YAML sets file key")
    func importYAMLFileKey() throws {
        let viewModel = ConfigViewModel()
        let yaml = """
        figma:
          fileId: "imported-key"
        """

        try viewModel.importFromYAML(yaml)

        #expect(viewModel.fileKey == "imported-key")
    }

    @Test("Import YAML enables platforms")
    func importYAMLPlatforms() throws {
        let viewModel = ConfigViewModel()
        let yaml = """
        figma:
          fileId: "test"
        ios:
          assetsFolder: "Assets.xcassets"
        """

        try viewModel.importFromYAML(yaml)

        #expect(viewModel.platforms.first { $0.platform == .ios }!.isEnabled)
    }

    @Test("Import YAML handles comments")
    func importYAMLComments() throws {
        let viewModel = ConfigViewModel()
        let yaml = """
        # This is a comment
        figma:
          fileId: "test-key"
        """

        try viewModel.importFromYAML(yaml)

        #expect(viewModel.fileKey == "test-key")
    }
}

// MARK: - Platform Tests

@Suite("Platform Tests")
struct PlatformTests {
    @Test("All platforms have icon names")
    func allPlatformsHaveIcons() {
        for platform in Platform.allCases {
            #expect(!platform.iconName.isEmpty)
        }
    }

    @Test("All platforms have IDs")
    func allPlatformsHaveIds() {
        for platform in Platform.allCases {
            #expect(!platform.id.isEmpty)
        }
    }
}

// MARK: - PlatformConfig Tests

@Suite("PlatformConfig Tests")
struct PlatformConfigTests {
    @Test("Default iOS config has expected options")
    func defaultIOSConfig() {
        let config = PlatformConfig.defaultConfig(for: .ios)

        #expect(config.platform == .ios)
        #expect(!config.isEnabled)
        #expect(config.colorsEnabled)
        #expect(config.iconsEnabled)
        #expect(config.imagesEnabled)
        #expect(config.typographyEnabled)
        #expect(config.options.contains { $0.name == "Assets Folder" })
    }

    @Test("Default Android config has expected options")
    func defaultAndroidConfig() {
        let config = PlatformConfig.defaultConfig(for: .android)

        #expect(config.platform == .android)
        #expect(config.options.contains { $0.name == "Resources Path" })
        #expect(config.options.contains { $0.name == "Vector Drawables" })
    }

    @Test("Default Flutter config has expected options")
    func defaultFlutterConfig() {
        let config = PlatformConfig.defaultConfig(for: .flutter)

        #expect(config.platform == .flutter)
        #expect(config.options.contains { $0.name == "Colors Class" })
    }

    @Test("Default Web config has format picker")
    func defaultWebConfig() {
        let config = PlatformConfig.defaultConfig(for: .web)

        #expect(config.platform == .web)
        #expect(!config.typographyEnabled) // Web doesn't support typography by default

        let formatOption = config.options.first { $0.name == "Format" }
        #expect(formatOption != nil)

        if case let .picker(options) = formatOption?.type {
            #expect(options.contains("css"))
            #expect(options.contains("scss"))
            #expect(options.contains("json"))
        } else {
            Issue.record("Format option should be a picker")
        }
    }
}

// MARK: - NameStyle Tests

@Suite("NameStyle Tests")
struct NameStyleTests {
    @Test("All name styles have unique IDs")
    func uniqueIds() {
        let ids = NameStyle.allCases.map(\.id)
        #expect(Set(ids).count == NameStyle.allCases.count)
    }

    @Test("Name styles have expected raw values")
    func rawValues() {
        #expect(NameStyle.original.rawValue == "Original")
        #expect(NameStyle.camelCase.rawValue == "camelCase")
        #expect(NameStyle.snakeCase.rawValue == "snake_case")
        #expect(NameStyle.kebabCase.rawValue == "kebab-case")
    }
}
