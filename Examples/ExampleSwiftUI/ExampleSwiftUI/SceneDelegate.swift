import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        let contentView = ContentView()

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            window.tintColor = UIColor(named: "tint")
            self.window = window
            window.makeKeyAndVisible()
        }

        setupAppearance()
    }

    private func setupAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.font: UIFont.largeTitle(),
            NSAttributedString.Key.foregroundColor: UIColor.textSecondary,
        ]
        appearance.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.header(),
            NSAttributedString.Key.foregroundColor: UIColor.textSecondary,
        ]
        UINavigationBar.appearance().standardAppearance = appearance
    }
}
