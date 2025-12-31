import SwiftUI
import WebKit

// MARK: - OAuth Web View

/// WKWebView wrapper for OAuth authentication flow.
struct OAuthWebView: NSViewRepresentable {
    let url: URL
    let onCallback: (URL) -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator

        // Load the OAuth URL
        webView.load(URLRequest(url: url))

        return webView
    }

    func updateNSView(_: WKWebView, context _: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCallback: onCallback, onCancel: onCancel)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate {
        let onCallback: (URL) -> Void
        let onCancel: () -> Void

        init(onCallback: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
            self.onCallback = onCallback
            self.onCancel = onCancel
        }

        @MainActor
        func webView(
            _: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            // Check if this is our OAuth callback
            if url.scheme == "exfig", url.host == "oauth" {
                onCallback(url)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
            // Handle navigation errors
            let nsError = error as NSError
            if nsError.code == NSURLErrorCancelled {
                // User cancelled, ignore
                return
            }
            onCancel()
        }

        func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
            // Handle provisional navigation errors (before loading starts)
            let nsError = error as NSError
            if nsError.code == NSURLErrorCancelled {
                return
            }
            onCancel()
        }
    }
}

// MARK: - OAuth Web View Sheet

/// Sheet wrapper for OAuth authentication in a window.
struct OAuthWebViewSheet: View {
    let url: URL
    let onCallback: (URL) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Sign in to Figma")
                    .font(.headline)

                Spacer()

                Button("Cancel") {
                    onCancel()
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(.bar)

            Divider()

            // Web view
            OAuthWebView(url: url) { callbackURL in
                onCallback(callbackURL)
                dismiss()
            } onCancel: {
                onCancel()
                dismiss()
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
}

// MARK: - Preview

#Preview {
    OAuthWebViewSheet(
        // swiftlint:disable:next force_unwrapping
        url: URL(string: "https://www.figma.com/oauth?client_id=test")!,
        onCallback: { _ in },
        onCancel: {}
    )
}
