/// **Контроллер экрана авторизации с встроенным браузером (Слой представления / View Controller)**
///
/// **За что отвечает:**
/// Контроллер для отображения формы входа Unsplash OAuth во встроенном веб-браузере (`WKWebView`).
/// Отслеживает прогресс загрузки страницы через механизм KVO (`estimatedProgress`) и передает значения
/// презентеру. Перехватывает навигационные переходы через `WKNavigationDelegate`: при обнаружении
/// кода авторизации извлекает его, отменяет навигацию и передает код делегату `AuthViewController`.
///
/// **Задачи:**
/// 1. Отображает веб-страницу входа Unsplash и шкалу прогресса загрузки.
/// 2. Наблюдает за свойством `estimatedProgress` через KVO и уведомляет `presenter`.
/// 3. Перехватывает навигационные редиректы в `WKNavigationDelegate` для извлечения `code`.
/// 4. Передает полученный код делегату `WebViewViewControllerDelegate`.

import UIKit
import WebKit

// MARK: - WebViewViewControllerDelegate

/// Протокол делегата для передачи результатов авторизации в AuthViewController
protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String)
    func webViewViewControllerDidCancel(_ vc: WebViewViewController)
}

// MARK: - WebViewViewControllerProtocol

/// Интерфейс управления экраном авторизации для Презентера (MVP View Protocol)
public protocol WebViewViewControllerProtocol: AnyObject {
    var presenter: WebViewPresenterProtocol? { get set }
    func load(request: URLRequest)
    func setProgressValue(_ newValue: Float)
    func setProgressHidden(_ isHidden: Bool)
}

// MARK: - WebViewViewController

final class WebViewViewController: UIViewController, WebViewViewControllerProtocol {

    // MARK: - Public Properties

    var presenter: WebViewPresenterProtocol?
    weak var delegate: WebViewViewControllerDelegate?

    // MARK: - Private UI Properties

    private let webView: WKWebView = {
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.accessibilityIdentifier = "UnsplashWebView"
        return webView
    }()

    private let progressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        setupUI()
        setupConstraints()

        webView.addObserver(
            self,
            forKeyPath: #keyPath(WKWebView.estimatedProgress),
            options: .new,
            context: nil
        )

        presenter?.viewDidLoad()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }

    // MARK: - KVO

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            presenter?.didUpdateProgressValue(webView.estimatedProgress)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    // MARK: - WebViewViewControllerProtocol

    /// Обновляет значение индикатора прогресса
    func setProgressValue(_ newValue: Float) {
        progressView.progress = newValue
    }

    /// Показывает или скрывает индикатор прогресса
    func setProgressHidden(_ isHidden: Bool) {
        progressView.isHidden = isHidden
    }

    /// Загружает подготовленный URLRequest в WKWebView
    func load(request: URLRequest) {
        webView.load(request)
    }

    // MARK: - Private Methods

    /// Добавляет UI-компоненты на главный экран
    private func setupUI() {
        view.addSubview(webView)
        view.addSubview(progressView)
    }

    /// Устанавливает Auto Layout ограничения
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

    /// Перехватывает каждый переход внутри webView; при наличии авторизационного кода отменяет навигацию и передает код делегату
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

    /// Извлекает параметр `code` из ссылки редиректа с помощью презентера
    private func code(from navigationAction: WKNavigationAction) -> String? {
        if let url = navigationAction.request.url {
            return presenter?.code(from: url)
        }
        return nil
    }
}
