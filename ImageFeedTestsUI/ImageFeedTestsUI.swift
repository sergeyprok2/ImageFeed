/// **Пользовательские UI-тесты основного функционала приложения (Слой UI-тестирования / UI Automation Tests)**
///
/// **За что отвечает:**
/// Комплексный набор UI-автотестов, проверяющий основные пользовательские сценарии (User Flows):
/// авторизацию через WebKit UI, скроллинг ленты, поставление/снятие лайков, просмотр и зум полноэкранной картинки,
/// а также переход в профиль с проверкой данных и процессом выхода из учетной записи.
///
/// **Задачи:**
/// 1. `testAuth`: Проверяет форму авторизации Unsplash, ввод учетных данных и успешный вход.
/// 2. `testFeed`: Проверяет взаимодействие с лентой, переключение лайка, просмотр изображения и жесты масштабирования.
/// 3. `testProfile`: Проверяет отображение информации о пользователе и диалог подтверждения выхода.

import XCTest

// MARK: - ImageFeedUITests

final class ImageFeedUITests: XCTestCase {

    // MARK: - Private Properties

    private let app = XCUIApplication()

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        continueAfterFailure = false

        app.launchArguments = []

        if name.contains("testAuth") {
            app.launchArguments = ["-resetAuth"]
        }

        app.launch()
    }

    // MARK: - UI Test Cases

    /// Автоматизированный сценарий входа пользователя через встроенный веб-интерфейс Unsplash
    func testAuth() throws {
        app.buttons["Authenticate"].tap()
        let webView = app.webViews["UnsplashWebView"]

        XCTAssertTrue(webView.waitForExistence(timeout: 10))

        let loginTextField = webView.descendants(matching: .textField).element
        XCTAssertTrue(loginTextField.waitForExistence(timeout: 10))

        loginTextField.tap()
        loginTextField.typeText("stub_remits_22@icloud.com")
        webView.swipeUp()

        let passwordTextField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 5))

        passwordTextField.tap()
        let passwordTextField1 = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 5))
        passwordTextField1.tap()
        sleep(5)
        passwordTextField.typeText("tadjof-kyCguq-0hyzze")
        webView.swipeUp()

        webView.buttons["Login"].tap()
        sleep(5)
        let tablesQuery = app.tables
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)

        XCTAssertTrue(cell.waitForExistence(timeout: 5))
    }

    /// Автоматизированный сценарий работы с лентой фотографий (скролл, лайки, зум изображения)
    func testFeed() throws {
        let tableView = app.tables.firstMatch

        XCTAssertTrue(
            tableView.waitForExistence(timeout: 20),
            "Таблица с фотографиями не появилась"
        )

        tableView.swipeUp()
        sleep(20)

        let cells = tableView.cells
        var cellToLike: XCUIElement?

        for index in 0..<cells.count {
            let cell = cells.element(boundBy: index)
            let likeButton = cell.buttons["likeButton"]

            if cell.isHittable && likeButton.isHittable {
                cellToLike = cell
                break
            }
        }

        guard let cellToLike else {
            XCTFail("Не найдена видимая ячейка с кнопкой лайка")
            return
        }

        let likeOffButton = cellToLike.buttons["like button off"]

        XCTAssertTrue(
            likeOffButton.waitForExistence(timeout: 10),
            "Кнопка like button off не появилась"
        )

        likeOffButton.tap()

        let likeOnButton = cellToLike.buttons["like button on"]

        XCTAssertTrue(
            likeOnButton.waitForExistence(timeout: 10),
            "Кнопка like button on не появилась"
        )

        likeOnButton.tap()
        sleep(10)

        cellToLike.tap()

        let image = app.scrollViews.images.element(boundBy: 0)

        XCTAssertTrue(
            image.waitForExistence(timeout: 200),
            "Большая фотография не появилась"
        )

        image.pinch(withScale: 3, velocity: 1)
        image.pinch(withScale: 0.5, velocity: -1)

        let backButton = app.buttons["nav back button white"]

        XCTAssertTrue(
            backButton.waitForExistence(timeout: 20),
            "Кнопка назад не появилась"
        )

        backButton.tap()
    }

    /// Автоматизированный сценарий проверки экрана профиля и подтверждения выхода
    func testProfile() throws {
        let profileTab = app.tabBars.buttons.element(boundBy: 1)
        XCTAssertTrue(profileTab.waitForExistence(timeout: 100))
        profileTab.tap()

        let nameText = app.staticTexts["Name Lastname"]
        XCTAssertTrue(nameText.waitForExistence(timeout: 10))

        let usernameText = app.staticTexts["@username"]
        XCTAssertTrue(usernameText.waitForExistence(timeout: 10))

        let logoutButton = app.buttons["logout button"]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 5))
        logoutButton.tap()

        let alert = app.alerts["Пока, пока!"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Да"].tap()
    }
}
