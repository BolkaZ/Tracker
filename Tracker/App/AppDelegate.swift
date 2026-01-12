import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static private(set) var shared: AppDelegate?
    
    private override init() {
        super.init()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AppDelegate.shared = self
        LoggingService.bootstrapIfNeeded()
        AnalyticsService.activate()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        DataBaseStore.shared.saveContextIfNeeded()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        DataBaseStore.shared.saveContextIfNeeded()
    }
    
}

