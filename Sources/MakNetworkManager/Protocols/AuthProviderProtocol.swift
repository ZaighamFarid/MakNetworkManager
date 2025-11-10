//
//  AuthProviderProtocol.swift
//  MakNetworkManager
//
//  Protocol for handling authentication and token management
//

import Foundation

/// Protocol for providing authentication tokens and handling token refresh
/// Implement this protocol to integrate with your authentication system
public protocol AuthProviderProtocol {
    /// Get the current Bearer token
    /// - Returns: Bearer token string or nil if not authenticated
    func getBearerToken() -> String?
    
    /// Refresh the authentication token
    /// - Returns: New bearer token
    /// - Throws: NetworkError if refresh fails
    func refreshToken() async throws -> String
    
    /// Check if token refresh is currently in progress
    var isRefreshing: Bool { get }
}
