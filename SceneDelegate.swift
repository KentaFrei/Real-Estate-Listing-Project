import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

        window?.rootViewController = MainTabBarController()
        window?.makeKeyAndVisible()
    }
    
    // MARK: - Helper per cambiare root view controller
    func setRootViewController(_ viewController: UIViewController, animated: Bool = true) {
        guard let window = window else { return }
        
        if animated {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = viewController
            })
        } else {
            window.rootViewController = viewController
        }
        window.makeKeyAndVisible()
    }
}









