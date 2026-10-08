//


import XCTest

class Image_FeedUITests: XCTestCase {
    private let app = XCUIApplication() // переменная приложения
    
    override func setUpWithError() throws {
        continueAfterFailure = false

        app.launchArguments = []

        if name.contains("testAuth") {
            app.launchArguments = ["-resetAuth"]
        }

        app.launch()
    }
    
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
    
    func testFeed() throws {
        // Находим таблицу с фотографиями
        let tableView = app.tables.firstMatch

        // Проверяем, что таблица появилась
        XCTAssertTrue(
            tableView.waitForExistence(timeout: 20),
            "Таблица с фотографиями не появилась"
        )

        // Прокручиваем таблицу вверх
        tableView.swipeUp()

        // Ждём загрузку фотографий
        sleep(20)

        // Ищем видимую ячейку с доступной кнопкой лайка
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

        // Если подходящая ячейка не найдена, завершаем тест
        guard let cellToLike else {
            XCTFail("Не найдена видимая ячейка с кнопкой лайка")
            return
        }

        // Находим кнопку в состоянии «лайк не установлен»
        let likeOffButton = cellToLike.buttons["like button off"]

        // Ждём появления кнопки
        XCTAssertTrue(
            likeOffButton.waitForExistence(timeout: 10),
            "Кнопка like button off не появилась"
        )

        // Устанавливаем лайк
        likeOffButton.tap()

        // После запроса кнопка должна перейти в состояние «лайк установлен»
        let likeOnButton = cellToLike.buttons["like button on"]

        // Ждём обновления состояния кнопки
        XCTAssertTrue(
            likeOnButton.waitForExistence(timeout: 10),
            "Кнопка like button on не появилась"
        )

        // Снимаем лайк
        likeOnButton.tap()

        // Ждём завершения запроса снятия лайка
        sleep(10)

        // Открываем фотографию
        cellToLike.tap()

        // Находим большую фотографию
        let image = app.scrollViews.images.element(boundBy: 0)

        // Проверяем, что большая фотография появилась
        XCTAssertTrue(
            image.waitForExistence(timeout: 200),
            "Большая фотография не появилась"
        )

        // Увеличиваем изображение
        image.pinch(withScale: 3, velocity: 1)

        // Уменьшаем изображение
        image.pinch(withScale: 0.5, velocity: -1)

        // Находим кнопку возврата назад
        let backButton = app.buttons["nav back button white"]

        // Проверяем, что кнопка назад появилась
        XCTAssertTrue(
            backButton.waitForExistence(timeout: 20),
            "Кнопка назад не появилась"
        )

        // Возвращаемся к ленте
        backButton.tap()
    }

    func testProfile() throws {
        // 1. Ждем появление кнопки таб-бара и нажимаем на нее
        let profileTab = app.tabBars.buttons.element(boundBy: 1)
        XCTAssertTrue(profileTab.waitForExistence(timeout: 100))
        profileTab.tap()

        // 2. Ждем появления текста имени вместо sleep(10)
        let nameText = app.staticTexts["Name Lastname"]
        XCTAssertTrue(nameText.waitForExistence(timeout: 10))

        // 3. Ждем появления юзернейма
        let usernameText = app.staticTexts["@username"]
        XCTAssertTrue(usernameText.waitForExistence(timeout: 10))

        // 4. Нажимаем кнопку выхода
        let logoutButton = app.buttons["logout button"]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 5))
        logoutButton.tap()

        // 5. Работа с алертом: обращаемся к кнопке напрямую
        let alert = app.alerts["Пока, пока!"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Да"].tap()
    }
}
