//
//  RequestBuilder.swift
//  MakNetworkManager
//
//  Builds URLRequests from APIRequest objects
//

import Foundation

/// Default implementation of RequestBuilding protocol
public class RequestBuilder: RequestBuilding {
    private let logger: LoggerProtocol
    
    public init(logger: LoggerProtocol = DefaultLogger()) {
        self.logger = logger
    }
    
    public func buildRequest(
        from request: APIRequest,
        configuration: NetworkConfiguration
    ) throws -> URLRequest {
        // Construct full URL
        guard var urlComponents = URLComponents(url: request.baseURL, resolvingAgainstBaseURL: true) else {
            throw NetworkError.invalidRequest("Invalid base URL: \(request.baseURL)")
        }
        
        // Append path if not already included
        if !request.baseURL.absoluteString.contains(request.path) {
            urlComponents.path = urlComponents.path + "/" + request.path
        }
        
        // Add query parameters for GET requests
        if request.method == .get, let parameters = request.parameters {
            var allowedCharSet = CharacterSet.urlQueryAllowed
            allowedCharSet.remove(charactersIn: "+")
            
            urlComponents.percentEncodedQuery = parameters.compactMap { key, value in
                guard let encodedKey = key.addingPercentEncoding(withAllowedCharacters: allowedCharSet),
                      let encodedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: allowedCharSet) else {
                    logger.debug("Failed to encode parameter: \(key)=\(value)", file: #file, function: #function, line: #line)
                    return nil
                }
                return "\(encodedKey)=\(encodedValue)"
            }.joined(separator: "&")
        }
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidRequest("Failed to construct URL from components")
        }
        
        // Create URLRequest
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.timeoutInterval = request.timeout ?? configuration.timeout
        
        // Add default headers from configuration
        configuration.defaultHeaders.forEach { key, value in
            urlRequest.addValue(value, forHTTPHeaderField: key)
        }
        
        // Add custom headers from request
        request.headers?.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add body parameters for POST, PUT, PATCH requests
        if [HTTPMethod.post, .put, .patch].contains(request.method),
           let parameters = request.parameters {
            do {
                urlRequest.httpBody = try JSONSerialization.data(
                    withJSONObject: parameters,
                    options: .prettyPrinted
                )
            } catch {
                throw NetworkError.invalidRequest("Failed to serialize parameters: \(error.localizedDescription)")
            }
        }
        
        logger.debug("Built request: \(request.method.rawValue) \(url.absoluteString)", file: #file, function: #function, line: #line)
        
        return urlRequest
    }
}
