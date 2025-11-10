//
//  NetworkConfiguration.swift
//  MakNetworkManager
//
//  Configuration object for SDK initialization
//

import Foundation

/// Configuration object containing all necessary settings for the SDK
public struct NetworkConfiguration {
    /// Base URL for API endpoints
    public let baseURL: URL
    
    /// OAuth/Authentication base URL (if different from baseURL)
    public let oauthURL: URL
    
    /// Client ID for API authentication
    public let clientID: String
    
    /// Client secret for API authentication
    public let clientSecret: String
    
    /// API version string (optional)
    public let apiVersion: String
    
    /// Default request timeout interval in seconds
    public let timeout: TimeInterval
    
    /// Default headers to be included in all requests
    public let defaultHeaders: [String: String]
    
    /// Enable debug logging
    public let enableLogging: Bool
    
    /// Initialize a new network configuration
    /// - Parameters:
    ///   - baseURL: Base URL for API endpoints
    ///   - oauthURL: OAuth/Authentication base URL
    ///   - clientID: Client ID for authentication
    ///   - clientSecret: Client secret for authentication
    ///   - apiVersion: API version string (default: "v1")
    ///   - timeout: Request timeout in seconds (default: 30)
    ///   - defaultHeaders: Default headers for all requests
    ///   - enableLogging: Enable debug logging (default: false)
    public init(
        baseURL: URL,
        oauthURL: URL? = nil,
        clientID: String,
        clientSecret: String,
        apiVersion: String = "v1",
        timeout: TimeInterval = 30,
        defaultHeaders: [String: String] = [:],
        enableLogging: Bool = false
    ) {
        self.baseURL = baseURL
        self.oauthURL = oauthURL ?? baseURL
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.apiVersion = apiVersion
        self.timeout = timeout
        
        // Merge with default headers
        var headers = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        headers.merge(defaultHeaders) { _, new in new }
        self.defaultHeaders = headers
        
        self.enableLogging = enableLogging
    }
}
