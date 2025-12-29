import FigmaAPI
import SwiftUI

// MARK: - App State

/// Global app state for navigation and authentication.
@MainActor
@Observable
final class AppState {
    var isAuthenticated = false
    var figmaAuth: FigmaAuth?
    var selectedNavItem: NavigationItem? = .projects

    // View models
    let authViewModel = AuthViewModel()
    let projectViewModel = ProjectViewModel()
    let assetViewModel = AssetPreviewViewModel()
    let configViewModel = ConfigViewModel()
    let exportViewModel = ExportViewModel()
    let historyViewModel = ExportHistoryViewModel()

    init() {
        // Set up auth callback
        authViewModel.onAuthenticationComplete = { [weak self] auth in
            self?.figmaAuth = auth
            self?.isAuthenticated = true
            self?.projectViewModel.configure(with: auth)
        }
    }
}

// MARK: - Navigation Item

enum NavigationItem: String, Hashable, CaseIterable, Identifiable {
    case projects = "Projects"
    case assets = "Assets"
    case config = "Configuration"
    case export = "Export"
    case history = "History"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .projects: "folder"
        case .assets: "square.grid.2x2"
        case .config: "gearshape"
        case .export: "square.and.arrow.up"
        case .history: "clock.arrow.circlepath"
        }
    }
}

// MARK: - App Entry Point

@main
struct ExFigStudioApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainView(appState: appState)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About ExFig Studio") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            .applicationName: "ExFig Studio",
                            .applicationVersion: Bundle.main
                                .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0",
                            .credits: NSAttributedString(
                                string: "Export Figma assets to iOS, Android, Flutter, and Web",
                                attributes: [.font: NSFont.systemFont(ofSize: 11)]
                            ),
                        ]
                    )
                }
            }

            // Custom commands
            CommandGroup(after: .newItem) {
                Button("New Export...") {
                    appState.selectedNavItem = .config
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Divider()
            }
        }
    }
}

// MARK: - Main View

struct MainView: View {
    @Bindable var appState: AppState

    var body: some View {
        Group {
            if appState.isAuthenticated {
                authenticatedView
            } else {
                AuthView(viewModel: appState.authViewModel)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }

    private var authenticatedView: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $appState.selectedNavItem) {
                Section("Figma") {
                    NavigationLink(value: NavigationItem.projects) {
                        Label(NavigationItem.projects.rawValue, systemImage: NavigationItem.projects.icon)
                    }

                    NavigationLink(value: NavigationItem.assets) {
                        Label(NavigationItem.assets.rawValue, systemImage: NavigationItem.assets.icon)
                    }
                }

                Section("Export") {
                    NavigationLink(value: NavigationItem.config) {
                        Label(NavigationItem.config.rawValue, systemImage: NavigationItem.config.icon)
                    }

                    NavigationLink(value: NavigationItem.export) {
                        Label(NavigationItem.export.rawValue, systemImage: NavigationItem.export.icon)
                    }

                    NavigationLink(value: NavigationItem.history) {
                        Label(NavigationItem.history.rawValue, systemImage: NavigationItem.history.icon)
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 200)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await appState.authViewModel.signOut()
                            appState.isAuthenticated = false
                            appState.figmaAuth = nil
                        }
                    } label: {
                        Image(systemName: "person.crop.circle.badge.xmark")
                    }
                    .help("Sign Out")
                }
            }
        } detail: {
            // Detail view based on selection
            detailView
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch appState.selectedNavItem {
        case .projects:
            ProjectBrowserView(viewModel: appState.projectViewModel)
        case .assets:
            AssetPreviewGrid(viewModel: appState.assetViewModel)
        case .config:
            ConfigEditorView(viewModel: appState.configViewModel)
        case .export:
            ExportProgressView(appState: appState)
        case .history:
            ExportHistoryView(viewModel: appState.historyViewModel)
        case nil:
            ContentUnavailableView {
                Label("Select a Section", systemImage: "sidebar.left")
            } description: {
                Text("Choose a section from the sidebar to get started")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainView(appState: {
        let state = AppState()
        state.isAuthenticated = true
        return state
    }())
}
