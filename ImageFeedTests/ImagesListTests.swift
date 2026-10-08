//
@testable import ImageFeed
import XCTest

@MainActor
final class ImagesListTests: XCTestCase {
    
    func testViewControllerCallsViewDidLoad() {
        let viewController = ImagesListViewController()
        let presenter = ImagesListPresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController
        
        _ = viewController.view
        
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }
    
    func testnumberOfRows() {
        let photos = [
            Photo(id: "1", size: .zero, createdAt: nil, welcomeDescription: "First photo", thumbImageURL: "", largeImageURL: "", isLiked: true),
            Photo(id: "2", size: .zero, createdAt: nil, welcomeDescription: "Second photo", thumbImageURL: "", largeImageURL: "", isLiked: false),
            Photo(id: "3", size: .zero, createdAt: nil, welcomeDescription: "Third photo", thumbImageURL: "", largeImageURL: "", isLiked: true)
        ]
        let presenter = ImagesListPresenter(photos: photos)
        
        let count = presenter.numberOfRows()
        
        XCTAssertEqual(photos.count, count)
    }
    
    func testupdateTableViewAnimated() {
        
        let viewController = ImagesListViewControllerSpy()
        let presenter = ImagesListPresenter()
        viewController.presenter = presenter
        presenter.view = viewController
        
        NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: nil)
        
        XCTAssertTrue(viewController.updateTableViewAnimatedCalled)
    }
    
}
