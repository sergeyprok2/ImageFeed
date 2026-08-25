//
//  AuthViewController.swift
//  ImageFeed
//
//


import UIKit

protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController)
}

final class AuthViewController: UIViewController {
    private let showWebViewSegueIdentifier = "ShowWebView"
    private let oauth2Service = OAuth2Service.shared
    private let oauth2TokenStorage = OAuth2TokenStorage()
    
    weak var delegate: AuthViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureBackButton()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == showWebViewSegueIdentifier else {
            super.prepare(for: segue, sender: sender)
            return
        }

        guard let webViewViewController = segue.destination as? WebViewViewController else {
            assertionFailure("Failed to prepare for \(showWebViewSegueIdentifier)")
            return
        }

        webViewViewController.delegate = self
    }

    private func configureBackButton() {
        navigationController?.navigationBar.backIndicatorImage =
            UIImage(named: "nav_back_button")

        navigationController?.navigationBar.backIndicatorTransitionMaskImage =
            UIImage(named: "nav_back_button")

        navigationItem.backBarButtonItem = UIBarButtonItem(
            title: "",
            style: .plain,
            target: nil,
            action: nil
        )

        navigationItem.backBarButtonItem?.tintColor =
            UIColor(named: "ypBlack")
    }
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(
        _ vc: WebViewViewController,
        didAuthenticateWithCode code: String
    ) {
        
        oauth2Service.fetchAuthToken(code) { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .success(let token):
                self.oauth2TokenStorage.token = token
                print("[AuthViewController] Токен сохранён")
                // Уведомляем делегат (SplashViewController) об успешной авторизации
                self.delegate?.didAuthenticate(self)

            case .failure(let error):
                print("[AuthViewController] Ошибка получения токена: \(error)")
            }
        }
    }

    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        navigationController?.popViewController(animated: true)
    }
}


