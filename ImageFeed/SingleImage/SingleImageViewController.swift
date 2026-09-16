// MARK: - Шпаргалка по файлу:
// 🏛 АРХИТЕКТУРНЫЙ КОНТЕКСТ:
// Контроллер для просмотра одного полноэкранного изображения с поддержкой масштабирования (zoom) и шеринга.
// Использует `UIScrollView` и `UIImageView` с кастомным алгоритмом расчетного скейлинга и центрирования картинки под экраны любых размеров.
//
// 📌 КЛЮЧЕВЫЕ СВОЙСТВА И МЕТОДЫ:
// 1. image (didSet) — публичное свойство для передачи изображения; обновляет UI только если view уже загружена (`isViewLoaded`).
// 2. imageView & scrollView — связи из Storyboard/XIB для отображения и зуминга.
// 3. rescaleAndCenterImageInScrollView(image:) — алгоритм автоматического вписывания картинки в границы scrollView с вычислением оптимального `zoomScale` и центрированием через `contentOffset`.
// 4. didTapShareButton(_:) — вызывается при нажатии на кнопку "Поделиться", вызывает системный `UIActivityViewController`.
// 5. viewForZooming(in:) — метод протокола `UIScrollViewDelegate`, указывающий `imageView` как объект для зуминга.

import UIKit

final class SingleImageViewController: UIViewController {

    // 1. Промежуточная переменная-коробка для картинки
    var image: UIImage? {
        didSet {
            // Если экран ЕЩЁ не загружен в память — ничего не делаем, ждем viewDidLoad.
            // Если экран УЖЕ показан на экране — сразу обновляем картинку в imageView.
            guard isViewLoaded, let image = image else { return }
            imageView.image = image
            imageView.frame.size = image.size
            rescaleAndCenterImageInScrollView(image: image)
        }
    }
    
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
            action: #selector(didTapBackButton))
        backButton.translatesAutoresizingMaskIntoConstraints = false
        return backButton
    }()
    
    private lazy var shareButton: UIButton = {
        let shareButton = UIButton.systemButton(
            with: UIImage(named: "Sharing")?.withRenderingMode(.alwaysOriginal) ?? UIImage(),
            target: self,
            action: #selector(didTapShareButton(_:)))
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        return shareButton
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25
        
        // Когда экран сам загрузился в память, он берет картинку из коробки `image`
        // и кладёт её в `imageView`
        // Если картинку передали ДО загрузки экрана — отображаем и центрируем ее
        if let image = image {
            imageView.image = image
            imageView.frame.size = image.size
            rescaleAndCenterImageInScrollView(image: image)
        }

    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(named: "YP Black (iOS)")
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(backButton)
        view.addSubview(shareButton)
        scrollView.delegate = self
        }
        
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
    
    // MARK: - Actions
    @objc private func didTapBackButton() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapShareButton(_ sender: Any) {
        guard let image else { return }
        let share = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        present(share, animated: true, completion: nil)
    }
    
    // MARK: - Private Methods
    // Алгоритм рескейла и центрирования
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        // Сбрасываем скейл и сдвиг по умолчанию
        
        let minZoomScale = scrollView.minimumZoomScale
        let maxZoomScale = scrollView.maximumZoomScale
        view.layoutIfNeeded()
        
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        
        // Считаем, во сколько раз нужно сжать/увеличить картинку по ширине и высоте
        let hScale = visibleRectSize.width / imageSize.width
        let vScale = visibleRectSize.height / imageSize.height
        
        // Выбираем подходящий масштаб в рамках наших min/max ограничений
        let scale = min(maxZoomScale, max(minZoomScale, min(hScale, vScale)))
        
        // Применяем масштаб
        scrollView.setZoomScale(scale, animated: false)
        scrollView.layoutIfNeeded()
        
        // Считаем сдвиг, чтобы картинка встала ровно по центру
        let newContentSize = scrollView.contentSize
        let x = (newContentSize.width - visibleRectSize.width) / 2
        let y = (newContentSize.height - visibleRectSize.height) / 2
        
        scrollView.setContentOffset(CGPoint(x: x, y: y), animated: false)
    }
    
}

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    // Этот метод срабатывает каждый раз, когда пальцы меняют масштаб
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


