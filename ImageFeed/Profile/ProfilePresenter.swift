

import Foundation
import Kingfisher

protocol ProfilePresenterProtocol: AnyObject {
    var view: ProfileViewControllerProtocol? {get set}
    func viewDidLoad()
    func didTapLogoutButton()
}

final class ProfilePresenter: ProfilePresenterProtocol {
    weak var view: ProfileViewControllerProtocol?
    
    private var profileImageServiceObserver: NSObjectProtocol?
    
    private let profileService: ProfileService
    private let profileImageService: ProfileImageService
    
    init(view: ProfileViewControllerProtocol? = nil, profileService: ProfileService = ProfileService.shared, profileImageService: ProfileImageService = ProfileImageService.shared) {
        self.view = view
        self.profileService = profileService
        self.profileImageService = profileImageService
    }
    
    func viewDidLoad() {
        if let profile = profileService.profile {
            view?.updateProfileDetails(profile: profile)
        }
        
        if let image = profileImageService.avatarURL, let url = URL(string: image) {
            view?.updateAvatar(url: url)
            
        } else {
            print("DEBUG: Ссылка на аватарку пустая или nil")
        }
        
        profileImageServiceObserver = NotificationCenter.default
            .addObserver(
                forName: ProfileImageService.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                if let image = profileImageService.avatarURL, let url = URL(string: image) {
                    view?.updateAvatar(url: url)
                }
                
            }
    }
    
    func didTapLogoutButton() {
        view?.showExit()
    }
}
    
//    private func updateAvatar() {
//        guard
//            let profileImageURL = profileImageService.avatarURL,
//            let url = URL(string: profileImageURL)
//        else {
//            print("DEBUG: Ссылка на аватарку пустая или nil")
//            return }
//        print("DEBUG: Загружаем аватарку по URL: \(url)")
//        // 2. Настраиваем индикатор у свойства
//        view.avatarImageView.kf.indicatorType = .activity
//        
//        // 3. Вызываем МЕТОД setImage у свойства avatarImageView
//        avatarImageView.kf.setImage(
//            with: url,
//            placeholder: UIImage(named: "avatar"),
//            options: [
//                .processor(RoundCornerImageProcessor(cornerRadius: 35))
//            ]
//        )
//    }
    
    // MARK: - Private Methods
    
    // 💡 ВНЕШНИЙ ВИД: Заполняет UI-элементы настоящими данными из объекта Profile (или фоллбэками)
//    private func updateProfileDetails(profile: Profile) {
//        nameLabel.text = profile.name.isEmpty
//            ? "Имя не указано"
//            : profile.name
//        loginNameLabel.text = profile.loginName.isEmpty
//            ? "@неизвестный_пользователь"
//            : profile.loginName
//        descriptionLabel.text = (profile.bio?.isEmpty ?? true)
//            ? "Профиль не заполнен"
//            : profile.bio
//    }


