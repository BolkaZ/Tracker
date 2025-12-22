import UIKit

// MARK: - Tab Bar Controller
class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let trackersVC = TrackersViewController()
        let staticksVC = StatsViewController()

        // Настройка Tab Bar Item с кастомными картинками
        trackersVC.tabBarItem = UITabBarItem(title: "Трекеры",
                                             image: UIImage(named: "TabTrack"),
                                             selectedImage: UIImage(named: "TabTrack"))
        
        staticksVC.tabBarItem = UITabBarItem(title: "Статистика",
                                          image: UIImage(named: "TabStat"),
                                          selectedImage: UIImage(named: "TabStat"))

        viewControllers = [
            UINavigationController(rootViewController: trackersVC),
            UINavigationController(rootViewController: staticksVC)
        ]

        setupTabBarAppearance()
    }

    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white

        // Линия
        appearance.shadowColor = UIColor(named: "AppGray")

        // Неактивное состояние
        let unselectedColor = UIColor(named: "AppGray") ?? UIColor.gray
        appearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: unselectedColor]

        // Активное состояние
        let selectedColor = UIColor(named: "AppBlue") ?? UIColor.systemBlue
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]

        tabBar.scrollEdgeAppearance = appearance
        tabBar.standardAppearance = appearance
        
    }
}
