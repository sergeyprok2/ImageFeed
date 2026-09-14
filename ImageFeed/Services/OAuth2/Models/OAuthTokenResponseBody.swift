// MARK: - Шпаргалка по файлу:
// 🏛 АРХИТЕКТУРНЫЙ КОНТЕКСТ:
// DTO-модель (Data Transfer Object) для декодирования сетевого ответа сервера Unsplash.
// Используется в `OAuth2Service` при успешном обмене авторизационного кода (code) на Bearer-токен.
//
// 📌 КЛЮЧЕВЫЕ СВОЙСТВА:
// 1. accessToken — полученный ключ доступа к API Unsplash.
// 2. CodingKeys — маппинг змейки JSON (`access_token`) в верблюжий стиль Swift (`accessToken`).

import Foundation

// 💡 МОДЕЛЬ ДАННЫХ: Структура для декодирования ответа от сервера Unsplash при получении OAuth-токена
struct OAuthTokenResponseBody: Decodable {
    
    // 💡 СВОЙСТВО: Сам токен доступа (access_token), который мы используем для авторизации запросов
    let accessToken: String

    // 💡 КЛЮЧИ ДЕКОДИРОВАНИЯ: Связывает название свойства в Swift (`accessToken`) с именем поля в JSON (`access_token`)
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}
