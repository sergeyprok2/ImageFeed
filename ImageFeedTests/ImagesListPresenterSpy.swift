//
@testable import ImageFeed
import Foundation
import CoreGraphics

final class ImagesListPresenterSpy: ImagesListPresenterProtocol {
    
    var view: ImagesListViewControllerProtocol?
    var viewDidLoadCalled: Bool = false
    
    func fetchPhotosNextPage() {
        viewDidLoadCalled = true
    }
    
    func numberOfRows() -> Int {
        return 0
    }
    
    func numberOfRowsOldCount() -> Int {
        return 0
    }
    
    func photo(at indexPath: IndexPath) -> Photo {
        return Photo(id: "", size: .zero, createdAt: nil, welcomeDescription: nil, thumbImageURL: "", largeImageURL: "", isLiked: false)
    }
    
    func didTapLike(at indexPath: IndexPath) {
        
    }
}
