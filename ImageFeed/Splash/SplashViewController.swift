// MARK: - Шпаргалка по файлу:
// 🏛 АРХИТЕКТУРНЫЙ КОНТЕКСТ:
// Стартовый (Splash) контроллер приложения, выполняющий роль маршрутизатора (Flow Manager) при запуске.
// Проверяет наличие авторизационного токена: если токен есть — загружает профиль через `ProfileService` и переключает на главный `TabBarController`; если нет — отправляет на экран авторизации (`AuthViewController`). Подписывается на `AuthViewControllerDelegate`.
//
// 📌 КЛЮЧЕВЫЕ СВОЙСТВА И МЕТОДЫ:
// 1. viewDidAppear(_:) — точка входа для принятия решения о навигации (проверка токена в `OAuth2TokenStorage`).
// 2. prepare(for:sender:) — передает текущий экземпляр как делегат в `AuthViewController` при переходе по segue.
// 3. didAuthenticate(_:) — реализация делегата авторизации: закрывает экран входа и запускает загрузку профиля.
// 4. fetchProfile(token:) — запрашивает данные пользователя из `ProfileService` с отображением `UIBlockingProgressHUD`.
// 5. switchToTabBarController() — жестко подменяет `rootViewController` основного окна приложения на `TabBarViewController`.

import UIKit
import WebKit

// MARK: - Шпаргалка по файлу:
// 1. viewDidAppear — точка принятия решения при старте (есть токен -> качаем профиль, нет -> показ экрана авторизации).
// 2. didAuthenticate — ловит событие успешного входа из AuthViewController и запускает загрузку профиля.
// 3. fetchProfile — показывает UIBlockingProgressHUD, делает запрос через ProfileService и при успехе вызывает switchToTabBarController.
// 4. switchToTabBarController — жестко подменяет window.rootViewController со Splash-экрана на главную ленту с табами.

final class SplashViewController: UIViewController {
    
    private let profileService = ProfileService.shared
    private let storage = OAuth2TokenStorage.shared
    
    private lazy var splashLogo: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "AppLogo")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(named: "YP Black (iOS)")
        setupUI()
        setupConstraints()
    }
    
    // 💡 ЖИЗНЕННЫЙ ЦИКЛ: Срабатывает при появлении экрана. Проверяет наличие токена: качает профиль или отправляет на вход.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let token = storage.token {
            // Пользователь авторизован — грузим профиль
            fetchProfile(token: token)
        } else {
            // Пользователь НЕ авторизован — показываем экран авторизации из Storyboard
            showAuthViewController()
        }
    }
    
    // Вся логика перехода на AuthViewController кодом:
    private func showAuthViewController() {
        let authVC = AuthViewController()
        let navigation = UINavigationController(rootViewController: authVC)
        
        // 1. Выставляем делегатом себя
        authVC.delegate = self
        
        // 2. Режим fullScreen
        authVC.modalPresentationStyle = .fullScreen
        
        // 3. Презентуем
        present(navigation, animated: true)
    }

    // 💡 ЖИЗНЕННЫЙ ЦИКЛ: Обновляет статус-бар перед появлением экрана.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }

    // 💡 НАСТРОЙКА: Делает иконки статус-бара (часы, батарейку) светлыми.
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    private func setupUI() {
        view.addSubview(splashLogo)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            splashLogo.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            splashLogo.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
        ])
    }
    
}

// MARK: - AuthViewControllerDelegate & Profile Loading

extension SplashViewController: AuthViewControllerDelegate {
    // 💡 ДЕЛЕГАТ: Срабатывает, когда пользователь успешно вошел. Закрывает экран входа и запускает загрузку профиля.
    func didAuthenticate(_ vc: AuthViewController) {
        vc.dismiss(animated: true)
        guard let token = storage.token else { return }
        fetchProfile(token: token)
    }
    
    // 💡 СЕТЕВОЙ ВЫЗОВ: Показывает лоадер (HUD), качает профиль через ProfileService и при успехе переключает экран.
    private func fetchProfile(token: String) {
        UIBlockingProgressHUD.show()
        
        profileService.fetchProfile(token) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            
            guard let self = self else { return }
            switch result {
            case .success(let profile):
                print("все хорошо")
                
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { imageResult in
                    DispatchQueue.main.async {
                        switch imageResult{
                        case .success(let url):
                            print("🔍 [SplashVC]: Аватарка получена в комплишене: \(url)")
                        case .failure(let error):
                            print("❌ [SplashVC]: Ошибка получения аватарки в комплишене: \(error)")
                        }
                        self.switchToTabBarController()
                    }
                }
            case.failure(let error):
                print("Ошибка получения профиля: \(error)")
                break
            }
        }
    }
    
    // 💡 СМЕНА ЭКРАНА: Подменяет главный rootViewController приложения на TabBarViewController (главные экраны).
    private func switchToTabBarController() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
                assertionFailure("Invalid window configuration")
                return
        }
        
        // чистое создание контроллера:
        let tabBarController = TabBarController()
           
        // Установим в `rootViewController` полученный контроллер
        window.rootViewController = tabBarController
    }
}




