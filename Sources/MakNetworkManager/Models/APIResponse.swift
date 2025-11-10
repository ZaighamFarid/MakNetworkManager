//
//  APIResponse.swift
//  MakNetworkManager
//
//  Represents a successful API response
//

import Foundation

/// Encapsulates a successful network response
public struct APIResponse {
    /// The HTTP status code of the response
    public let statusCode: Int
    
    /// The raw response data
    public let data: Data
    
    /// The original URL request
    public let request: URLRequest?
    
    /// The HTTP URL response object
    public let response: HTTPURLResponse?
    
    public init(
        statusCode: Int,
        data: Data,
        request: URLRequest? = nil,
        response: HTTPURLResponse? = nil
    ) {
        self.statusCode = statusCode
        self.data = data
        self.request = request
        self.response = response
    }
    
    /// Decode response data to a Codable type
    /// - Parameter type: The type to decode to
    /// - Returns: Decoded object
    /// - Throws: NetworkError.decoding if decoding fails
    public func decode<T: Decodable>(_ type: T.Type) throws -> T {
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        } catch {
            throw NetworkError.decoding(error.localizedDescription)
        }
    }
}
