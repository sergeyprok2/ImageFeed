// MARK: - Шпаргалка по файлу:
// 🏛 АРХИТЕКТУРНЫЙ КОНТЕКСТ:
// Сервис-синглтон (`shared`), отвечающий за авторизацию OAuth 2.0.
// Выполняет сетевой запрос к API Unsplash для обмена одноразового `code` (полученного в `WebViewViewController`)
// на постоянный Bearer-токен. Включает механизм защиты от race condition (состояния гонки) и дублирующих запросов с одним кодом.
// Вызывается из `AuthViewController`.
//
// 📌 КЛЮЧЕВЫЕ СВОЙСТВА И МЕТОДЫ:
// 1. shared & init() — реализации паттерна Singleton для единой точки доступа.
// 2. task & lastCode — хранение текущей сетевой таски и последнего запрошенного кода для отмены дублей и предпреждения гонки.
// 3. makeOAuthTokenRequest(code:) — собирает POST-запрос с параметрами авторизации (client_id, secret, redirect_uri, code).
// 4. fetchAuthToken(_:completion:) — отменяет предыдущую таску, проверяет код на уникальность, исполняет сетевой запрос и декодирует результат в `OAuthTokenResponseBody`.

import Foundation

// MARK: - Шпаргалка по файлу:
// 1. makeOAuthTokenRequest — форматирует POST-запрос с параметрами client_id, secret, redirect_uri и code к API Unsplash.
// 2. fetchAuthToken — выполняет запрос на получение токена, проверяет от дублей через lastCode, декодирует OAuthTokenResponseBody и возвращает accessToken.

// MARK: - OAuth2Service (Сервис получения токена авторизации)

class OAuth2Service {
    static let shared = OAuth2Service()
    init() {} // Запрещаем создавать другие экземпляры (синглтон)
    
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?
    private let dataStorage = OAuth2TokenStorage.shared

    private(set) var authToken: String? {
        get {
            return dataStorage.token
        }
        set {
            dataStorage.token = newValue
        }
    }

    // 💡 МЕТОД 1: Собирает POST-запрос с параметрами (client_id, secret, code) для обмена кода на токен
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard var urlComponents = URLComponents(
            string: WebViewConstants.unsplashTokenURLString
        ) else {
            print("[OAuth2Service] ❌ Ошибка: Не удалось создать URLComponents из строки: \(WebViewConstants.unsplashTokenURLString)")
            return nil
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret",value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri",value: Constants.redirectURI),
            URLQueryItem(name: "code",value: code),
            URLQueryItem(name: "grant_type",value: "authorization_code")
        ]

        guard let url = urlComponents.url else {
            print("[OAuth2Service] ❌ Ошибка: Не удалось получить URL из urlComponents")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        return request
    }

    // 💡 МЕТОД 2: Отправляет запрос в сеть, забирает OAuth-токен и защищает от повторных дублирующих запросов (состояние гонки)
    func fetchAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        // Защита: если передали тот же код, что и в прошлый раз, отменяем вызов
        guard lastCode != code else {
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        task?.cancel() 
        lastCode = code
        
        // 💡 Проверяем, удалось ли собрать URLRequest; если нет — завершаем метод с ошибкой
        guard let request = makeOAuthTokenRequest(code: code) else {
            print("[OAuth2Service] ❌ Ошибка: Не удалось создать URLRequest")
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        // 💡 Запускает сетевой запрос и принимает ответ от сервера (данные или ошибку)
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            DispatchQueue.main.async {
                UIBlockingProgressHUD.dismiss()
                guard let self = self else { return }

                switch result {
                case .success(let body):
                    let authToken = body.accessToken
                    self.authToken = authToken // сохраняем в свойство
                    print("[OAuth2Service] Токен сохранён")
                    completion(.success(authToken)) // возвращаем наружу

                    self.task = nil
                    self.lastCode = nil

                case .failure(let error):
                    print("[fetchOAuthToken]: Ошибка запроса: \(error.localizedDescription)")
                    completion(.failure(error)) // ошибка

                    self.task = nil
                    self.lastCode = nil
                }
            }
        }
        self.task = task
        task.resume()
    }
}
