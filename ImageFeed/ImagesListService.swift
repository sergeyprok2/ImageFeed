

import Foundation

struct UrlsResult: Codable {
    let thumb: String
    let full: String
}

struct PhotoResult: Codable {
    let id: String
    let width: Int
    let height: Int
    let createdAt: String?
    let description: String?
    let likedByUser: Bool
    let urls: UrlsResult
    
    private enum CodingKeys: String, CodingKey {
        case id
        case width
        case height
        case createdAt = "created_at"
        case description
        case likedByUser = "liked_by_user"
        case urls
    }
}

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    let isLiked: Bool
    private static let dateFormatter = ISO8601DateFormatter()
    
    init(from result: PhotoResult) {
        self.id = result.id
        self.size = CGSize(width: CGFloat(result.width), height: CGFloat(result.height))
        self.createdAt = Self.dateFormatter.date(from: result.createdAt ?? "")
        self.welcomeDescription = result.description
        self.thumbImageURL = result.urls.thumb
        self.largeImageURL = result.urls.full
        self.isLiked = result.likedByUser
    }
}

final class ImagesListService {
    private(set) var photos: [Photo] = []
    
    private var lastLoadedPage: Int?
    
    private var task: URLSessionTask?
    
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    
    func fetchPhotosNextPage() {
        guard task == nil else { return }
        
        let nextPage = (lastLoadedPage ?? 0) + 1
        
        guard let token = OAuth2TokenStorage.shared.token else {return}
        guard let request = makePhotoRequest(page: nextPage, token: token) else {return}

        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            switch result {
            case .success(let result):
                guard let self = self else { return }
                // превращаем массив из типа PhotoResult в тип Photo
                let newPhotos = result.map { Photo(from: $0) }
                // для того чтобы добавить в массив photos: [Photo] мы в предыдущей строчке привели массив result к типу Photo
                self.photos.append(contentsOf: newPhotos)
                self.lastLoadedPage = nextPage
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Self.didChangeNotification, object: self, userInfo: nil)
                }
            
            case .failure(let error):
                print("[fetchPhotosNextPage]: Ошибка запроса: \(error.localizedDescription)")
                
            }
            self?.task = nil
        }

        self.task = task
        task.resume()
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
