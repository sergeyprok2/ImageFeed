/// **Сетевой сервис списка фотографий (Слой данных / Model)**
///
/// **За что отвечает:**
/// Это слой данных и сети. Его единственная задача — сходить в сеть, получить JSON,
/// распарсить его в модели Photo, хранить их и отдать результат (или сообщить об ошибке).
///
/// Задачи:
/// 1. Отправляет запросы к Unsplash API для пагинации списков.
/// 2. Декодирует JSON-ответы в модели Photo и хранит их массив.
/// 3. Уведомляет подписчиков о получении новых данных через NotificationCenter.
///
/// **Правило:**
/// Он ничего не должен знать про экраны, кнопки или спиннеры.
/// Уведомляет UI только через NotificationCenter.

import Foundation

final class ImagesListService {
    private(set) var photos: [Photo] = []
    
    static let shared = ImagesListService()
    
    private var lastLoadedPage: Int?
    private var task: URLSessionTask?
    
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    
    func fetchPhotosNextPage() {
        guard task == nil else { return }

        let nextPage = (lastLoadedPage ?? 0) + 1

        guard let token = OAuth2TokenStorage.shared.token else {
            print("[fetchPhotosNextPage ImagesListService]: [Ошибка авторизации] [Токен отсутствует, Страница: \(nextPage)]")
            return
        }
        guard let request = makePhotoRequest(page: nextPage, token: token) else {
            print("[fetchPhotosNextPage ImagesListService]: [Ошибка формирования URLRequest] [Страница: \(nextPage)]")
            return
        }

        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self = self else { return }

            switch result {
            case .success(let photoResults):
                let newPhotos = photoResults.map { Photo(from: $0) }
                self.photos.append(contentsOf: newPhotos)
                self.lastLoadedPage = nextPage

                NotificationCenter.default.post(
                    name: Self.didChangeNotification,
                    object: self
                )

            case .failure(let error):
                print("[fetchPhotosNextPage ImagesListService]: [Ошибка загрузки страницы] [Страница: \(nextPage), Ошибка: \(error.localizedDescription)]")
            }

            self.task = nil
        }

        self.task = task
        task.resume()
    }

    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "https://api.unsplash.com/photos/\(photoId)/like") else {
            let error = NetworkError.invalidRequest
            print("[changeLike ImagesListService]: [Некорректный URL] [ID фото: \(photoId), Состояние лайка: \(isLike)]")
            completion(.failure(error))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"
        
        guard let token = OAuth2TokenStorage.shared.token else {
            let error = NetworkError.invalidRequest
            print("[changeLike ImagesListService]: [Ошибка авторизации] [ID фото: \(photoId), Токен отсутствует]")
            completion(.failure(error))
            return
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<LikeResult, Error>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let likeResult):
                let photoResult = likeResult.photo
                
                if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                    let newPhoto = Photo(from: photoResult)
                    self.photos[index] = newPhoto
                }
                completion(.success(()))
                
            case .failure(let error):
                print("[changeLike ImagesListService]: [Ошибка изменения лайка] [ID фото: \(photoId), Состояние лайка: \(isLike), Ошибка: \(error.localizedDescription)]")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func clear() {
        photos = []
        lastLoadedPage = nil
    }
    
    private func makePhotoRequest(page: Int, token: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/photos?page=\(page)&per_page=10") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
