// MARK: - Шпаргалка по файлу:
// 🏛 АРХИТЕКТУРНЫЙ КОНТЕКСТ:
// Хранилище авторизационного Bearer-токена поверх системного `UserDefaults`.
// Служит единым источником правды о том, авторизован ли пользователь. Используется в `SplashViewController` при запуске
// для проверки наличия токена и в `AuthViewController` для сохранения токена после успешного входа.
//
// 📌 КЛЮЧЕВЫЕ СВОЙСТВА:
// 1. userDefaults & tokenKey — системная база данных key-value и ключ "bearer_token" для записи.
// 2. token (getter/setter) — вычисляемое свойство: достает строку из UserDefaults при чтении, сохраняет её при записи или удаляет объект при присвоении nil.

// MARK: - Шпаргалка по файлу:
// 🏛 АРХИТЕКТУРНЫЙ КОНТЕКСТ:
// Сервис-синглтон (`shared`) для безопасного хранения и чтения OAuth-токена авторизации.
// Работает как обертка над `UserDefaults.standard`. Является единой точкой правды о статусе авторизации
// для `SplashViewController`, `AuthViewController`, `ProfileService` и `ProfileImageService`.
//
// 📌 КЛЮЧЕВЫЕ СВОЙСТВА:
// 1. shared & init() — паттерн Singleton для единой точки доступа к токену из любой части приложения.
// 2. dataStorage & tokenKey — экземпляр UserDefaults и ключ "token" для сохранения строки в системную базу.
// 3. token (getter/setter) — вычисляемое свойство: возвращает токен или записывает/удаляет его при присвоении nil.

import Foundation
import SwiftKeychainWrapper

// 💡 ХРАНИЛИЩЕ: Класс для безопасного чтения и сохранения Bearer-токена авторизации
final class OAuth2TokenStorage {
    
    static let shared = OAuth2TokenStorage()
    private init() {}
    
    // 💡 СВОЙСТВА: Ссылка на стандартное хранилище настроек и ключ для записи токена
    private let keychainWrapper = KeychainWrapper.standard
    private let tokenKey = "bearer_token"
    
    
    // 💡 СВОЙСТВО (COMPUTED): Вычисляемое свойство для работы с токеном.
    // При чтении (get) достает строку из UserDefaults.
    // При записи (set) сохраняет новое значение или удаляет ключ, если передали nil.
    var token: String? {
        get {
            keychainWrapper.string(forKey: tokenKey)
        }
        set {
            if let newToken = newValue {
                keychainWrapper.set(newToken, forKey: tokenKey)
            } else {
                keychainWrapper.removeObject(forKey: tokenKey)
            }
        }
    }
}
