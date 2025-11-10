//
//  APIService.swift
//  MakNetworkManager
//
//  Main service orchestrating network requests with automatic token refresh
//

import Foundation

/// Main network service that coordinates all API requests
public class APIService {
    private let configuration: NetworkConfiguration
    private let requestBuilder: RequestBuilding
    private let requestExecutor: NetworkExecuting
    private let responseHandler: ResponseHandling
    private let reachability: ReachabilityProtocol
    private let logger: LoggerProtocol
    private var authProvider: AuthProviderProtocol?
    
    // Token refresh queue management
    private let refreshQueue = DispatchQueue(label: "com.networkcore.tokenrefresh", attributes: .concurrent)
    private var isRefreshingToken = false
    private var pendingRequests: [(request: APIRequest, continuation: CheckedContinuation<APIResponse, Error>)] = []
    
    /// Initialize the API service with dependencies
    /// - Parameters:
    ///   - configuration: Network configuration
    ///   - requestBuilder: Request builder implementation
    ///   - requestExecutor: Request executor implementation
    ///   - responseHandler: Response handler implementation
    ///   - reachability: Reachability monitor
    ///   - logger: Logger implementation
    ///   - authProvider: Optional auth provider for token management
    public init(
        configuration: NetworkConfiguration,
        requestBuilder: RequestBuilding = RequestBuilder(),
        requestExecutor: NetworkExecuting = RequestExecutor(),
        responseHandler: ResponseHandling = ResponseHandler(),
        reachability: ReachabilityProtocol = Reachability(),
        logger: LoggerProtocol? = nil,
        authProvider: AuthProviderProtocol? = nil
    ) {
        self.configuration = configuration
        self.requestBuilder = requestBuilder
        self.requestExecutor = requestExecutor
        self.responseHandler = responseHandler
        self.reachability = reachability
        self.logger = logger ?? DefaultLogger(isEnabled: configuration.enableLogging)
        self.authProvider = authProvider
        
        // Start monitoring network status
        self.reachability.startMonitoring()
    }
    
    deinit {
        reachability.stopMonitoring()
    }
    
    /// Set or update the auth provider
    /// - Parameter provider: Auth provider implementation
    public func setAuthProvider(_ provider: AuthProviderProtocol?) {
        self.authProvider = provider
    }
    
