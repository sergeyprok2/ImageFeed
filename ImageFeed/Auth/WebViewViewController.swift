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
enum WebViewConstants {
    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
    static let unsplashTokenURLString = "https://unsplash.com/oauth/token"
}

// 💡 ПРОТОКОЛ: Сообщает в AuthViewController, что пользователь вошел (передал код) или отменил вход
protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String)
    func webViewViewControllerDidCancel(_ vc: WebViewViewController)
}


final class WebViewViewController: UIViewController {
    
    private let webView: WKWebView = {
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()
    
    private let progressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    // MARK: - Properties
    
    weak var delegate: WebViewViewControllerDelegate?
    private var estimatedProgressObservation: NSKeyValueObservation?
    
    // MARK: - Lifecycle
    
    // 💡 ЖИЗНЕННЫЙ ЦИКЛ: Назначает делегат для webView и запускает загрузку страницы входа
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        loadAuthView()
        setupUI()
        setupConstraints()
        
        // 💡 НАБЛЮДАТЕЛЬ (KVO): Ловит изменения шкалы загрузки и обновит полоску progressView
        estimatedProgressObservation = webView.observe(
            \.estimatedProgress,
            options: [],
            changeHandler: { [weak self] _, _ in
                guard let self = self else { return }
                self.updateProgress()
            }
        )
    }
    
    private func setupUI() {
        view.addSubview(webView)
        view.addSubview(progressView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.topAnchor.constraint(equalTo: progressView.topAnchor)
        ])
    }
    
    // 💡 ЖИЗНЕННЫЙ ЦИКЛ: Включает наблюдение (KVO) за полоской прогресса загрузки страницы
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // 💡 ЖИЗНЕННЫЙ ЦИКЛ: Отключает наблюдение за полоской прогресса при уходе с экрана
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

}

// MARK: - WKNavigationDelegate

extension WebViewViewController: WKNavigationDelegate {
    
    // 💡 ДЕЛЕГАТ НАВИГАЦИИ: Перехватывает каждый переход внутри webView; если в ссылке есть authorization code, передает его делегату и отменяет загрузку
    func webView(_ webView: WKWebView,decidePolicyFor navigationAction: WKNavigationAction,decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
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
    
    // MARK: - Private Methods

    // 💡 ВНЕШНИЙ ВИД: Обновляет процент полоски progressView и скрывает её, когда загрузка доходит до 100%
    private func updateProgress() {
        progressView.progress = Float(webView.estimatedProgress)
        progressView.isHidden = fabs(webView.estimatedProgress - 1.0) <= 0.0001
    }
    
    // 💡 СЕТЕВОЙ ЗАПРОС: Собирает URL для авторизации (с client_id и redirect_uri) и загружает его в webView
    private func loadAuthView() {
        guard var urlComponents = URLComponents(string: WebViewConstants.unsplashAuthorizeURLString) else {
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Constants.accessScope)
        ]
        
        guard let url = urlComponents.url else {
            return
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    // 💡 ВСПОМОГАТЕЛЬНЫЙ МЕТОД: Достает значение параметра `code` из ссылки редиректа после успешного входа
    private func code(from navigationAction: WKNavigationAction) -> String? {
        if
            let url = navigationAction.request.url,
            let urlComponents = URLComponents(string: url.absoluteString),
            urlComponents.path == "/oauth/authorize/native",
            let items = urlComponents.queryItems,
            let codeItem = items.first(where: { $0.name == "code" }) {
            return codeItem.value
        } else {
            return nil
        }
    }
}
