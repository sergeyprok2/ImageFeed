//
@testable import ImageFeed
import Foundation

final class ImagesListViewControllerSpy: ImagesListViewControllerProtocol {
    var presenter: ImagesListPresenterProtocol?
    var updateTableViewAnimatedCalled: Bool = false
    
    func updateTableViewAnimated() {
        updateTableViewAnimatedCalled = true
    }
    
    func updateLikeCell(at indexPath: IndexPath, isLiked: Bool) {
        
    }

}
