/// **Сервис загрузки и хранения профиля авторизованного пользователя (Слой данных / Model)**
///
/// **За что отвечает:**
/// Сервис-синглтон (`shared`) для загрузки и хранения профиля авторизованного пользователя Unsplash.
/// Выполняет сетевой запрос к эндпоинту `/me` с заголовком авторизации Bearer, декодирует ответ
/// в сетевую модель `ProfileResult` и трансформирует её в UI-модель `Profile`.
///
/// **Задачи:**
/// 1. Собирает авторизованный GET-запрос к эндпоинту `/me`.
/// 2. Выполняет сетевой запрос и конвертирует полученный DTO в UI-модель `Profile`.
/// 3. Хранит текущий загруженный профиль пользователя в свойстве `profile`.

import Foundation

// MARK: - Nested Types

/// UI-модель профиля пользователя
struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String?
}

/// Сетевая DTO-модель ответа Unsplash API при запросе данных профиля
struct ProfileResult: Codable {
    let username: String
    let firstName: String
    let lastName: String?
    let bio: String?

    private enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
    }
}

// MARK: - ProfileService

final class ProfileService {

    // MARK: - Static Properties

    static let shared = ProfileService()

    // MARK: - Public Properties

    /// Публичное свойство для чтения текущего профиля пользователя
    private(set) var profile: Profile?

    // MARK: - Private Properties

    private var task: URLSessionTask?
    private let urlSession = URLSession.shared

    // MARK: - Init

    private init() {}

    // MARK: - Public Methods

    /// Скачивает данные профиля из сети, превращает их в модель Profile и сохраняет в self.profile
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        task?.cancel()

        guard let request = makeProfileRequest(token: token) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<ProfileResult, Error>) in
            switch result {
            case .success(let result):
                let lastName = result.lastName ?? ""
                let profile = Profile(
                    username: result.username,
                    name: "\(result.firstName) \(lastName)".trimmingCharacters(in: .whitespaces),
                    loginName: "@\(result.username)",
                    bio: result.bio
                )

                self?.profile = profile
                completion(.success(profile))

            case .failure(let error):
                print("[fetchProfile]: Ошибка запроса: \(error.localizedDescription)")
                completion(.failure(error))
            }
            self?.task = nil
        }

        self.task = task
        task.resume()
    }

    /// Очищает сохраненный профиль при выходе из аккаунта
    func clear() {
        profile = nil
    }

    // MARK: - Private Methods

    /// Собирает URL-запрос к эндпоинту /me и подставляет заголовок с токеном авторизации Bearer
    private func makeProfileRequest(token: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/me") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return request
    }
}
