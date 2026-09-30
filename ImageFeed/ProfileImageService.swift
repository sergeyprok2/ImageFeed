// MARK: - Шпаргалка по файлу ProfileImageService.swift:
// 🏛 АРХИТЕКТУРНЫЙ КОНТЕКСТ:
// Сервис-синглтон (`shared`) для получения URL аватарки пользователя с сервера Unsplash.
// Выполняет запрос `GET /users/:username` с авторизационным токеном из `OAuth2TokenStorage`,
// декодирует ответ в `UserResult` и сохраняет ссылку на картинку в `avatarURL`.
// Предотвращает дублирование сетевых запросов (race condition) при повторных вызовах.
//
// 📌 КЛЮЧЕВЫЕ СВОЙСТВА И МЕТОДЫ:
// 1. avatarURL — приватное для записи свойство `private(set)`, хранящее полученную ссылку на аватарку.
// 2. fetchProfileImageURL(username:completion:) — отменяет текущую таску, формирует URLRequest с Bearer-токеном и запрашивает аватарку.
// 3. UserResult & ProfileImage — Codable-структуры для парсинга объекта `profile_image` из JSON ответа Unsplash.
//

import Foundation

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

struct UserResult: Codable {
    let profileImage: ProfileImage

    private enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

final class ProfileImageService {
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")

    // Синглтон
    static let shared = ProfileImageService()
    private init() {}

    // Приватное свойство для хранения URL аватарки
    private(set) var avatarURL: String?

    private var task: URLSessionTask?

    // Метод для получения аватарки по имени пользователя
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
                print("✅ [ProfileImageService]: Ссылка на аватарку успешно получена: \(result.profileImage.small)")
                completion(.success(result.profileImage.small))

                NotificationCenter.default
                    .post(
                        name: ProfileImageService.didChangeNotification,
                        object: self,
                        userInfo: ["URL": self.avatarURL ?? ""]
                    )

            case .failure(let error):
                print("[fetchProfileImageURL]: Ошибка запроса: \(error.localizedDescription)")
                completion(.failure(error)) // Прокидываем ошибку
            }
        }

        self.task = task
        task.resume()
    }
    
    func clear() {
        avatarURL = nil
    }

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
