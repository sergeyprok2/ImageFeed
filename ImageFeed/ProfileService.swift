// MARK: - Шпаргалка по файлу:
// 🏛 АРХИТЕКТУРНЫЙ КОНТЕКСТ:
// Сервис-синглтон (`shared`) загрузки и хранения профиля авторизованного пользователя Unsplash.
// Содержит сетевую DTO-модель `ProfileResult`, UI-модель `Profile` и сервис `ProfileService`, который выполняет запрос к эндпоинту `/me` с заголовком авторизации Bearer.
// Сохраняет полученный результат в свойстве `profile` и используется в `SplashViewController` и `ProfileViewController`.
//
// 📌 КЛЮЧЕВЫЕ СВОЙСТВА И МЕТОДЫ:
// 1. Profile & ProfileResult — модели данных (UI-структура и сетевая Codable-модель с кастомными `CodingKeys`).
// 2. profile — свойство `private(set)` для доступа к текущему загруженному профилю.
// 3. fetchProfile(_:completion:) — отменяет предыдущую таску, запрашивает данные профиля, конвертирует DTO в `Profile` и сохраняет результат.
// 4. makeProfileRequest(token:) — собирает GET-запрос к `https://api.unsplash.com/me` с авторизационным заголовком `Authorization: Bearer <token>`.

import Foundation

// MARK: - Шпаргалка по файлу:
// 1. makeProfileRequest — конструктор запроса. Берет адрес https://api.unsplash.com/me и прикрепляет заголовок Bearer + token.
// 2. fetchProfile — исполняемый метод. Перезапускает прошлую таску, делает запрос через URLSession, декодирует JSON (ProfileResult) в UI-модель (Profile) и сохраняет в self.profile.

// MARK: - Models (Модели данных из сети и для UI)

struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String?
}

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

// MARK: - ProfileService (Сервис загрузки профиля)

final class ProfileService {
    private(set) var profile: Profile?
    
    static let shared = ProfileService() // 👈 Один единственный экземпляр на всё приложение
    private init() {} // Запрещаем создавать другие экземпляры через ()
    
    private var task: URLSessionTask?
    private let urlSession = URLSession.shared

    // 💡 МЕТОД 1: Скачивает данные профиля из сети, превращает их в модель Profile и сохраняет в self.profile
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        task?.cancel()

        guard let request = makeProfileRequest(token: token) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<ProfileResult, Error>) in
            switch result {
            case .success(let result):
                let lastName = result.lastName ?? ""
                let profile = Profile(
                    username: result.username,
                    name: "\(result.firstName) \(lastName)"
                        .trimmingCharacters(in: .whitespaces), // Убираем лишние пробелы
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

    // 💡 МЕТОД 2: Собирает URL-запрос к эндпоинту /me и подставляет заголовок с токеном авторизации Bearer
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
