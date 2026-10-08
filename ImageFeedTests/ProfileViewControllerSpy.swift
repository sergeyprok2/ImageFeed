//
@testable import ImageFeed
import Foundation

final class ProfileViewControllerSpy: ProfileViewControllerProtocol {
    var presenter: ProfilePresenterProtocol?
    var updateAvatarCalled: Bool = false
    var updateProfileDetailsCalled: Bool = false
    var showExitCalled: Bool = false
    
    func updateAvatar(url: URL?) {
        updateAvatarCalled = true
    }
    
    func updateProfileDetails(profile: Profile) {
        updateProfileDetailsCalled = true
    }
    
    func showExit() {
        showExitCalled = true
    }
    
    

}
