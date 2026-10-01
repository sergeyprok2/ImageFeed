

import Foundation
import WebKit

final class ProfileLogoutService {
    static let shared = ProfileLogoutService()
    
    private init() { }

    func logout() {
        OAuth2TokenStorage.shared.token = nil
        ProfileService.shared.clear()
        ProfileImageService.shared.clear()
        ImagesListService.shared.clear()
        
        // Передаем замыкание: смена экрана выполнится СТРОГО после завершения очистки кук
        cleanCookies { [weak self] in
            DispatchQueue.main.async {
                self?.switchToSplashViewController()
            }
        }
    }

    private func cleanCookies(completion: @escaping () -> Void) {
        // 1. Очищаем куки из HTTPCookieStorage
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        
        // 2. Запрашиваем записи из WKWebsiteDataStore
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            // Создаем группу для отслеживания асинхронных операций удаления
            let group = DispatchGroup()
            
            records.forEach { record in
                group.enter() // Увеличиваем счетчик задач
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record]) {
                    group.leave() // Уменьшаем счетчик, когда одна запись удалилась
                }
            }
            
            // Когда счетчик станет равен 0 (все записи удалены) — вызываем completion
            group.notify(queue: .main) {
                completion()
            }
        }
    }
    
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
    
