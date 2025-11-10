//
//  NetworkProtocols.swift
//  MakNetworkManager
//
//  Core networking protocols for request building and execution
//

import Foundation

/// Protocol for building URLRequests from APIRequest objects
public protocol RequestBuilding {
    /// Build a URLRequest from an APIRequest
    /// - Parameters:
    ///   - request: The APIRequest to build from
    ///   - configuration: Network configuration
    /// - Returns: A configured URLRequest
    /// - Throws: NetworkError if request building fails
    func buildRequest(
        from request: APIRequest,
        configuration: NetworkConfiguration
    ) throws -> URLRequest
}

/// Protocol for executing network requests
public protocol NetworkExecuting {
    /// Execute a URLRequest and return the response
    /// - Parameter request: The URLRequest to execute
    /// - Returns: APIResponse containing the result
    /// - Throws: NetworkError if execution fails
    func execute(_ request: URLRequest) async throws -> APIResponse
}

/// Protocol for handling and parsing responses
public protocol ResponseHandling {
    /// Handle a network response and route to appropriate outcome
    /// - Parameter response: The APIResponse to handle
    /// - Returns: Processed APIResponse for success cases
    /// - Throws: NetworkError for failure cases
    func handle(_ response: APIResponse) throws -> APIResponse
}
