//
//  ExampleNetworkManager.swift
//  MakNetworkManagerExample
//
//  Centralized network manager for the example app
//

import Foundation
import MakNetworkManager

class ExampleNetworkManager: ObservableObject {
    static let shared = ExampleNetworkManager()
    
    let apiService: APIService
    let authProvider: ExampleAuthProvider
    let reachability: Reachability
    
    @Published var networkStatus: NetworkStatus = .unavailable
    @Published var isOnline: Bool = false
    
    private init() {
        // Configure the SDK with mock/example URLs
        let configuration = NetworkConfiguration(
            baseURL: URL(string: "https://jsonplaceholder.typicode.com/")!,
            oauthURL: URL(string: "https://jsonplaceholder.typicode.com/")!,
            clientID: "example_client_id",
            clientSecret: "example_client_secret",
            enableLogging: true
        )
        
        // Initialize auth provider
        self.authProvider = ExampleAuthProvider()
        
        // Initialize reachability
        self.reachability = Reachability()
        
        // Initialize API service
        self.apiService = APIService(
            configuration: configuration,
            reachability: reachability,
            authProvider: authProvider
        )
        
        // Start monitoring network
        setupReachability()
    }
    
    private func setupReachability() {
        reachability.startMonitoring()
        
        NotificationCenter.default.addObserver(
            forName: .networkStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let status = notification.userInfo?["status"] as? NetworkStatus {
                self?.networkStatus = status
                self?.isOnline = status != .unavailable
            }
        }
        
        // Set initial status
        self.networkStatus = reachability.status
        self.isOnline = reachability.isReachable
    }
    
    deinit {
        reachability.stopMonitoring()
    }
}

/// Example Auth Provider (for demo purposes)
class ExampleAuthProvider: AuthProviderProtocol {
    @Published private(set) var isRefreshing = false
    private var accessToken: String?
    
    func getBearerToken() -> String? {
        return accessToken.map { "Bearer \($0)" }
    }
    
    func refreshToken() async throws -> String {
        isRefreshing = true
        defer { isRefreshing = false }
        
        // Simulate token refresh
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let newToken = UUID().uuidString
        self.accessToken = newToken
        return newToken
    }
    
    func setToken(_ token: String) {
        self.accessToken = token
    }
}
