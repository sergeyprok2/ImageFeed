// MARK: - Шпаргалка по файлу:
// 🏛 АРХИТЕКТУРНЫЙ КОНТЕКСТ:
// Контроллер экрана авторизации. Управляет кнопкой входа и переходом на `WebViewViewController`.
// Выступает делегатом для `WebViewViewController`: получает код авторизации, запрашивает Bearer-токен через `OAuth2Service`
// и сохраняет его в `OAuth2TokenStorage`. Уведомляет `SplashViewController` об успешном входе через `AuthViewControllerDelegate`.
//
// 📌 КЛЮЧЕВЫЕ СВОЙСТВА И МЕТОДЫ:
// 1. delegate — слабый (weak) делегат для передачи события успешной авторизации наверх.
// 2. oauth2Service — сервис для выполнения сетевого запроса на обмен кода авторизации на токен.
// 3. oauth2TokenStorage — хранилище для сохранения полученного авторизационного токена.
// 4. webViewViewController(_:didAuthenticateWithCode:) — обрабатывает полученный код, блокирует UI через HUD и запрашивает токен.
// 5. configureBackButton() — кастомизирует внешнее отображение кнопки «Назад» в Navigation Bar.


import UIKit
import ProgressHUD

// 💡 ПРОТОКОЛ: Позволяет передать событие об успешном входе наверх (в SplashViewController)
protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController)
}

final class AuthViewController: UIViewController {
    private let showWebViewSegueIdentifier = "ShowWebView"
    private let oauth2Service = OAuth2Service.shared
    private let oauth2TokenStorage = OAuth2TokenStorage.shared
    
    weak var delegate: AuthViewControllerDelegate?
    
    private lazy var button: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(named: "YP White (iOS)")
        button.setTitle("Войти", for: .normal)
        button.setTitleColor(UIColor(named: "YP Black (iOS)"), for: .normal)
        button.layer.cornerRadius = 16
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var icon: UIImageView = {
        let logo = UIImageView()
        logo.image = UIImage(named: "auth_screen_logo")
        logo.translatesAutoresizingMaskIntoConstraints = false
        return logo
    }()

    // 💡 ЖИЗНЕННЫЙ ЦИКЛ: При загрузке экрана кастомизирует кнопку «Назад» в Navigation Bar
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black (iOS)")
        configureBackButton()
        setupUI()
        setupConstraints()
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        
    }
    
    private func setupUI() {
        view.addSubview(button)
        view.addSubview(icon)
    }

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
    
    @objc private func didTapButton() {
        let webViewViewController = WebViewViewController()
        webViewViewController.delegate = self
        navigationController?.pushViewController(webViewViewController, animated: true)
    }

    // 💡 НАВИГАЦИЯ: Подготавливает переход на WebViewViewController и назначает себя его делегатом
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        guard segue.identifier == showWebViewSegueIdentifier else {
//            super.prepare(for: segue, sender: sender)
//            return
//        }
//
//        guard let webViewViewController = segue.destination as? WebViewViewController else {
//            assertionFailure("Failed to prepare for \(showWebViewSegueIdentifier)")
//            return
//        }
//
//        webViewViewController.delegate = self
//    }

    // 💡 ВНЕШНИЙ ВИД: Настраивает кастомную иконку и внешний вид кнопки «Назад»
    private func configureBackButton() {
        navigationController?.navigationBar.backIndicatorImage =
            UIImage(named: "nav_back_button")

        navigationController?.navigationBar.backIndicatorTransitionMaskImage =
            UIImage(named: "nav_back_button")

        navigationItem.backBarButtonItem = UIBarButtonItem(
            title: "",
            style: .plain,
            target: nil,
            action: nil
        )

        navigationItem.backBarButtonItem?.tintColor = UIColor(named: "YP Black (iOS)")
    }
}

// MARK: - WebViewViewControllerDelegate

extension AuthViewController: WebViewViewControllerDelegate {
    
    // 💡 ДЕЛЕГАТ ВЕБ-ВЬЮ: Получает код авторизации от WebView, обменивает его на токен через OAuth2Service и сохраняет результат
    func webViewViewController(_ vc: WebViewViewController,didAuthenticateWithCode code: String) {

        // Показываем индикатор загрузки
        UIBlockingProgressHUD.show()
        
        oauth2Service.fetchAuthToken(code) { [weak self] result in
            // Скрываем индикатор загрузки
            // Это действие выполняется только один раз до кейсов `switch`, потому что индикатор нужно скрыть при любом исходе сетевого запроса - как при успехе, так и при ошибке.
            UIBlockingProgressHUD.dismiss()
            
            guard let self = self else {
                return
            }

            switch result {
            case .success(let token):
                print("Успешно получен токен: \(token)")
                // Уведомляем делегат (SplashViewController) об успешной авторизации
                self.delegate?.didAuthenticate(self)

            case .failure(let error):
                print("[AuthViewController] Ошибка получения токена: \(error)")
                DispatchQueue.main.async {
                    self.showAuthErrorAlert()
                }
            }
        }
    }

    // 💡 ДЕЛЕГАТ ВЕБ-ВЬЮ: Срабатывает при отмене авторизации пользователем — возвращает на предыдущий экран
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        navigationController?.popViewController(animated: true)
    }
}

extension AuthViewController {
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


