//
//  OAuth2Service.swift
//  ImageFeed
//
//

// OAuth2Service.swift

import Foundation

final class OAuth2Service {
    static let shared = OAuth2Service()

    private init() {}

    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard var urlComponents = URLComponents(
            string: WebViewConstants.unsplashTokenURLString
        ) else {
            print("[OAuth2Service] ❌ Ошибка: Не удалось создать URLComponents из строки: \(WebViewConstants.unsplashTokenURLString)")
            return nil
        }

        urlComponents.queryItems = [
            URLQueryItem(
                name: "client_id",
                value: Constants.accessKey
            ),
            URLQueryItem(
                name: "client_secret",
                value: Constants.secretKey
            ),
            URLQueryItem(
                name: "redirect_uri",
                value: Constants.redirectURI
            ),
            URLQueryItem(
                name: "code",
                value: code
            ),
            URLQueryItem(
                name: "grant_type",
                value: "authorization_code"
            )
        ]

        guard let url = urlComponents.url else {
            print("[OAuth2Service] ❌ Ошибка: Не удалось получить URL из urlComponents")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        return request
    }

    func fetchAuthToken(
        _ code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let request = makeOAuthTokenRequest(code: code) else {
            print("[OAuth2Service] ❌ Ошибка: Не удалось создать URLRequest")
            DispatchQueue.main.async {
                completion(.failure(NetworkError.invalidRequest))
            }
            return
        }

        URLSession.shared.data(for: request) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(
                        OAuthTokenResponseBody.self,
                        from: data
                    )

                    completion(.success(response.accessToken))
                } catch {
                    print("[OAuth2Service] Ошибка декодирования: \(error)")
                    completion(.failure(NetworkError.decodingError(error)))
                }

            case .failure(let error):
                print("[OAuth2Service] Ошибка запроса: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
}
