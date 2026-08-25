//
//  OAuth2TokenStorage.swift
//  ImageFeed
//
//


import Foundation

final class OAuth2TokenStorage {
    private let userDefaults = UserDefaults.standard
    private let tokenKey = "bearer_token"
    
    var token: String? {
        get {
            userDefaults.string(forKey: tokenKey)
        }
        set {
            if let newToken = newValue {
                userDefaults.set(newToken, forKey: tokenKey)
            } else {
                userDefaults.removeObject(forKey: tokenKey)
            }
        }
    }
}
