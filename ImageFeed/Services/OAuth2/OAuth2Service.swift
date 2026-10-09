// MARK: - Шпаргалка по файлу:
/// **Сервис получения токена авторизации OAuth 2.0 (Слой данных / Model)**
///
/// **За что отвечает:**
/// Сервис-синглтон (`shared`), отвечающий за авторизацию OAuth 2.0. Выполняет сетевой запрос
/// к API Unsplash для обмена одноразового `code` (полученного в `WebViewViewController`)
/// на постоянный Bearer-токен. Включает механизм защиты от race condition (состояния гонки)
/// и дублирующих запросов с одним кодом.
///
/// **Задачи:**
/// 1. Форматирует POST-запрос с параметрами `client_id`, `secret`, `redirect_uri` и `code` к API Unsplash.
/// 2. Выполняет запрос на получение токена, защищает от дублей через `lastCode`, декодирует `OAuthTokenResponseBody`.
/// 3. Сохраняет полученный `accessToken` в хранилище `OAuth2TokenStorage`.

import Foundation

final class OAuth2Service {

    // MARK: - Static Properties

    static let shared = OAuth2Service()

    // MARK: - Private Properties

    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?
    private let dataStorage = OAuth2TokenStorage.shared

    // MARK: - Public Properties

    private(set) var authToken: String? {
        get {
            return dataStorage.token
        }
        set {
            dataStorage.token = newValue
        }
    }

    // MARK: - Init

    private init() {}

    // MARK: - Public Methods

    /// Отправляет запрос в сеть, забирает OAuth-токен и защищает от повторных дублирующих запросов (состояние гонки)
    func fetchAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)

        guard lastCode != code else {
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        task?.cancel()
        lastCode = code

        guard let request = makeOAuthTokenRequest(code: code) else {
            print("[OAuth2Service] ❌ Ошибка: Не удалось создать URLRequest")
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            DispatchQueue.main.async {
                UIBlockingProgressHUD.dismiss()
                guard let self = self else { return }

                switch result {
                case .success(let body):
                    let authToken = body.accessToken
                    self.authToken = authToken
                    print("[OAuth2Service] Токен сохранён")
                    completion(.success(authToken))

                    self.task = nil
                    self.lastCode = nil

                case .failure(let error):
                    print("[fetchOAuthToken]: Ошибка запроса: \(error.localizedDescription)")
                    completion(.failure(error))

                    self.task = nil
                    self.lastCode = nil
                }
            }
        }
        self.task = task
        task.resume()
    }

    // MARK: - Private Methods

    /// Собирает POST-запрос с параметрами (client_id, secret, code) для обмена кода на токен
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard var urlComponents = URLComponents(
            string: Constants.unsplashTokenURLString
        ) else {
            print("[OAuth2Service] ❌ Ошибка: Не удалось создать URLComponents из строки: \(Constants.unsplashTokenURLString)")
            return nil
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]

        guard let url = urlComponents.url else {
            print("[OAuth2Service] ❌ Ошибка: Не удалось получить URL из urlComponents")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        return request
    }
}
