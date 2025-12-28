import SwiftUI

@main
struct ExFigStudioApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
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
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "paintbrush.pointed.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("ExFig Studio")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Export Figma assets to iOS, Android, Flutter, and Web")
                .foregroundStyle(.secondary)

            Divider()
                .frame(maxWidth: 300)

            Text("Coming soon...")
                .foregroundStyle(.tertiary)
        }
        .padding(40)
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    ContentView()
}
