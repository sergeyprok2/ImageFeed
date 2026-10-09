/// **Презентер для экрана профиля пользователя (Слой презентации / MVP)**
///
/// **За что отвечает:**
/// Управляет логикой отображения данных профиля и аватарки. Взаимодействует
/// с `ProfileService` и `ProfileImageService` для получения данных, подписывается
/// на обновления и передает сформированные URL и данные в `ProfileViewController`.

import Foundation

// MARK: - Protocol

/// Протокол презентера для управления экраном профиля
protocol ProfilePresenterProtocol: AnyObject {
    var view: ProfileViewControllerProtocol? { get set }
    func viewDidLoad()
    func didTapLogoutButton()
}

// MARK: - ProfilePresenter

final class ProfilePresenter: ProfilePresenterProtocol {

    // MARK: - Public Properties

    weak var view: ProfileViewControllerProtocol?

    // MARK: - Private Properties

    private var profileImageServiceObserver: NSObjectProtocol?
    private let profileService: ProfileService
    private let profileImageService: ProfileImageService

    // MARK: - Initialization

    init(
        view: ProfileViewControllerProtocol? = nil,
        profileService: ProfileService = ProfileService.shared,
        profileImageService: ProfileImageService = ProfileImageService.shared
    ) {
        self.view = view
        self.profileService = profileService
        self.profileImageService = profileImageService
    }

    // MARK: - Public Methods

    /// Настраивает первичные данные профиля и подписывается на обновления аватарки
    func viewDidLoad() {
        if let profile = profileService.profile {
            view?.updateProfileDetails(profile: profile)
        }

        if let image = profileImageService.avatarURL, let url = URL(string: image) {
            view?.updateAvatar(url: url)
        }

        profileImageServiceObserver = NotificationCenter.default
            .addObserver(
                forName: ProfileImageService.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                if let image = self.profileImageService.avatarURL, let url = URL(string: image) {
                    self.view?.updateAvatar(url: url)
                }
            }
    }

    /// Обрабатывает нажатие на кнопку выхода из профиля
    func didTapLogoutButton() {
        view?.showExit()
    }
}


