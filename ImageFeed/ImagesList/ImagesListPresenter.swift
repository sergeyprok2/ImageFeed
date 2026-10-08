
//

import UIKit

protocol ImagesListPresenterProtocol: AnyObject {
    var view: ImagesListViewControllerProtocol? { get set }
    func fetchPhotosNextPage()
    func numberOfRows() -> Int
    func numberOfRowsOldCount() -> Int
    func photo(at indexPath: IndexPath) -> Photo
    func didTapLike(at indexPath: IndexPath)
}

final class ImagesListPresenter: ImagesListPresenterProtocol {
    
    weak var view: ImagesListViewControllerProtocol?
    private let imagesListService = ImagesListService()
    private var photos: [Photo] = []
    private var imagesListServiceObserver: NSObjectProtocol?
    private var oldCountPhotos: Int = 0
    
    init(view: ImagesListViewControllerProtocol? = nil, photos: [Photo] = [], imagesListServiceObserver: NSObjectProtocol? = nil) {
        self.view = view
        self.photos = photos
        self.imagesListServiceObserver = imagesListServiceObserver
        
        self.imagesListServiceObserver = NotificationCenter.default
            .addObserver(
                forName: ImagesListService.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                print("🔔 Получено уведомление. Было фото: \(oldCountPhotos), в сервисе: \(imagesListService.photos.count)")
                oldCountPhotos = self.photos.count
                self.photos = self.imagesListService.photos
                self.view?.updateTableViewAnimated()
                UIBlockingProgressHUD.dismiss()
                
            }
    }
     // загрузка следующей страницы
    func fetchPhotosNextPage() {
        // Здесь скоро вызовем сервис для загрузки
        imagesListService.fetchPhotosNextPage()
    }
    
    func numberOfRows() -> Int {
        // количество элементов для таблицы
        return photos.count
    }
    
    func numberOfRowsOldCount() -> Int {
        return oldCountPhotos
    }
    
    // получаем конкретную фотографию по индексу (или IndexPath)
    func photo(at indexPath: IndexPath) -> Photo {
        return photos[indexPath.row]
    }
    
    func didTapLike(at indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.photos = self.imagesListService.photos
                    let newIsLiked = self.photos[indexPath.row].isLiked
                    print("2. [VC] Успех сети! Новое значение из массива: \(newIsLiked)")
                    
                    self.view?.updateLikeCell(at: indexPath, isLiked: newIsLiked)
                    
                    UIBlockingProgressHUD.dismiss()
                    
                case .failure(let error):
                    UIBlockingProgressHUD.dismiss()
                    print("❌ [VC] Ошибка запроса: \(error)")
                }
            }
        }
    }
}
