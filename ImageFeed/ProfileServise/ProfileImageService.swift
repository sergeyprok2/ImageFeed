/// **Сервис получения ссылки на аватар пользователя (Слой данных / Model)**
///
/// **За что отвечает:**
/// Сервис-синглтон (`shared`) для получения URL аватарки пользователя с сервера Unsplash.
/// Выполняет запрос `GET /users/:username` с авторизационным токеном из `OAuth2TokenStorage`,
/// декодирует ответ в `UserResult` и сохраняет ссылку на картинку в `avatarURL`.
/// Предотвращает дублирование сетевых запросов (race condition) при повторных вызовах.
///
/// **Задачи:**
/// 1. Формирует авторизованный сетевой запрос для получения информации о пользователе.
/// 2. Декодирует ссылки на аватарку из ответа Unsplash API.
/// 3. Сохраняет ссылку `avatarURL` и уведомляет систему через `NotificationCenter`.

import Foundation

// MARK: - Nested Types

/// Модель ссылок на изображения аватара разного разрешения
struct ProfileImage: Codable {
    let small: String
    let medium: String
    let large: String

    private enum CodingKeys: String, CodingKey {
        case small
        case medium
        case large
    }
}

/// Модель ответа API Unsplash с объектом профиля пользователя
struct UserResult: Codable {
    let profileImage: ProfileImage

    private enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

// MARK: - ProfileImageService

final class ProfileImageService {

    // MARK: - Static Properties

    static let shared = ProfileImageService()
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")

    // MARK: - Public Properties

    /// Публичное свойство для чтения URL аватарки пользователя
    private(set) var avatarURL: String?

    // MARK: - Private Properties

    private var task: URLSessionTask?

    // MARK: - Init

    private init() {}

    // MARK: - Public Methods

    /// Запрашивает ссылку на аватар пользователя по имени пользователя
    func fetchProfileImageURL(username: String, completion: @escaping (Result<String, Error>) -> Void) {
        task?.cancel()

        guard let token = OAuth2TokenStorage.shared.token else {
            completion(.failure(NSError(domain: "ProfileImageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authorization token missing"])))
            return
        }

        guard let request = makeProfileImageRequest(username: username, token: token) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
            switch result {
            case .success(let result):
                guard let self = self else { return }
                self.avatarURL = result.profileImage.small
                completion(.success(result.profileImage.small))

                NotificationCenter.default.post(
                    name: ProfileImageService.didChangeNotification,
                    object: self,
                    userInfo: ["URL": self.avatarURL ?? ""]
                )

            case .failure(let error):
                print("[fetchProfileImageURL]: Ошибка запроса: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }

        self.task = task
        task.resume()
    }

    /// Очищает сохраненную ссылку на аватар при выходе из аккаунта
    func clear() {
        avatarURL = nil
    }

    // MARK: - Private Methods

    /// Собирает GET-запрос для получения данных профиля пользователя
    private func makeProfileImageRequest(username: String, token: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/users/\(username)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return request
    }
}