    /// Perform an API request with automatic token refresh on 401
    /// - Parameter request: The API request to perform
    /// - Returns: API response
    /// - Throws: NetworkError if request fails
    public func perform<T: APIRequest>(_ request: T) async throws -> APIResponse {
        logger.logNetworkEvent("API_Request_Started", parameters: ["path": request.path])
        
        // Check network reachability
        guard reachability.isReachable else {
            logger.error("Network unavailable", error: nil, file: #file, function: #function, line: #line)
            throw NetworkError.noInternet
        }
        
        // Check if token refresh is in progress
        if isRefreshingToken {
            return try await queueRequest(request)
        }
        
        // Build the request
        var urlRequest = try requestBuilder.buildRequest(from: request, configuration: configuration)
        
        // Add auth token if required
        if request.requiresAuthToken {
            guard let token = authProvider?.getBearerToken() else {
                logger.error("Auth token required but not available", error: nil, file: #file, function: #function, line: #line)
                throw NetworkError.unauthorized
            }
            urlRequest.addValue(token, forHTTPHeaderField: "Authorization")
        }
        
        do {
            // Execute the request
            let response = try await requestExecutor.execute(urlRequest)
            
            // Handle the response
            let validatedResponse = try responseHandler.handle(response)
            
            logger.logNetworkEvent("API_Request_Success", parameters: ["path": request.path, "status": validatedResponse.statusCode])
            return validatedResponse
            
        } catch NetworkError.unauthorized {
            // Token expired - attempt refresh and retry
            if request.requiresAuthToken, authProvider != nil {
                logger.info("Token expired, attempting refresh", file: #file, function: #function, line: #line)
                return try await handleTokenRefresh(for: request)
            }
            throw NetworkError.unauthorized
            
        } catch {
            logger.logNetworkEvent("API_Request_Failed", parameters: ["path": request.path, "error": error.localizedDescription])
            throw error
        }
    }
    
    /// Perform request and decode response to Codable type
    /// - Parameters:
    ///   - request: The API request to perform
    ///   - type: The Codable type to decode to
    /// - Returns: Decoded object
    /// - Throws: NetworkError if request or decoding fails
    public func perform<T: APIRequest, R: Decodable>(_ request: T, decoding type: R.Type) async throws -> R {
        let response = try await perform(request)
        return try response.decode(type)
    }
    
    // MARK: - Token Refresh Logic
    
    private func handleTokenRefresh<T: APIRequest>(for request: T) async throws -> APIResponse {
        return try await withCheckedThrowingContinuation { continuation in
            refreshQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: NetworkError.unknown("Service deallocated"))
                    return
                }
                
                // Queue the current request
                self.pendingRequests.append((request, continuation))
                
                // Only start refresh if not already in progress
                guard !self.isRefreshingToken else {
                    self.logger.debug("Token refresh already in progress, request queued", file: #file, function: #function, line: #line)
                    return
                }
                
                self.isRefreshingToken = true
                
                Task {
                    do {
                        // Attempt token refresh
                        guard let authProvider = self.authProvider else {
                            throw NetworkError.unauthorized
                        }
                        
                        self.logger.info("Starting token refresh", file: #file, function: #function, line: #line)
                        _ = try await authProvider.refreshToken()
                        
                        // Refresh successful - retry all pending requests
                        self.logger.info("Token refresh successful, retrying \(self.pendingRequests.count) pending requests", file: #file, function: #function, line: #line)
                        await self.retryPendingRequests()
                        
                    } catch {
                        // Refresh failed - fail all pending requests
                        self.logger.error("Token refresh failed", error: error, file: #file, function: #function, line: #line)
                        await self.failPendingRequests(with: NetworkError.tokenRefreshFailed)
                    }
                    
                    self.refreshQueue.async(flags: .barrier) {
                        self.isRefreshingToken = false
                    }
                }
            }
        }
    }
    
    private func queueRequest<T: APIRequest>(_ request: T) async throws -> APIResponse {
        return try await withCheckedThrowingContinuation { continuation in
            refreshQueue.async(flags: .barrier) { [weak self] in
                self?.pendingRequests.append((request, continuation))
                self?.logger.debug("Request queued while token refresh in progress", file: #file, function: #function, line: #line)
            }
        }
    }
    
    private func retryPendingRequests() async {
        let requests = refreshQueue.sync { self.pendingRequests }
        refreshQueue.async(flags: .barrier) { self.pendingRequests.removeAll() }
        
        for (request, continuation) in requests {
            Task {
                do {
                    let response = try await self.perform(request)
                    continuation.resume(returning: response)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func failPendingRequests(with error: NetworkError) async {
        let requests = refreshQueue.sync { self.pendingRequests }
        refreshQueue.async(flags: .barrier) { self.pendingRequests.removeAll() }
        
        for (_, continuation) in requests {
            continuation.resume(throwing: error)
        }
    }
}

// MARK: - Convenience Methods with Closures (for backward compatibility)

public extension APIService {
    /// Perform request with completion handlers (closure-based API)
    /// - Parameters:
    ///   - request: The API request
    ///   - success: Success completion handler
    ///   - failure: Failure completion handler
    func perform<T: APIRequest>(
        _ request: T,
        success: @escaping (APIResponse) -> Void,
        failure: @escaping (NetworkError) -> Void
    ) {
        Task {
            do {
                let response = try await perform(request)
                await MainActor.run {
                    success(response)
                }
            } catch let error as NetworkError {
                await MainActor.run {
                    failure(error)
                }
            } catch {
                await MainActor.run {
                    failure(.unknown(error.localizedDescription))
                }
            }
        }
    }
}
