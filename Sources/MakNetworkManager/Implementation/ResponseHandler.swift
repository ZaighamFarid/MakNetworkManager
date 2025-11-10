//
//  ResponseHandler.swift
//  MakNetworkManager
//
//  Handles and validates network responses
//

import Foundation

/// Default implementation of ResponseHandling protocol
public class ResponseHandler: ResponseHandling {
    private let logger: LoggerProtocol
    
    public init(logger: LoggerProtocol = DefaultLogger()) {
        self.logger = logger
    }
    
    public func handle(_ response: APIResponse) throws -> APIResponse {
        let statusCode = response.statusCode
        
        logger.debug("Handling response with status code: \(statusCode)", file: #file, function: #function, line: #line)
        
        switch statusCode {
        case 200...299:
            // Success
            return response
            
        case 401:
            // Unauthorized - token expired or invalid
            logger.error("Unauthorized (401)", error: nil, file: #file, function: #function, line: #line)
            throw NetworkError.unauthorized
            
        case 400...499:
            // Client error
            let message = parseErrorMessage(from: response.data)
            logger.error("Client error (\(statusCode)): \(message ?? "Unknown")", error: nil, file: #file, function: #function, line: #line)
            throw NetworkError.server(status: statusCode, message: message)
            
        case 500...599:
            // Server error
            let message = parseErrorMessage(from: response.data)
            logger.error("Server error (\(statusCode)): \(message ?? "Unknown")", error: nil, file: #file, function: #function, line: #line)
            throw NetworkError.server(status: statusCode, message: message)
            
        default:
            // Unknown status code
            logger.error("Unknown status code: \(statusCode)", error: nil, file: #file, function: #function, line: #line)
            throw NetworkError.unknown("Unexpected status code: \(statusCode)")
        }
    }
    
    /// Attempt to parse error message from response data
    private func parseErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        // Try common error message keys
        if let message = json["message"] as? String {
            return message
        }
        
        if let message = json["error"] as? String {
            return message
        }
        
        if let errors = json["errors"] as? [String: Any],
           let detail = errors["detail"] as? String {
            return detail
        }
        
        if let detail = json["detail"] as? String {
            return detail
        }
        
        return nil
    }
}
