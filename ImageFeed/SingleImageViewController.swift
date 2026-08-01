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
            guard isViewLoaded else { return }
            imageView.image = image
        }
    }
    
    // 2. Приватный аутлет (никто извне не может случайно сломать интерфейс)
    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 3. Когда экран сам загрузился в память, он берет картинку из коробки `image`
        // и кладёт её в `imageView`
        imageView.image = image
    }
}
