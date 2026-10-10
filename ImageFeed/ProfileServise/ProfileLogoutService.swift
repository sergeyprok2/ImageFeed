/// **Сервис выхода пользователя из системы и очистки сессии (Слой бизнес-логики / Model)**
///
/// **За что отвечает:**
/// Сервис-синглтон (`shared`), полностью управляющий процессом выхода из учетной записи.
/// Сбрасывает сохраненный токен авторизации, очищает локальные кэши сервисов (`ProfileService`,
/// `ProfileImageService`, `ImagesListService`), удаляет куки сессии из `WebKit` и переключает
/// интерфейс обратно на `SplashViewController`.
///
/// **Задачи:**
/// 1. Очищает авторизационный токен в `OAuth2TokenStorage`.
/// 2. Вызывает сброс состояния во всех ключевых сервисах приложения.
/// 3. Асинхронно удаляет пользовательские куки и веб-данные из `WKWebsiteDataStore` и `HTTPCookieStorage`.
/// 4. Перенаправляет пользователя на стартовый экран после завершения очистки.

import Foundation
import WebKit

// MARK: - ProfileLogoutService

final class ProfileLogoutService {

    // MARK: - Static Properties

    static let shared = ProfileLogoutService()

    // MARK: - Init

    private init() {}

    // MARK: - Public Methods

    /// Полностью завершает сессию пользователя, очищает локальные данные и куки, затем возвращает на стартовый экран
    func logout() {
        OAuth2TokenStorage.shared.token = nil
        ProfileService.shared.clear()
        ProfileImageService.shared.clear()
        ImagesListService.shared.clear()

        cleanCookies { [weak self] in
            DispatchQueue.main.async {
                self?.switchToSplashViewController()
            }
        }
    }

    // MARK: - Private Methods

    /// Асинхронно очищает данные веб-сессии и куки из `HTTPCookieStorage` и `WKWebsiteDataStore`
    private func cleanCookies(completion: @escaping () -> Void) {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)

        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            let group = DispatchGroup()

            records.forEach { record in
                group.enter()
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record]) {
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                completion()
            }
        }
    }

    /// Сбрасывает текущий `rootViewController` приложения на `SplashViewController`
    private func switchToSplashViewController() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
                assertionFailure("Invalid window configuration")
                return
        }

        let splashViewController = SplashViewController()
        window.rootViewController = splashViewController
    }
}
    
