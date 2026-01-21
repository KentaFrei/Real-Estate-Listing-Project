import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

        // ⚠️ Token statico salvato per test - RIMUOVERE IN PRODUZIONE
        #if DEBUG
        let testToken = "c317d24ca043bf52e826c62c00213691a7676618"
        UserDefaults.standard.set(testToken, forKey: "authToken")
        print("🔑 Token di test salvato in UserDefaults")
        #endif

        // Controlla se esiste un token per decidere la schermata iniziale
        if UserDefaults.standard.string(forKey: "authToken") != nil {
            window?.rootViewController = MainTabBarController()
        } else {
            window?.rootViewController = LoginViewController()
        }
        
        window?.makeKeyAndVisible()
    }
}








