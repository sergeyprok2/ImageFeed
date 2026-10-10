/// **Стартовый контроллер приложения (Flow Manager / Слой навигации)**
///
/// **За что отвечает:**
/// Стартовый (Splash) контроллер приложения, выполняющий роль маршрутизатора (Flow Manager) при запуске.
/// Проверяет наличие авторизационного токена: если токен есть — загружает профиль через `ProfileService`
/// и переключает на главный `TabBarController`; если нет — отправляет на экран авторизации (`AuthViewController`).
///
/// **Задачи:**
/// 1. При открытии проверяет токен в `OAuth2TokenStorage`.
/// 2. Презентует `AuthViewController` при отсутствии токена.
/// 3. Загружает профиль пользователя и URL аватара при наличии токена.
/// 4. Подменяет `rootViewController` окна приложения на `TabBarController` при успешном входе.

import UIKit

final class SplashViewController: UIViewController {

    // MARK: - Private Properties

    private let profileService = ProfileService.shared
    private let storage = OAuth2TokenStorage.shared

    // MARK: - UI Components

    private lazy var splashLogo: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "AppLogo")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(named: "YP Black (iOS)")
        setupUI()
        setupConstraints()
    }

    /// Срабатывает при появлении экрана. Проверяет наличие токена: качает профиль или отправляет на вход.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let token = storage.token {
            fetchProfile(token: token)
        } else {
            showAuthViewController()
        }
    }

    /// Обновляет статус-бар перед появлением экрана.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }

    /// Делает иконки статус-бара (часы, батарейку) светлыми.
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    // MARK: - Private Methods

    private func setupUI() {
        view.addSubview(splashLogo)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            splashLogo.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            splashLogo.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
        ])
    }

    /// Вся логика перехода на AuthViewController кодом
    private func showAuthViewController() {
        let authVC = AuthViewController()
        let navigation = UINavigationController(rootViewController: authVC)

        authVC.delegate = self
        authVC.modalPresentationStyle = .fullScreen

        present(navigation, animated: true)
    }

    /// Показывает лоадер (HUD), качает профиль через ProfileService и при успехе переключает экран.
    private func fetchProfile(token: String) {
        UIBlockingProgressHUD.show()

        profileService.fetchProfile(token) { [weak self] result in
            UIBlockingProgressHUD.dismiss()

            guard let self = self else { return }
            switch result {
            case .success(let profile):
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { imageResult in
                    DispatchQueue.main.async {
                        switch imageResult {
                        case .success(let url):
                            print("🔍 [SplashVC]: Аватарка получена в комплишене: \(url)")
                        case .failure(let error):
                            print("❌ [SplashVC]: Ошибка получения аватарки в комплишене: \(error)")
                        }
                        self.switchToTabBarController()
                    }
                }
            case .failure(let error):
                print("Ошибка получения профиля: \(error)")
            }
        }
    }

    /// Подменяет главный rootViewController приложения на TabBarController (главные экраны).
    private func switchToTabBarController() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
                assertionFailure("Invalid window configuration")
                return
        }

        let tabBarController = TabBarController()
        window.rootViewController = tabBarController
    }
}

// MARK: - AuthViewControllerDelegate

extension SplashViewController: AuthViewControllerDelegate {

    /// Срабатывает, когда пользователь успешно вошел. Закрывает экран входа и запускает загрузку профиля.
    func didAuthenticate(_ vc: AuthViewController) {
        vc.dismiss(animated: true)
        guard let token = storage.token else { return }
        fetchProfile(token: token)
    }
}




