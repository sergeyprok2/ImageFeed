//
/// **Модульные тесты ленты фотографий (Слой тестирования / Unit Tests)**
///
/// **За что отвечает:**
/// Набор Unit-тестов для проверки корректности взаимодействия компонентов MVP ленты фотографий
/// (`ImagesListViewController` и `ImagesListPresenter`). Проверяет вызовы методов жизненного цикла,
/// подсчет элементов и реакцию на уведомления об изменении списка фотографий.
///
/// **Задачи:**
/// 1. Проверяет корректность вызова методов презентера при загрузке `ImagesListViewController`.
/// 2. Валидирует расчет количества строк презентером `numberOfRows()`.
/// 3. Проверяет отправку сообщения `updateTableViewAnimated` контроллеру при получении уведомления от сервиса.

@testable import ImageFeed
import XCTest

// MARK: - ImagesListTests

@MainActor
final class ImagesListTests: XCTestCase {

    // MARK: - Test Methods

    /// Проверяет, что контроллер при загрузке view обращается к презентеру
    func testViewControllerCallsViewDidLoad() {
        let viewController = ImagesListViewController()
        let presenter = ImagesListPresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController

        _ = viewController.view

        XCTAssertTrue(presenter.viewDidLoadCalled)
    }

    /// Проверяет, что презентер правильно возвращает количество загруженных фотографий
    func testnumberOfRows() {
        let photos = [
            Photo(id: "1", size: .zero, createdAt: nil, welcomeDescription: "First photo", thumbImageURL: "", largeImageURL: "", isLiked: true),
            Photo(id: "2", size: .zero, createdAt: nil, welcomeDescription: "Second photo", thumbImageURL: "", largeImageURL: "", isLiked: false),
            Photo(id: "3", size: .zero, createdAt: nil, welcomeDescription: "Third photo", thumbImageURL: "", largeImageURL: "", isLiked: true)
        ]
        let presenter = ImagesListPresenter(photos: photos)

        let count = presenter.numberOfRows()

        XCTAssertEqual(photos.count, count)
    }

    /// Проверяет, что презентер вызывает анимацию обновления таблицы при получении уведомления
    func testupdateTableViewAnimated() {
        let viewController = ImagesListViewControllerSpy()
        let presenter = ImagesListPresenter()
        viewController.presenter = presenter
        presenter.view = viewController

        NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: nil)

        XCTAssertTrue(viewController.updateTableViewAnimatedCalled)
    }
}
