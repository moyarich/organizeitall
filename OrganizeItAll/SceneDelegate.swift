import SwiftData
import SwiftUI
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)

        if #available(iOS 17.0, *) {
            let rootView = OrganizeItAllRootView()
                .modelContainer(PersistenceController.shared.container)
            window.rootViewController = UIHostingController(rootView: rootView)
        } else {
            window.rootViewController = UIHostingController(rootView: UnsupportedSystemView())
        }

        self.window = window
        window.makeKeyAndVisible()
    }
}

private struct UnsupportedSystemView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone")
                .font(.system(size: 44))
            Text("iOS 17 Required")
                .font(.title2.bold())
            Text("This version of OrganizeItAll uses SwiftData and requires iOS 17 or later.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
