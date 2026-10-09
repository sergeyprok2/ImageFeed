/// **Контроллер экрана авторизации (Слой представления / View Controller)**
///
/// **За что отвечает:**
/// Контроллер экрана авторизации. Управляет кнопкой входа и переходом на `WebViewViewController`.
/// Выступает делегатом для `WebViewViewController`: получает код авторизации, запрашивает Bearer-токен через `OAuth2Service`
/// и сохраняет его в `OAuth2TokenStorage`. Уведомляет `SplashViewController` об успешном входе через `AuthViewControllerDelegate`.
///
/// **Задачи:**
/// 1. Отображает UI с кнопкой входа и фирменным логотипом приложения.
/// 2. Настраивает и презентует `WebViewViewController` вместе с презентером `WebViewPresenter` и помощником `AuthHelper`.
/// 3. Обрабатывает полученный `code` авторизации от `WebViewViewControllerDelegate`, совершая обмен на токен с отображением `UIBlockingProgressHUD`.
/// 4. Показывает предупреждающий `UIAlertController` в случае ошибки получения токена.

import UIKit
import ProgressHUD

// MARK: - AuthViewControllerDelegate

/// Протокол для уведомления родительского контроллера (SplashViewController) об успешной авторизации
protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController)
}

// MARK: - AuthViewController

final class AuthViewController: UIViewController {

    // MARK: - Public Properties

    weak var delegate: AuthViewControllerDelegate?

    // MARK: - Private Properties

    private let showWebViewSegueIdentifier = "ShowWebView"
    private let oauth2Service = OAuth2Service.shared
    private let oauth2TokenStorage = OAuth2TokenStorage.shared

    // MARK: - UI Components

    private lazy var button: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(named: "YP White (iOS)")
        button.setTitle("Войти", for: .normal)
        button.setTitleColor(UIColor(named: "YP Black (iOS)"), for: .normal)
        button.layer.cornerRadius = 16
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "Authenticate"
        return button
    }()

    private lazy var icon: UIImageView = {
        let logo = UIImageView()
        logo.image = UIImage(named: "auth_screen_logo")
        logo.translatesAutoresizingMaskIntoConstraints = false
        return logo
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black (iOS)")
        configureBackButton()
        setupUI()
        setupConstraints()
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func didTapButton() {
        let webViewViewController = WebViewViewController()
        let authHelper = AuthHelper()
        let webViewPresenter = WebViewPresenter(authHelper: authHelper)

        webViewViewController.presenter = webViewPresenter
        webViewPresenter.view = webViewViewController
        webViewViewController.delegate = self

        navigationController?.pushViewController(webViewViewController, animated: true)
    }

    // MARK: - Private Methods

    /// Добавляет UI-компоненты на экран
    private func setupUI() {
        view.addSubview(button)
        view.addSubview(icon)
    }

    /// Устанавливает верстку Auto Layout
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -90),
            button.heightAnchor.constraint(equalToConstant: 48),

            icon.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            icon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            icon.heightAnchor.constraint(equalToConstant: 60),
            icon.widthAnchor.constraint(equalToConstant: 60)
        ])
    }

    /// Настраивает кастомную иконку и внешний вид кнопки «Назад» в Navigation Bar
    private func configureBackButton() {
        navigationController?.navigationBar.backIndicatorImage = UIImage(named: "nav_back_button")
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "nav_back_button")

        navigationItem.backBarButtonItem = UIBarButtonItem(
            title: "",
            style: .plain,
            target: nil,
            action: nil
        )

        navigationItem.backBarButtonItem?.tintColor = UIColor(named: "YP Black (iOS)")
    }

    /// Отображает модальное окно ошибки авторизации
    func showAuthErrorAlert() {
        let alertController = UIAlertController(
            title: "Что-то пошло не так",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "Ок", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - WebViewViewControllerDelegate

extension AuthViewController: WebViewViewControllerDelegate {

    /// Получает код авторизации от WebView, обменивает его на токен через OAuth2Service и сохраняет результат
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        UIBlockingProgressHUD.show()

        oauth2Service.fetchAuthToken(code) { [weak self] result in
            UIBlockingProgressHUD.dismiss()

            guard let self = self else { return }

            switch result {
            case .success(let token):
                print("Успешно получен токен: \(token)")
                self.delegate?.didAuthenticate(self)

            case .failure(let error):
                print("[AuthViewController] Ошибка получения токена: \(error)")
                DispatchQueue.main.async {
                    self.showAuthErrorAlert()
                }
            }
        }
    }

    /// Срабатывает при отмене авторизации пользователем — возвращает на предыдущий экран
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        navigationController?.popViewController(animated: true)
    }
}
