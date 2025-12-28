import AppKit
import Foundation

/// Application delegate for handling URL scheme callbacks (OAuth).
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Callback handler for OAuth URL events.
    var onOAuthCallback: ((URL) -> Void)?

    func applicationDidFinishLaunching(_: Notification) {
        // Register for Apple Events to handle URL scheme
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    func applicationWillTerminate(_: Notification) {
        // Cleanup if needed
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        false // Keep app running when window is closed
    }

    // MARK: - URL Handling

    @objc private func handleGetURL(_ event: NSAppleEventDescriptor, withReplyEvent _: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString)
        else {
            return
        }

        // Check if this is an OAuth callback
        if url.scheme == "exfig", url.host == "oauth" {
            handleOAuthCallback(url)
        }
    }

    private func handleOAuthCallback(_ url: URL) {
        // Notify observers about the OAuth callback
        NotificationCenter.default.post(
            name: .oauthCallback,
            object: nil,
            userInfo: ["url": url]
        )

        // Call the direct callback if set
        onOAuthCallback?(url)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when an OAuth callback URL is received.
    static let oauthCallback = Notification.Name("ExFigStudioOAuthCallback")
}
