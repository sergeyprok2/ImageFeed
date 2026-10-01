// MARK: - Шпаргалка по файлу:
// 🏛 АРХИТЕКТУРНЫЙ КОНТЕКСТ:
// Контроллер экрана профиля пользователя. Отвечает за верстку программного UI (Auto Layout без Storyboard),
// отображение информации об авторизованном пользователе (аватар, имя, логин, био) и обработку выхода из системы.
// Берет сохраненные данные из `ProfileService.shared`.
//
// 📌 КЛЮЧЕВЫЕ СВОЙСТВА И МЕТОДЫ:
// 1. avatarImageView, nameLabel, loginNameLabel, descriptionLabel, logoutButton — компоненты интерфейса, созданные программно.
// 2. updateProfileDetails(profile:) — заполняет UI-элементы данными из модели `Profile` с безопасными фоллбэками.
// 3. setupSubviews() & setupConstraints() — программно добавляет subviews и активирует констрейнты Auto Layout.
// 4. didTapLogoutButton() — метод-обработчик нажатия на кнопку выхода из аккаунта.

import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {
    
    private var profileImageServiceObserver: NSObjectProtocol?
    
    // 💡 СЕРВИС: Экземпляр синглтона для доступа к сохраненным данным профиля
    private let profileService = ProfileService.shared
    
    // MARK: - UI Components
    
    // 💡 UI: Аватарка пользователя (круглый UIImageView 70x70)
    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "avatar")
        imageView.layer.cornerRadius = 35
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // 💡 UI: Лейбл для отображения полного имени
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Екатерина Новикова"
        label.font = .systemFont(ofSize: 23, weight: .bold)
        label.textColor = UIColor(named: "YP White (iOS)")
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 💡 UI: Лейбл для логина (начинается с @)
    private lazy var loginNameLabel: UILabel = {
        let label = UILabel()
        label.text = "@ekaterina_nov"
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(named: "YP Gray (iOS)")
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 💡 UI: Лейбл для описания профиля (био)
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Hello, world!"
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(named: "YP White (iOS)")
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 💡 UI: Кнопка выхода из аккаунта
    private lazy var logoutButton: UIButton = {
        let button = UIButton.systemButton(
            with: UIImage(named: "Exit") ?? UIImage(),
            target: self,
            action: #selector(didTapLogoutButton)
        )
        button.tintColor = UIColor(named: "YP Red (iOS)")
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    
    // 💡 ЖИЗНЕННЫЙ ЦИКЛ: Вёрстка UI, установка автолейаута и подстановка скачанных данных профиля
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black (iOS)")
        setupSubviews()
        setupConstraints()
        if let profile = ProfileService.shared.profile {
            updateProfileDetails(profile: profile)
        }
        profileImageServiceObserver = NotificationCenter.default
            .addObserver(
                forName: ProfileImageService.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                self.updateAvatar()
            }
        updateAvatar()
    }

    private func updateAvatar() {
        guard
            let profileImageURL = ProfileImageService.shared.avatarURL,
            let url = URL(string: profileImageURL)
        else {
            print("DEBUG: Ссылка на аватарку пустая или nil")
            return }
        print("DEBUG: Загружаем аватарку по URL: \(url)")
        // 2. Настраиваем индикатор у свойства
        avatarImageView.kf.indicatorType = .activity
        
        // 3. Вызываем МЕТОД setImage у свойства avatarImageView
        avatarImageView.kf.setImage(
            with: url,
            placeholder: UIImage(named: "avatar"),
            options: [
                .processor(RoundCornerImageProcessor(cornerRadius: 35))
            ]
        )
    }
    
    // MARK: - Private Methods
    
    // 💡 ВНЕШНИЙ ВИД: Заполняет UI-элементы настоящими данными из объекта Profile (или фоллбэками)
    private func updateProfileDetails(profile: Profile) {
        nameLabel.text = profile.name.isEmpty
            ? "Имя не указано"
            : profile.name
        loginNameLabel.text = profile.loginName.isEmpty
            ? "@неизвестный_пользователь"
            : profile.loginName
        descriptionLabel.text = (profile.bio?.isEmpty ?? true)
            ? "Профиль не заполнен"
            : profile.bio
    }
    
    // MARK: - Actions
    
    // 💡 ДЕЙСТВИЕ: Обработчик нажатия на кнопку логаута
    @objc private func didTapLogoutButton() {
        showExit()
    }
    
    // MARK: - Setup UI
    
    // 💡 ВЁРСТКА: Добавляет все UI-компоненты на главный view
    private func setupSubviews() {
        view.addSubview(avatarImageView)
        view.addSubview(nameLabel)
        view.addSubview(loginNameLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(logoutButton)
    }
    
    // 💡 ВЁРСТКА: Настраивает Auto Layout ограничения (constraints) для всех элементов
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Avatar
            avatarImageView.widthAnchor.constraint(equalToConstant: 70),
            avatarImageView.heightAnchor.constraint(equalToConstant: 70),
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            avatarImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            
            // Labels
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            
            loginNameLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            
            descriptionLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8),
            
            // Logout Button
            logoutButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            logoutButton.heightAnchor.constraint(equalToConstant: 44),
            logoutButton.widthAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    func showExit() {
        let alertController = UIAlertController(
            title: "Пока, пока!",
            message: "Уверены, что хотите выйти?",
            preferredStyle: .alert
        )
        let noAction = UIAlertAction(title: "Нет", style: .cancel, handler: nil)
        let yesAction = UIAlertAction(title: "Да", style: .default, handler:{_ in  ProfileLogoutService.shared.logout() })
        alertController.addAction(noAction)
        alertController.addAction(yesAction)
        present(alertController, animated: true, completion: nil)
    }
}
