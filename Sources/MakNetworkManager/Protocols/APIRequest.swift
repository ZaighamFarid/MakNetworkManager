//
//  APIRequest.swift
//  MakNetworkManager
//
//  Protocol defining the structure of an API endpoint
//

import Foundation

/// Protocol that defines the structure of an API request
/// Adopt this protocol to create type-safe API endpoint definitions
public protocol APIRequest {
    /// The base URL for the request
    var baseURL: URL { get }
    
    /// The path component to append to the base URL
    var path: String { get }
    
    /// The HTTP method for the request
    var method: HTTPMethod { get }
    
    /// HTTP headers for the request
    var headers: [String: String]? { get }
    
    /// Parameters to be sent with the request
    var parameters: [String: Any]? { get }
    
    /// Whether this request requires an authentication token
    var requiresAuthToken: Bool { get }
    
    /// Custom timeout for this specific request (optional)
    var timeout: TimeInterval? { get }
}

/// Default implementations for convenience
public extension APIRequest {
    /// Default headers - can be overridden
    var headers: [String: String]? {
        return nil
    }
    
    /// Default parameters - can be overridden
    var parameters: [String: Any]? {
        return nil
    }
    
    /// By default, requests don't require auth token
    var requiresAuthToken: Bool {
        return false
    }
    
    /// Default timeout - uses configuration timeout
    var timeout: TimeInterval? {
        return nil
    }
}
