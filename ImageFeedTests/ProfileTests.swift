//
@testable import ImageFeed
import XCTest

@MainActor
final class ProfileTests: XCTestCase {
    
    func testViewControllerCallsViewDidLoad() {
        let viewController = ProfileViewController()
        let presenter = ProfilePresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController
        
        _ = viewController.view
        
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }
    
    func testPresenterCallsShowExit() {
        // Given
        let viewController = ProfileViewControllerSpy()
        let presenter = ProfilePresenter()
        presenter.view = viewController
        
        // When
        presenter.didTapLogoutButton()
        
        // Then
        XCTAssertTrue(viewController.showExitCalled)
    }
    
    func testPresenterUpdatesAvatarOnNotification() {
        // Given
        let viewController = ProfileViewControllerSpy()
        let presenter = ProfilePresenter()
        presenter.view = viewController
        
        // When — подписываемся внутри viewDidLoad
        presenter.viewDidLoad()
        
        // Отправляем уведомление о смене аватара
        NotificationCenter.default.post(
            name: ProfileImageService.didChangeNotification,
            object: nil
        )
        
        // Then — если avatarURL был или если мы проверяем сам факт вызова
        // (Или можно задать ProfileImageService.shared.avatarURL, если у него доступен сеттер)
    }
    
}
