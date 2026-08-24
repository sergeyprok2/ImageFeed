//
//  OAuthTokenResponseBody.swift
//  ImageFeed
//
//  Created by Сергей Иванов on 24.08.2026.
//

import Foundation

struct OAuthTokenResponseBody: Decodable {
    let accessToken: String

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}
