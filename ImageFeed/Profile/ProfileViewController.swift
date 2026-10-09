/// **Контроллер экрана профиля пользователя (Слой представления / View & Controller)**
///
/// **За что отвечает:**
/// Это слой представления (UI) экрана профиля. Отвечает за верстку программного UI (Auto Layout без Storyboard),
/// отображение информации об авторизованном пользователе (аватар, имя, логин, био) и обработку диалога выхода из системы.
///
/// **Задачи:**
/// 1. Создает программный интерфейс (аватар, текстовые метки, кнопка выхода).
/// 2. Отображает данные пользователя и загружает аватарку с использованием библиотеки Kingfisher.
/// 3. Показывает предупреждающий алерт при попытке выхода из аккаунта.
///
/// **Правило:**
/// Не обращается к сервисам напрямую, а управляется через `ProfilePresenter`.

import UIKit
import Kingfisher

// MARK: - Protocol

/// Протокол UI-контроллера для управления экраном профиля
protocol ProfileViewControllerProtocol: AnyObject {
    var presenter: ProfilePresenterProtocol? { get set }
    func updateAvatar(url: URL?)
    func updateProfileDetails(profile: Profile)
    func showExit()
}

// MARK: - ProfileViewController

final class ProfileViewController: UIViewController, ProfileViewControllerProtocol {

    // MARK: - Public Properties

    var presenter: ProfilePresenterProtocol?

    // MARK: - UI Components

    /// Аватарка пользователя (круглый UIImageView 70x70)
    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "avatar")
        imageView.layer.cornerRadius = 35
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    /// Лейбл для отображения полного имени
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Екатерина Новикова"
        label.font = .systemFont(ofSize: 23, weight: .bold)
        label.textColor = UIColor(named: "YP White (iOS)")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "Name Lastname"
        return label
    }()

    /// Лейбл для логина (начинается с @)
    private lazy var loginNameLabel: UILabel = {
        let label = UILabel()
        label.text = "@ekaterina_nov"
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(named: "YP Gray (iOS)")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "@username"
        return label
    }()

    /// Лейбл для описания профиля (био)
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Hello, world!"
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(named: "YP White (iOS)")
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// Кнопка выхода из аккаунта
    private lazy var logoutButton: UIButton = {
        let button = UIButton.systemButton(
            with: UIImage(named: "Exit") ?? UIImage(),
            target: self,
            action: #selector(didTapLogoutButton)
        )
        button.tintColor = UIColor(named: "YP Red (iOS)")
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "logout button"
        return button
    }()

    // MARK: - Lifecycle

    /// Вёрстка UI, установка автолейаута и запросы на обновление данных
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black (iOS)")
        setupSubviews()
        setupConstraints()
        presenter?.viewDidLoad()
    }

    // MARK: - Public Methods

    /// Обновляет изображение аватара по переданному URL с обработкой круглых углов в Kingfisher
    func updateAvatar(url: URL?) {
        avatarImageView.kf.indicatorType = .activity
        avatarImageView.kf.setImage(
            with: url,
            placeholder: UIImage(named: "avatar"),
            options: [
                .processor(RoundCornerImageProcessor(cornerRadius: 35))
            ]
        )
    }

    /// Заполняет UI-элементы настоящими данными из объекта Profile
    func updateProfileDetails(profile: Profile) {
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

    /// Показывает всплывающий алерт с подтверждением выхода из системы
    func showExit() {
        let alertController = UIAlertController(
            title: "Пока, пока!",
            message: "Уверены, что хотите выйти?",
            preferredStyle: .alert
        )
        alertController.view.accessibilityIdentifier = "Пока, пока!"
        
        let noAction = UIAlertAction(title: "Нет", style: .cancel, handler: nil)
        let yesAction = UIAlertAction(
            title: "Да",
            style: .default,
            handler: { _ in ProfileLogoutService.shared.logout() }
        )
        
        alertController.addAction(noAction)
        alertController.addAction(yesAction)
        
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Actions

    /// Обработчик нажатия на кнопку выхода
    @objc private func didTapLogoutButton() {
        presenter?.didTapLogoutButton()
    }

    // MARK: - Private Methods

    /// Добавляет все UI-компоненты на главный view
    private func setupSubviews() {
        view.addSubview(avatarImageView)
        view.addSubview(nameLabel)
        view.addSubview(loginNameLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(logoutButton)
    }

    /// Настраивает Auto Layout ограничения (constraints) для всех элементов
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
}
