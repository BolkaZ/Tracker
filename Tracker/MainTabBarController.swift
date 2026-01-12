import UIKit

// MARK: - Tab Bar Controller
class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let trackersVC = TrackersViewController()
        let staticksVC = StatsViewController()

        // Настройка Tab Bar Item с кастомными картинками
        trackersVC.tabBarItem = UITabBarItem(title: NSLocalizedString("Трекеры", comment: "Tab title trackers"),
                                             image: UIImage(resource: .tabTrack),
                                             selectedImage: UIImage(resource: .tabTrack))
        
        staticksVC.tabBarItem = UITabBarItem(title: NSLocalizedString("Статистика", comment: "Tab title stats"),
                                             image: UIImage(resource: .tabStat),
                                             selectedImage: UIImage(resource: .tabStat))

        viewControllers = [
            UINavigationController(rootViewController: trackersVC),
            UINavigationController(rootViewController: staticksVC)
        ]

        setupTabBarAppearance()
    }

    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(resource: .appWhite)

        // Линия
        appearance.shadowColor = UIColor(resource: .appGray)

        // Неактивное состояние
        let unselectedColor = UIColor(resource: .appGray)
        appearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: unselectedColor]

        // Активное состояние
        let selectedColor = UIColor(resource: .appBlue)
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]

        tabBar.scrollEdgeAppearance = appearance
        tabBar.standardAppearance = appearance
        
    }
}
