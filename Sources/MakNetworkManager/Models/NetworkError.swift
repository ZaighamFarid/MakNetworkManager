//
//  NetworkError.swift
//  MakNetworkManager
//
//  A unified, type-safe error system for all network operations
//

import Foundation

/// Unified error type for all network operations in MakNetworkManager
public enum NetworkError: Error, LocalizedError, Equatable {
    /// No internet connection available
    case noInternet
    
    /// Authentication failed or token expired
    case unauthorized
    
    /// Server error with status code and optional message
    case server(status: Int, message: String?)
    
    /// Failed to decode response data
    case decoding(String)
    
    /// Request timed out
    case timeout
    
    /// Invalid URL or request configuration
    case invalidRequest(String)
    
    /// Token refresh failed
    case tokenRefreshFailed
    
    /// Unknown error with underlying error
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .noInternet:
            return "No internet connection available"
        case .unauthorized:
            return "Authentication failed. Please log in again."
        case .server(let status, let message):
            if let message = message {
                return "Server error (\(status)): \(message)"
            }
            return "Server error with status code: \(status)"
        case .decoding(let details):
            return "Failed to decode response: \(details)"
        case .timeout:
            return "Request timed out"
        case .invalidRequest(let details):
            return "Invalid request: \(details)"
        case .tokenRefreshFailed:
            return "Failed to refresh authentication token"
        case .unknown(let details):
            return "An unexpected error occurred: \(details)"
        }
    }
    
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.noInternet, .noInternet),
             (.unauthorized, .unauthorized),
             (.timeout, .timeout),
             (.tokenRefreshFailed, .tokenRefreshFailed):
            return true
        case (.server(let lStatus, let lMessage), .server(let rStatus, let rMessage)):
            return lStatus == rStatus && lMessage == rMessage
        case (.decoding(let lDetails), .decoding(let rDetails)),
             (.invalidRequest(let lDetails), .invalidRequest(let rDetails)),
             (.unknown(let lDetails), .unknown(let rDetails)):
            return lDetails == rDetails
        default:
            return false
        }
    }
}
