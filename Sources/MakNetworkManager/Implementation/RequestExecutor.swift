//
//  RequestExecutor.swift
//  MakNetworkManager
//
//  Executes network requests using URLSession
//

import Foundation

/// Default implementation of NetworkExecuting protocol
public class RequestExecutor: NetworkExecuting {
    private let session: URLSession
    private let logger: LoggerProtocol
    
    public init(
        session: URLSession = .shared,
        logger: LoggerProtocol = DefaultLogger()
    ) {
        self.session = session
        self.logger = logger
    }
    
    public func execute(_ request: URLRequest) async throws -> APIResponse {
        logger.info("Executing request: \(request.httpMethod ?? "UNKNOWN") \(request.url?.absoluteString ?? "nil")", file: #file, function: #function, line: #line)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown("Invalid response type")
            }
            
            logger.info("Received response: Status \(httpResponse.statusCode)", file: #file, function: #function, line: #line)
            
            return APIResponse(
                statusCode: httpResponse.statusCode,
                data: data,
                request: request,
                response: httpResponse
            )
        } catch let error as URLError {
            // Map URLError to NetworkError
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost:
                logger.error("No internet connection", error: error, file: #file, function: #function, line: #line)
                throw NetworkError.noInternet
            case .timedOut:
                logger.error("Request timed out", error: error, file: #file, function: #function, line: #line)
                throw NetworkError.timeout
            default:
                logger.error("Network error occurred", error: error, file: #file, function: #function, line: #line)
                throw NetworkError.unknown(error.localizedDescription)
            }
        } catch let error as NetworkError {
            // Re-throw NetworkError as-is
            throw error
        } catch {
            // Unknown error
            logger.error("Unknown error occurred", error: error, file: #file, function: #function, line: #line)
            throw NetworkError.unknown(error.localizedDescription)
        }
    }
}
