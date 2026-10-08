// MARK: - Шпаргалка по файлу:
// 🏛 АРХИТЕКТУРНЫЙ КОНТЕКСТ:
// Экран с встроенным браузером (`WKWebView`). Загружает форму входа Unsplash OAuth.
// Отслеживает прогресс загрузки через KVO (`estimatedProgress`) и отображает его на `UIProgressView`.
// Перехватывает навигационные переходы через `WKNavigationDelegate`: если в ссылке редиректа появляется authorization code,
// извлекает его, отменяет дальнейшую загрузку и передает в `AuthViewController` через `WebViewViewControllerDelegate`.
//
// 📌 КЛЮЧЕВЫЕ СВОЙСТВА И МЕТОДЫ:
// 1. webView & progressView — элементы UI для показа веб-страницы и индикатора прогресса.
// 2. delegate — слабый (weak) делегат для передачи полученного `code` или отмены авторизации.
// 3. loadAuthView() — формирует URL-запрос авторизации с параметрами (client_id, redirect_uri, scope) и загружает его в WKWebView.
// 4. code(from:) — разбирает параметры URL-адреса и извлекает значение query-параметра "code".
// 5. observeValue / updateProgress — механизм KVO для динамического обновления и скрытия полосы прогресса.

import UIKit
import WebKit


// 💡 КОНСТАНТЫ: Адреса сервера Unsplash для авторизации
//enum WebViewConstants {
//    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
//    static let unsplashTokenURLString = "https://unsplash.com/oauth/token"
//}

import UIKit
import WebKit

// 💡 ПРОТОКОЛ: Сообщает в AuthViewController, что пользователь вошел (передал код) или отменил вход
protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String)
    func webViewViewControllerDidCancel(_ vc: WebViewViewController)
}

// 💡 ПРОТОКОЛ ВЬЮ: Определяет интерфейс управления экраном авторизации для Презентера
public protocol WebViewViewControllerProtocol: AnyObject {
    var presenter: WebViewPresenterProtocol? { get set }
    func load(request: URLRequest)
    func setProgressValue(_ newValue: Float)
    func setProgressHidden(_ isHidden: Bool)
}

final class WebViewViewController: UIViewController, WebViewViewControllerProtocol {
    
    // MARK: - Properties
    
    // 💡 СВОЙСТВА: Ссылка на Презентер модуля авторизации
    var presenter: WebViewPresenterProtocol?
    
    // 💡 СВОЙСТВА: Делегат для передачи кода авторизации в AuthViewController
    weak var delegate: WebViewViewControllerDelegate?
    
    // MARK: - Private UI Properties
    
    // 💡 UI: Веб-представление для отображения страницы авторизации Unsplash
    private let webView: WKWebView = {
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.accessibilityIdentifier = "UnsplashWebView"

        return webView
    }()
    
    // 💡 UI: Индикатор прогресса загрузки веб-страницы
    private let progressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    // MARK: - Lifecycle
    
    // 💡 ЖИЗНЕННЫЙ ЦИКЛ: Назначает делегат для webView, настраивает UI/констрейнты, подписывается на KVO и запускает загрузку
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        setupUI()
        setupConstraints()
        
        // 💡 НАБЛЮДАТЕЛЬ (KVO): Регистрирует наблюдение за свойством estimatedProgress веб-вью
        webView.addObserver(
            self,
            forKeyPath: #keyPath(WKWebView.estimatedProgress),
            options: .new,
            context: nil
        )
        
        presenter?.viewDidLoad()
    }
    
    // 💡 ЖИЗНЕННЫЙ ЦИКЛ: Отключает наблюдение (KVO) за полоской прогресса при уходе с экрана
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }
    
    // MARK: - KVO
    
    // 💡 НАБЛЮДАТЕЛЬ (KVO): Ловит изменения шкалы загрузки и передает текущее значение в Презентер
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            presenter?.didUpdateProgressValue(webView.estimatedProgress)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK: - WebViewViewControllerProtocol
    
    // 💡 ВНЕШНИЙ ВИД: Обновляет значение процента в полоске progressView
    func setProgressValue(_ newValue: Float) {
        progressView.progress = newValue
    }

    // 💡 ВНЕШНИЙ ВИД: Скрывает или показывает полоску progressView
    func setProgressHidden(_ isHidden: Bool) {
        progressView.isHidden = isHidden
    }
    
    // 💡 СЕТЕВОЙ ЗАПРОС: Загружает подготовленный URLRequest в webView
    func load(request: URLRequest) {
        webView.load(request)
    }

    // MARK: - Private Methods
    
    // 💡 НАСТРОЙКА UI: Добавляет элементы webView и progressView на главный экран
    private func setupUI() {
        view.addSubview(webView)
        view.addSubview(progressView)
    }

    // 💡 НАСТРОЙКА UI: Устанавливает Auto Layout ограничения для позиционирования элементов
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor)
        ])
    }
}

// MARK: - WKNavigationDelegate

extension WebViewViewController: WKNavigationDelegate {
    
    // 💡 ДЕЛЕГАТ НАВИГАЦИИ: Перехватывает каждый переход внутри webView; если в ссылке есть authorization code, передает его делегату и отменяет загрузку
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        print("[LOG] Переход на URL: \(navigationAction.request.url?.absoluteString ?? "")")
        if let code = code(from: navigationAction) {
            print("🟢 [STEP 1]: WebView перехватил код authorization code = \(code)")
            print("🟢 [STEP 2]: Вызываем делегат didAuthenticateWithCode...")
            delegate?.webViewViewController(self, didAuthenticateWithCode: code)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
    
    // 💡 ВСПОМОГАТЕЛЬНЫЙ МЕТОД: Достает значение параметра `code` из ссылки редиректа после успешного входа
    private func code(from navigationAction: WKNavigationAction) -> String? {
        if let url = navigationAction.request.url {
            return presenter?.code(from: url)
        }
        return nil
    }
}
