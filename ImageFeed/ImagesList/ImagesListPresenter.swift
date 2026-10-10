/// /// **Презентер для экрана ленты фотографий (Слой презентации / MVP)**
///
/// **За что отвечает:**
/// Управляет логикой отображения списка фотографий. Взаимодействует с `ImagesListService`
/// для получения данных и обработки лайков, а также запрашивает обновление UI у `ImagesListViewController`.
///
/// **Задачи:**
/// 1. Обрабатывает запросы пагинации и получает новые партии фотографий.
/// 2. Подписывается на уведомления сервиса для своевременного обновления таблицы.
/// 3. Предоставляет контроллеру данные о количестве строк и конкретных фото.
/// 4. Обрабатывает нажатие на кнопку лайка и передает результат в UI.

import UIKit

// MARK: - Protocol

/// Протокол презентера для управления экраном ленты фотографий
protocol ImagesListPresenterProtocol: AnyObject {
    var view: ImagesListViewControllerProtocol? { get set }
    func fetchPhotosNextPage()
    func numberOfRows() -> Int
    func numberOfRowsOldCount() -> Int
    func photo(at indexPath: IndexPath) -> Photo
    func didTapLike(at indexPath: IndexPath)
}

// MARK: - Presenter

final class ImagesListPresenter: ImagesListPresenterProtocol {

    // MARK: - Public Properties

    weak var view: ImagesListViewControllerProtocol?

    // MARK: - Private Properties

    private let imagesListService = ImagesListService()
    private var photos: [Photo] = []
    private var imagesListServiceObserver: NSObjectProtocol?
    private var oldCountPhotos: Int = 0

    // MARK: - Initialization

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
                
                self.oldCountPhotos = self.photos.count
                self.photos = self.imagesListService.photos
                self.view?.updateTableViewAnimated()
                UIBlockingProgressHUD.dismiss()
            }
    }

    // MARK: - Public Methods

    /// Запрашивает загрузку следующей страницы фотографий в сервисе
    func fetchPhotosNextPage() {
        imagesListService.fetchPhotosNextPage()
    }

    /// Возвращает текущее количество фотографий для отображения в таблице
    func numberOfRows() -> Int {
        return photos.count
    }

    /// Возвращает количество фотографий до последнего обновления (для анимации вставки)
    func numberOfRowsOldCount() -> Int {
        return oldCountPhotos
    }

    /// Возвращает объект фотографии по переданному индексу
    func photo(at indexPath: IndexPath) -> Photo {
        return photos[indexPath.row]
    }

    /// Обрабатывает нажатие на кнопку лайка и отправляет сетевой запрос
    func didTapLike(at indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        
        imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.photos = self.imagesListService.photos
                    let newIsLiked = self.photos[indexPath.row].isLiked

                    self.view?.updateLikeCell(at: indexPath, isLiked: newIsLiked)
                    UIBlockingProgressHUD.dismiss()

                case .failure(let error):
                    UIBlockingProgressHUD.dismiss()
                    print("[didTapLike ImagesListPresenter]: [Ошибка изменения лайка] [ID: \(photo.id), Ошибка: \(error)]")
                }
            }
        }
    }
}
