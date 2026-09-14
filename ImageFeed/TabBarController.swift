




import UIKit

final class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Настройка внешнего вида самого TabBar
        tabBar.backgroundColor = UIColor(named: "YP Black (iOS)")
        tabBar.tintColor = .white
        
        // 2. Инициализация экранов
        let imagesListViewController = ImagesListViewController()
        imagesListViewController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab_editorial_active"),
            selectedImage: nil
        )
        
        let profileViewController = ProfileViewController()
        profileViewController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab_profile_active"),
            selectedImage: nil
        )
        
        // 3. Назначение дочерних контроллеров
        self.viewControllers = [imagesListViewController, profileViewController]
    }
}
       
