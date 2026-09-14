//
//

import UIKit
import WebKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        #warning("Закомментировать сброс!")
        OAuth2TokenStorage.shared.token = nil; WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast, completionHandler: {}) // Сброс для тестов

        print("=== ВСЕ КЛЮЧИ В USERDEFAULTS AppDelegate ===")
        let allDictionary = UserDefaults.standard.dictionaryRepresentation()
        
        // Фильтруем системные ключи Apple и оставляем только твои
        for (key, value) in allDictionary {
            if !key.hasPrefix("Apple") && !key.hasPrefix("NS") {
                print("Найден ключ: '\(key)' === Значение: \(value)")
            }
        }
        print("================================")
        configureTabBarAppearance()
        // Override point for customization after application launch.
        return true
    }
    
    // MARK:  Private function

    private func configureTabBarAppearance() {
        let backgroundColor = UIColor(named: "YP Black (iOS)") ?? .black
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = backgroundColor
        appearance.shadowColor = .clear

        let tabBarAppearance = UITabBar.appearance()
        tabBarAppearance.standardAppearance = appearance
        tabBarAppearance.scrollEdgeAppearance = appearance
        tabBarAppearance.backgroundColor = backgroundColor
        tabBarAppearance.isTranslucent = false
    }

    // MARK: UISceneSession Lifecycle

//    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
//        // Called when a new scene session is being created.
//        // Use this method to select a configuration to create the new scene with.
//        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
//    }
    
    func application(_ application: UIApplication,configurationForConnecting connectingSceneSession: UISceneSession,options: UIScene.ConnectionOptions) -> UISceneConfiguration {
       let sceneConfiguration = UISceneConfiguration(name: "Main",sessionRole: connectingSceneSession.role)
       sceneConfiguration.delegateClass = SceneDelegate.self   // 2
       return sceneConfiguration
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

