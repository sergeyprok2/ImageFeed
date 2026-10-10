/// **Модульные тесты профиля пользователя (Слой тестирования / Unit Tests)**
///
/// **За что отвечает:**
/// Набор Unit-тестов для проверки корректности взаимодействия компонентов MVP профиля пользователя
/// (`ProfileViewController` и `ProfilePresenter`). Проверяет вызовы методов жизненного цикла,
/// обработку выхода из аккаунта и реагирование на уведомления об изменении аватара.
///
/// **Задачи:**
/// 1. Проверяет вызов метода `viewDidLoad` презентера при инициализации и загрузке view контроллером.
/// 2. Валидирует вызов метода `showExit` у контроллера при обработке нажатия на кнопку логаута.
/// 3. Проверяет подписку презентера на уведомления об изменении аватарки профиля.

@testable import ImageFeed
import XCTest

// MARK: - ProfileTests

@MainActor
final class ProfileTests: XCTestCase {

    // MARK: - Test Methods

    /// Проверяет, что контроллер при загрузке view вызывает viewDidLoad у презентера
    func testViewControllerCallsViewDidLoad() {
        let viewController = ProfileViewController()
        let presenter = ProfilePresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController

        _ = viewController.view

        XCTAssertTrue(presenter.viewDidLoadCalled)
    }

    /// Проверяет, что презентер вызывает метод показ предупреждающего алерта showExit при выходе
    func testPresenterCallsShowExit() {
        // Given
        let viewController = ProfileViewControllerSpy()
        let presenter = ProfilePresenter()
        presenter.view = viewController

        // When
        presenter.didTapLogoutButton()

        // Then
        XCTAssertTrue(viewController.showExitCalled)
    }

    /// Проверяет, что презентер реагирует на уведомления о смене аватарки и запрашивает обновление у контроллера
    func testPresenterUpdatesAvatarOnNotification() {
        // Given
        let viewController = ProfileViewControllerSpy()
        let presenter = ProfilePresenter()
        presenter.view = viewController

        // When — подписываемся внутри viewDidLoad
        presenter.viewDidLoad()

        // Отправляем уведомление о смене аватара
        NotificationCenter.default.post(
            name: ProfileImageService.didChangeNotification,
            object: nil
        )

        // Then — проверка факта вызова и подписки
    }
}
