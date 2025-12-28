import SwiftUI

// MARK: - Config Editor View

/// Main view for editing export configuration.
struct ConfigEditorView: View {
    @Bindable var viewModel: ConfigViewModel

    @State private var selectedPlatform: Platform?
    @State private var showYAMLExport = false
    @State private var showYAMLImport = false
    @State private var yamlText = ""

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .navigationTitle("Configuration")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    yamlText = viewModel.exportToYAML()
                    showYAMLExport = true
                } label: {
                    Label("Export YAML", systemImage: "square.and.arrow.up")
                }

                Button {
                    yamlText = ""
                    showYAMLImport = true
                } label: {
                    Label("Import YAML", systemImage: "square.and.arrow.down")
                }
            }
        }
        .sheet(isPresented: $showYAMLExport) {
            YAMLExportSheet(yaml: yamlText)
        }
        .sheet(isPresented: $showYAMLImport) {
            YAMLImportSheet(yaml: $yamlText) {
                try? viewModel.importFromYAML(yamlText)
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selectedPlatform) {
            // Figma Source
            Section("Figma Source") {
                FigmaSourceRow(fileKey: $viewModel.fileKey, frameName: $viewModel.figmaFrameName)
            }

            // Platforms
            Section("Platforms") {
                ForEach(Platform.allCases) { platform in
                    PlatformRow(
                        platform: platform,
                        isEnabled: viewModel.platforms.first(where: { $0.platform == platform })?.isEnabled ?? false
                    ) {
                        viewModel.togglePlatform(platform)
                    }
                    .tag(platform)
                }
            }

            // Common Options
            Section("Common Options") {
                CommonOptionsRow(viewModel: viewModel)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 250)
    }

    // MARK: - Detail View

    @ViewBuilder
    private var detailView: some View {
        if let platform = selectedPlatform,
           let config = viewModel.platforms.first(where: { $0.platform == platform })
        {
            PlatformConfigView(
                config: Binding(
                    get: { config },
                    set: { newValue in
                        if let index = viewModel.platforms.firstIndex(where: { $0.platform == platform }) {
                            viewModel.platforms[index] = newValue
                        }
                    }
                )
            )
        } else {
            ContentUnavailableView {
                Label("Select a Platform", systemImage: "sidebar.left")
            } description: {
                Text("Choose a platform from the sidebar to configure export options")
            }
        }
    }
}

// MARK: - Figma Source Row

struct FigmaSourceRow: View {
    @Binding var fileKey: String
    @Binding var frameName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("File Key") {
                TextField("Enter file key or URL", text: $fileKey)
                    .textFieldStyle(.roundedBorder)
            }

            LabeledContent("Frame Name") {
                TextField("Icons", text: $frameName)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Platform Row

struct PlatformRow: View {
    let platform: Platform
    let isEnabled: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Image(systemName: platform.iconName)
                .foregroundStyle(isEnabled ? .primary : .secondary)

            Text(platform.rawValue)
                .foregroundStyle(isEnabled ? .primary : .secondary)

            Spacer()

            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
        }
    }
}

// MARK: - Common Options Row

struct CommonOptionsRow: View {
    @Bindable var viewModel: ConfigViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Name Style") {
                Picker("", selection: $viewModel.nameStyle) {
                    ForEach(NameStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .labelsHidden()
                .frame(width: 150)
            }

            LabeledContent("Validate Regex") {
                TextField("Optional", text: $viewModel.nameValidateRegexp)
                    .textFieldStyle(.roundedBorder)
            }

            LabeledContent("Replace Regex") {
                TextField("Optional", text: $viewModel.nameReplaceRegexp)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Platform Config View

struct PlatformConfigView: View {
    @Binding var config: PlatformConfig

    var body: some View {
        Form {
            // Asset Types
            Section("Asset Types") {
                Toggle("Colors", isOn: $config.colorsEnabled)
                Toggle("Icons", isOn: $config.iconsEnabled)
                Toggle("Images", isOn: $config.imagesEnabled)
                Toggle("Typography", isOn: $config.typographyEnabled)
            }

            // Platform Options
            Section("Export Options") {
                ForEach($config.options) { $option in
                    ExportOptionRow(option: $option)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(config.platform.rawValue)
    }
}

// MARK: - Export Option Row

struct ExportOptionRow: View {
    @Binding var option: ExportOption

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Toggle(option.name, isOn: $option.enabled)

                Spacer()

                optionInput
                    .disabled(!option.enabled)
            }

            Text(option.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var optionInput: some View {
        switch option.type {
        case .text, .path:
            TextField("", text: $option.value)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)

        case .toggle:
            Toggle("", isOn: Binding(
                get: { option.value == "true" },
                set: { option.value = $0 ? "true" : "false" }
            ))
            .labelsHidden()

        case let .picker(choices):
            Picker("", selection: $option.value) {
                ForEach(choices, id: \.self) { choice in
                    Text(choice).tag(choice)
                }
            }
            .labelsHidden()
            .frame(width: 100)
        }
    }
}

// MARK: - YAML Export Sheet

struct YAMLExportSheet: View {
    let yaml: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Export Configuration")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding()
            .background(.bar)

            Divider()

            ScrollView {
                Text(yaml)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }

            Divider()

            HStack {
                Spacer()
                Button("Copy to Clipboard") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(yaml, forType: .string)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 600, height: 500)
    }
}

// MARK: - YAML Import Sheet

struct YAMLImportSheet: View {
    @Binding var yaml: String
    let onImport: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Import Configuration")
                    .font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }
            }
            .padding()
            .background(.bar)

            Divider()

            TextEditor(text: $yaml)
                .font(.system(.body, design: .monospaced))
                .padding()

            Divider()

            HStack {
                Button("Paste from Clipboard") {
                    if let string = NSPasteboard.general.string(forType: .string) {
                        yaml = string
                    }
                }

                Spacer()

                Button("Import") {
                    onImport()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(yaml.isEmpty)
            }
            .padding()
        }
        .frame(width: 600, height: 500)
    }
}

// MARK: - Preview

#Preview {
    ConfigEditorView(viewModel: ConfigViewModel())
        .frame(width: 900, height: 600)
}
