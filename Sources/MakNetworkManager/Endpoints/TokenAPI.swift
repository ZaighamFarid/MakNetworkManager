//
//  TokenAPI.swift
//  MakNetworkManager
//
//  Example authentication/token API endpoints
//

import Foundation

/// Example API endpoints for authentication operations
public enum TokenAPI: APIRequest {
    case login(email: String, password: String)
    case refreshToken(refreshToken: String)
    case logout
    
    public var baseURL: URL {
        // This should come from NetworkConfiguration's oauthURL
        return URL(string: "https://auth.example.com/")!
    }
    
    public var path: String {
        switch self {
        case .login:
            return "auth/login"
        case .refreshToken:
            return "auth/refresh"
        case .logout:
            return "auth/logout"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .login, .refreshToken, .logout:
            return .post
        }
    }
    
    public var parameters: [String: Any]? {
        switch self {
        case .login(let email, let password):
            return ["email": email, "password": password]
        case .refreshToken(let token):
            return ["refresh_token": token]
        case .logout:
            return nil
        }
    }
    
    public var requiresAuthToken: Bool {
        switch self {
        case .login, .refreshToken:
            return false
        case .logout:
            return true
        }
    }
}

/// Example token response
public struct TokenResponse: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
    
    public init(accessToken: String, refreshToken: String, expiresIn: Int) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }
}
