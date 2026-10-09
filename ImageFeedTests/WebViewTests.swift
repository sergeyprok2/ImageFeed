/// **Модульные тесты экрана авторизации через WebView (Слой тестирования / Unit Tests)**
///
/// **За что отвечает:**
/// Набор Unit-тестов для проверки корректности взаимодействия компонентов авторизации
/// (`WebViewViewController`, `WebViewPresenter` и `AuthHelper`). Проверяет вызовы методов
/// жизненного цикла, вычисление прогресса загрузки, сборку URL авторизации и извлечение `code`.
///
/// **Задачи:**
/// 1. Проверяет вызов `viewDidLoad` у презентера при загрузке `WebViewViewController`.
/// 2. Валидирует вызов метода загрузки `URLRequest` в контроллере при старте.
/// 3. Проверяет логику скрытия/отображения прогресс-бара в зависимости от значения от 0.0 до 1.0.
/// 4. Валидирует генерацию ссылки авторизации `authURL()` класса `AuthHelper`.
/// 5. Проверяет парсинг параметра `code` из редирект-ссылки после входа.

@testable import ImageFeed
import XCTest

// MARK: - WebViewTests

@MainActor
final class WebViewTests: XCTestCase {

    // MARK: - Test Methods

    /// Проверяет, что контроллер при загрузке view вызывает viewDidLoad у презентера
    func testViewControllerCallsViewDidLoad() {
        let viewController = WebViewViewController()
        let presenter = WebViewPresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController

        _ = viewController.view

        XCTAssertTrue(presenter.viewDidLoadCalled)
    }

    /// Проверяет, что презентер передает сформированный запрос на загрузку в WebViewViewController
    func testPresenterCallsLoadRequest() {
        // given
        let viewController = WebViewViewControllerSpy()
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        viewController.presenter = presenter
        presenter.view = viewController

        // when
        presenter.viewDidLoad()

        // then
        XCTAssertTrue(viewController.loadRequestCalled)
    }

    /// Проверяет, что индикатор прогресса остается видимым, пока прогресс меньше 1.0 (100%)
    func testProgressVisibleWhenLessThenOne() {
        // given
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        let progress: Float = 0.6

        // when
        let shouldHideProgress = presenter.shouldHideProgress(for: progress)

        // then
        XCTAssertFalse(shouldHideProgress)
    }

    /// Проверяет, что индикатор прогресса скрывается при достижении 1.0 (100%)
    func testProgressHiddenWhenOne() {
        // given
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        let progress: Float = 1.0

        // when
        let shouldHideProgress = presenter.shouldHideProgress(for: progress)

        // then
        XCTAssertTrue(shouldHideProgress)
    }

    /// Проверяет корректность формирования URL для авторизации со всеми обязательными параметрами
    func testAuthHelperAuthURL() {
        // given
        let configuration = AuthConfiguration.standard
        let authHelper = AuthHelper(configuration: configuration)

        // when
        let url = authHelper.authURL()

        guard let urlString = url?.absoluteString else {
            XCTFail("Auth URL is nil")
            return
        }

        // then
        XCTAssertTrue(urlString.contains(configuration.authURLString))
        XCTAssertTrue(urlString.contains(configuration.accessKey))
        XCTAssertTrue(urlString.contains(configuration.redirectURI))
        XCTAssertTrue(urlString.contains("code"))
        XCTAssertTrue(urlString.contains(configuration.accessScope))
    }

    /// Проверяет извлечение значения параметра code из редирект-URL
    func testCodeFromURL() {
        let authHelper = AuthHelper()

        guard var urlComponents = URLComponents(string: "https://unsplash.com/oauth/authorize/native") else {
            XCTFail("Не удалось создать URLComponents")
            return
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "code", value: "test code")
        ]

        guard let url = urlComponents.url else {
            XCTFail("Не удалось получить URL из urlComponents")
            return
        }

        let code = authHelper.code(from: url)

        XCTAssertEqual(code, "test code")
    }
}
