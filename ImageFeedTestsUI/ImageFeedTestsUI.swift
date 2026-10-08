//


import XCTest

class Image_FeedUITests: XCTestCase {
    private let app = XCUIApplication() // переменная приложения
    
    override func setUpWithError() throws {
        continueAfterFailure = false // настройка выполнения тестов, которая прекратит выполнения тестов, если в тесте что-то пошло не так
        
        let app = XCUIApplication()
        // Передаем аргумент для очистки состояния или токена при запуске
        app.launchArguments = ["-resetToken"]
        app.launch() // запускаем приложение перед каждым тестом
    }
    
    func testAuth() throws {
        print("222222222222222222222222222222222222222222222222222")
        app.buttons["Authenticate"].tap()
        print("111111111111111111111111111111111111111111111111111")
        let webView = app.webViews["UnsplashWebView"]
        
        XCTAssertTrue(webView.waitForExistence(timeout: 100))

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
        passwordTextField.typeText("tadjof-kyCguq-0hyzze")
        webView.swipeUp()
        
        webView.buttons["Login"].tap()
        
        let tablesQuery = app.tables
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        
        XCTAssertTrue(cell.waitForExistence(timeout: 500))
    }
    
    func testFeed() throws {
        let tableView = app.tables.firstMatch

        XCTAssertTrue(
            tableView.waitForExistence(timeout: 20),
            "Таблица с фотографиями не появилась"
        )

        let firstCell = tableView.cells.element(boundBy: 0)

        XCTAssertTrue(
            firstCell.waitForExistence(timeout: 20),
            "Первая ячейка не появилась"
        )

        firstCell.swipeUp()

        sleep(2) // ждём завершения прокрутки

        var cellToLike = tableView.cells.element(boundBy: 1)

        XCTAssertTrue(
            cellToLike.waitForExistence(timeout: 20),
            "Вторая ячейка не появилась"
        )

        sleep(100) // ждём загрузку изображения

        var likeButton = cellToLike.buttons["likeButton"]

        XCTAssertTrue(
            likeButton.waitForExistence(timeout: 20),
            "Кнопка лайка не появилась"
        )

        XCTAssertTrue(
            likeButton.isHittable,
            "Кнопка лайка найдена, но недоступна для нажатия"
        )

        likeButton.tap()

        sleep(3) // ждём ответ сервера и обновление ячейки

        // ВАЖНО: заново получаем ячейку после изменения лайка
        cellToLike = tableView.cells.element(boundBy: 1)

        XCTAssertTrue(
            cellToLike.waitForExistence(timeout: 20),
            "Ячейка исчезла после установки лайка"
        )

        likeButton = cellToLike.buttons["likeButton"]

        XCTAssertTrue(
            likeButton.waitForExistence(timeout: 20),
            "Кнопка лайка не найдена после обновления"
        )

        XCTAssertTrue(
            likeButton.isHittable,
            "Кнопка лайка недоступна после обновления"
        )

        likeButton.tap()

        sleep(3) // ждём снятие лайка

        // Повторно находим ячейку перед открытием фотографии
        cellToLike = tableView.cells.element(boundBy: 1)

        XCTAssertTrue(
            cellToLike.waitForExistence(timeout: 20),
            "Ячейка не найдена перед открытием фотографии"
        )

        XCTAssertTrue(
            cellToLike.isHittable,
            "Ячейка недоступна для нажатия"
        )

        cellToLike.tap()

        let image = app.scrollViews.images.element(boundBy: 0)

        XCTAssertTrue(
            image.waitForExistence(timeout: 20),
            "Большая фотография не появилась"
        )

        image.pinch(withScale: 3, velocity: 1)
        image.pinch(withScale: 0.5, velocity: -1)

        let navBackButtonWhiteButton = app.buttons["nav back button white"]

        XCTAssertTrue(
            navBackButtonWhiteButton.waitForExistence(timeout: 20),
            "Кнопка назад не появилась"
        )

        navBackButtonWhiteButton.tap()
    }


    
    func testProfile() throws {
        sleep(10)
        app.tabBars.buttons.element(boundBy: 1).tap()
        print("222222222222222222222222222222222222222222222222222")
        XCTAssertTrue(app.staticTexts["Name Lastname"].exists)
        sleep(10)
        XCTAssertTrue(app.staticTexts["@username"].exists)
        
        app.buttons["logout button"].tap()
        
        app.alerts["Bye bye!"].scrollViews.otherElements.buttons["Yes"].tap()
    }
}
