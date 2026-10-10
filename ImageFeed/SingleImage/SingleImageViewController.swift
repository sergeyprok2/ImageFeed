/// **Контроллер для просмотра одного полноэкранного изображения (Слой представления / View & Controller)**
///
/// **За что отвечает:**
/// Показывает выбранное изображение во весь экран с поддержкой масштабирования (zoom), центрирования и шеринга.
/// Использует `UIScrollView` и `UIImageView` с кастомным алгоритмом расчетного скейлинга под размеры экрана.
///
/// **Задачи:**
/// 1. Загружает полноразмерное изображение по URL через Kingfisher с отображением HUD.
/// 2. Масштабирует и центрирует изображение в контейнере `UIScrollView`.
/// 3. Обрабатывает жесты масштабирования (делегат `UIScrollViewDelegate`).
/// 4. Предоставляет возможность поделиться картинкой через системный `UIActivityViewController`.

import UIKit
import Kingfisher

// MARK: - SingleImageViewController

final class SingleImageViewController: UIViewController {

    // MARK: - Public Properties

    var fullImageURL: URL?

    // MARK: - UI Components

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var backButton: UIButton = {
        let backButton = UIButton.systemButton(
            with: UIImage(named: "Backward")?.withRenderingMode(.alwaysOriginal) ?? UIImage(),
            target: self,
            action: #selector(didTapBackButton)
        )
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.accessibilityIdentifier = "nav back button white"
        return backButton
    }()

    private lazy var shareButton: UIButton = {
        let shareButton = UIButton.systemButton(
            with: UIImage(named: "Sharing")?.withRenderingMode(.alwaysOriginal) ?? UIImage(),
            target: self,
            action: #selector(didTapShareButton(_:))
        )
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        return shareButton
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()

        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25

        fetchImage()
    }

    // MARK: - Actions

    @objc private func didTapBackButton() {
        dismiss(animated: true, completion: nil)
    }

    @objc func didTapShareButton(_ sender: Any) {
        guard let image = imageView.image else { return }
        let share = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        present(share, animated: true, completion: nil)
    }

    // MARK: - Private Methods

    /// Настройка иерархии UI-компонентов
    private func setupUI() {
        view.backgroundColor = UIColor(named: "YP Black (iOS)")
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(backButton)
        view.addSubview(shareButton)
        scrollView.delegate = self
    }

    /// Настройка ограничений (Auto Layout)
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            backButton.widthAnchor.constraint(equalToConstant: 44),

            shareButton.heightAnchor.constraint(equalToConstant: 50),
            shareButton.widthAnchor.constraint(equalToConstant: 50),
            shareButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -17)
        ])
    }

    /// Загружает полноразмерное изображение из сети
    private func fetchImage() {
        UIBlockingProgressHUD.show()
        imageView.kf.setImage(with: fullImageURL) { [weak self] result in
            UIBlockingProgressHUD.dismiss()

            guard let self = self else { return }
            switch result {
            case .success(let imageResult):
                self.rescaleAndCenterImageInScrollView(image: imageResult.image)
            case .failure:
                self.showError()
            }
        }
    }

    /// Показывает диалог ошибки с возможностью повторить загрузку
    private func showError() {
        let alertController = UIAlertController(
            title: "Что-то пошло не так",
            message: "Что-то пошло не так. Попробовать ещё раз?",
            preferredStyle: .alert
        )
        let noAction = UIAlertAction(title: "Не надо", style: .cancel, handler: nil)
        let resetAction = UIAlertAction(title: "Повторить", style: .default, handler: { [weak self] _ in self?.fetchImage() })
        alertController.addAction(noAction)
        alertController.addAction(resetAction)
        present(alertController, animated: true, completion: nil)
    }

    /// Рассчитывает масштаб и сдвиг для центрирования изображения в контейнере
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        let minZoomScale = scrollView.minimumZoomScale
        let maxZoomScale = scrollView.maximumZoomScale
        view.layoutIfNeeded()

        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size

        let hScale = visibleRectSize.width / imageSize.width
        let vScale = visibleRectSize.height / imageSize.height

        let scale = min(maxZoomScale, max(minZoomScale, min(hScale, vScale)))

        scrollView.setZoomScale(scale, animated: false)
        scrollView.layoutIfNeeded()

        let newContentSize = scrollView.contentSize
        let x = (newContentSize.width - visibleRectSize.width) / 2
        let y = (newContentSize.height - visibleRectSize.height) / 2

        scrollView.setContentOffset(CGPoint(x: x, y: y), animated: false)
    }
}

// MARK: - UIScrollViewDelegate

extension SingleImageViewController: UIScrollViewDelegate {

    /// Возвращает дочерний View, подлежащий масштабированию
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    /// Вызывается при изменении масштаба для динамического центрирования контента
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)

        scrollView.contentInset = UIEdgeInsets(
            top: offsetY,
            left: offsetX,
            bottom: offsetY,
            right: offsetX
        )
    }
}


