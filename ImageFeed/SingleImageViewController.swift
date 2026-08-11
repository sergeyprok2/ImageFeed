//
//  SingleImageViewController.swift
//  ImageFeed
//
//  Created by Сергей on 01.08.2026.
//

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
    
    // MARK: - Outlets
    @IBOutlet private var imageView: UIImageView!
    
    @IBOutlet private var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    // MARK: - Actions
    @IBAction private func didTapBackButton() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapShareButton(_ sender: Any) {
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
}


