import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // MARK: - UIWindowSceneDelegate

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        if shouldShowOnboarding() {
            let onboarding = OnboardingPageViewController()
            onboarding.onFinish = { [weak self] in
                self?.showMainInterface()
            }
            window.rootViewController = onboarding
        } else {
            window.rootViewController = MainTabBarController()
        }
        
        window.makeKeyAndVisible()
    }
    
    // MARK: - Onboarding
    
    private func shouldShowOnboarding() -> Bool {
        return UserDefaults.standard.bool(forKey: OnboardingPageViewController.completionKey) == false
    }
    
    // MARK: - Presentation
    
    private func showMainInterface(animated: Bool = true) {
        guard let window = window else { return }
        let mainController = MainTabBarController()
        guard animated else {
            window.rootViewController = mainController
            return
        }
        
        UIView.transition(with: window,
                          duration: 0.35,
                          options: .transitionCrossDissolve,
                          animations: {
            window.rootViewController = mainController
        })
    }
}
