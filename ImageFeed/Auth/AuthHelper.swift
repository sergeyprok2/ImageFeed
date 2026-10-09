/// **Вспомогательный класс для подготовки параметров и URL авторизации OAuth 2.0 (Слой бизнес-логики / Model)**
///
/// **За что отвечает:**
/// Вспомогательный класс (`AuthHelper`), инкапсулирующий логику конструирования URL-запросов авторизации
/// и извлечения авторизационного кода (`code`) из редирект-ссылки Unsplash OAuth 2.0.
///
/// **Задачи:**
/// 1. Собирает полный `URLRequest` и `URL` для загрузки веб-страницы входа с параметрами `client_id`, `redirect_uri`, `response_type` и `scope`.
/// 2. Валидирует редирект-URL после авторизации пользователя и извлекает параметрический `code`.

import Foundation

// MARK: - AuthHelperProtocol

/// Протокол вспомогательного сервиса авторизации
protocol AuthHelperProtocol {
    func authRequest() -> URLRequest?
    func code(from url: URL) -> String?
}

// MARK: - AuthHelper

final class AuthHelper: AuthHelperProtocol {

    // MARK: - Public Properties

    let configuration: AuthConfiguration

    // MARK: - Init

    init(configuration: AuthConfiguration = .standard) {
        self.configuration = configuration
    }

    // MARK: - Public Methods

    /// Собирает готовый URLRequest для загрузки страницы авторизации в WebView
    func authRequest() -> URLRequest? {
        guard let url = authURL() else { return nil }

        return URLRequest(url: url)
    }

    /// Формирует URL авторизации с необходимыми Query-параметрами на основе конфигурации
    func authURL() -> URL? {
        guard var urlComponents = URLComponents(string: configuration.authURLString) else {
            return nil
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.accessKey),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: configuration.accessScope)
        ]

        return urlComponents.url
    }

    /// Извлекает авторизационный код из URL перенаправления (callback URL)
    func code(from url: URL) -> String? {
        if let urlComponents = URLComponents(string: url.absoluteString),
           urlComponents.path == "/oauth/authorize/native",
           let items = urlComponents.queryItems,
           let codeItem = items.first(where: { $0.name == "code" }) {
            return codeItem.value
        } else {
            return nil
        }
    }
}
