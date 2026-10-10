/// **Презентер экрана авторизации через WebView (Слой презентации / MVP Presenter)**
///
/// **За что отвечает:**
/// Выступает в роли презентера (MVP) для управления логикой авторизации в `WebViewViewController`.
/// Взаимодействует с `AuthHelperProtocol` для генерации сетевого запроса `URLRequest` и извлечения
/// авторизационного кода из обратного URL. Управляет состоянием индикатора прогресса загрузки.
///
/// **Задачи:**
/// 1. Подготавливает и отправляет `URLRequest` авторизации в View при запуске (`viewDidLoad`).
/// 2. Вычисляет прогресс загрузки и указывает View, нужно ли скрывать шкалу прогресса.
/// 3. Делегирует извлечение кода авторизации из URL классу `AuthHelper`.

import Foundation

// MARK: - WebViewPresenterProtocol

/// Протокол презентера экрана авторизации WebView
public protocol WebViewPresenterProtocol {
    var view: WebViewViewControllerProtocol? { get set }
    func viewDidLoad()
    func didUpdateProgressValue(_ newValue: Double)
    func code(from url: URL) -> String?
}

// MARK: - WebViewPresenter

final class WebViewPresenter: WebViewPresenterProtocol {

    // MARK: - Public Properties

    weak var view: WebViewViewControllerProtocol?
    var authHelper: AuthHelperProtocol

    // MARK: - Init

    init(authHelper: AuthHelperProtocol) {
        self.authHelper = authHelper
    }

    // MARK: - Public Methods

    /// Собирает URL для авторизации с помощью AuthHelper и передает запрос View
    func viewDidLoad() {
        guard let request = authHelper.authRequest() else { return }

        view?.load(request: request)
        didUpdateProgressValue(0)
    }

    /// Обновляет значение шкалы прогресса и управляет ее видимостью
    func didUpdateProgressValue(_ newValue: Double) {
        let newProgressValue = Float(newValue)
        view?.setProgressValue(newProgressValue)

        let shouldHideProgress = shouldHideProgress(for: newProgressValue)
        view?.setProgressHidden(shouldHideProgress)
    }

    /// Определяет, следует ли скрыть индикатор прогресса (скрывается при значении, равном 1.0)
    func shouldHideProgress(for value: Float) -> Bool {
        abs(value - 1.0) <= 0.0001
    }

    /// Извлекает код авторизации из URL перенаправления через AuthHelper
    func code(from url: URL) -> String? {
        authHelper.code(from: url)
    }
}
