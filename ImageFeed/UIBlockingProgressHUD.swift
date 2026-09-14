// MARK: - Шпаргалка по файлу:
// 🏛 АРХИТЕКТУРНЫЙ КОНТЕКСТ:
// Класс-обертка над сторонней библиотекой `ProgressHUD`.
// Отвечает за блокировку пользовательского взаимодействия с UI во время проведения долгих сетевых операций
// (например, при обмене кода на токен в `AuthViewController` или загрузке профиля в `SplashViewController`).
//
// 📌 КЛЮЧЕВЫЕ СВОЙСТВА И МЕТОДЫ:
// 1. window — приватное вычисляемое свойство, находит текущее активное `keyWindow` приложения через `UIWindowScene`.
// 2. show() — статический метод: блокирует любые нажатия и жесты на экране (`isUserInteractionEnabled = false`) и показывает индикатор загрузки.
// 3. dismiss() — статический метод: скрывает индикатор и возвращает UI в активное состояние.

import UIKit
import ProgressHUD

// 💡 ИНДИКАТОР: Класс-обертка над ProgressHUD, который блокирует пользовательский ввод на время сетевых запросов
final class UIBlockingProgressHUD {
    
    // 💡 СВОЙСТВО: Находит текущее ключевое окно (keyWindow) приложения для управления касаниями экрана
    private static var window: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    // 💡 МЕТОД: Показывает спиннер загрузки и блокирует все нажатия на экран
    static func show() {
        window?.isUserInteractionEnabled = false
        ProgressHUD.animate()
    }
    
    // 💡 МЕТОД: Скрывает спиннер и разблокирует экран для пользователя
    static func dismiss() {
        window?.isUserInteractionEnabled = true
        ProgressHUD.dismiss()
    }
}
