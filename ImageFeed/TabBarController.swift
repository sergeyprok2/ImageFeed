/// **Корневой контроллер вкладок приложения (Flow Manager / Слой навигации)**
///
/// **За что отвечает:**
/// Кастомный `UITabBarController`, управляющий переключением между главными экранами приложения
/// (лентой фотографий и профилем пользователя). Выполняет сборку и связывание компонентов MVP
/// (View & Presenter) при старте основной сессии.
///
/// **Задачи:**
/// 1. Настраивает внешнее оформление таб-бара (цвета фона и иконок).
/// 2. Инициализирует контроллеры `ImagesListViewController` и `ProfileViewController`.
/// 3. Создает презентеры `ImagesListPresenter` и `ProfilePresenter`, устанавливая двусторонние связи MVP.
/// 4. Назначает сформированные View Controllers в свойство `viewControllers`.

import UIKit

// MARK: - TabBarController

final class TabBarController: UITabBarController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupAppearance()
        setupViewControllers()
    }

    // MARK: - Private Methods

    /// Настройка внешнего вида и стилей таб-бара
    private func setupAppearance() {
        tabBar.backgroundColor = UIColor(named: "YP Black (iOS)")
        tabBar.tintColor = .white
    }

    /// Инициализация, сборка MVP-связей и назначение дочерних контроллеров
    private func setupViewControllers() {
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

        let imagesListPresenter = ImagesListPresenter()
        imagesListViewController.presenter = imagesListPresenter
        imagesListPresenter.view = imagesListViewController

        let profilePresenter = ProfilePresenter()
        profileViewController.presenter = profilePresenter
        profilePresenter.view = profileViewController

        self.viewControllers = [imagesListViewController, profileViewController]
    }
}
       
