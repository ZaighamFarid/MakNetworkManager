# MakNetworkManager Integration Guide

This guide walks you through integrating MakNetworkManager into your iOS project step by step.

## Table of Contents

1. [Installation](#installation)
2. [Initial Setup](#initial-setup)
3. [Creating Your API Definitions](#creating-your-api-definitions)
4. [Implementing Authentication](#implementing-authentication)
5. [Building Service Layers](#building-service-layers)
6. [Using in ViewModels/Views](#using-in-viewmodelsviews)
7. [Testing](#testing)
8. [Best Practices](#best-practices)

## Installation

### Step 1: Add Package

In Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/zaighamfarid/MakNetworkManager.git`
3. Click "Add Package"

### Step 2: Import Module

```swift
import MakNetworkManager
```

## Initial Setup

### Create a Network Manager (Singleton Pattern)

Create a `NetworkManager.swift` file in your project:

```swift
import MakNetworkManager

class NetworkManager {
    static let shared = NetworkManager()
    
    let apiService: APIService
    private let authProvider: AppAuthProvider
    
    private init() {
        // Configure the SDK
        let configuration = NetworkConfiguration(
            baseURL: URL(string: "https://api.yourapp.com/v1/")!,
            oauthURL: URL(string: "https://auth.yourapp.com/")!,
            clientID: "YOUR_CLIENT_ID",
            clientSecret: "YOUR_CLIENT_SECRET",
            enableLogging: true
        )
        
        // Create auth provider
        self.authProvider = AppAuthProvider()
        
        // Initialize API service
        self.apiService = APIService(
            configuration: configuration,
            authProvider: authProvider
        )
    }
}
```

## Creating Your API Definitions

### Step 1: Create API Endpoint Enums

Create a folder `Networking/APIs/` and add your API definitions:

```swift
// UserAPI.swift
import MakNetworkManager

enum UserAPI: APIRequest {
    case getCurrentUser
    case getUser(id: Int)
    case updateProfile(name: String, email: String)
    case uploadAvatar(imageData: Data)
    
    var baseURL: URL {
        return NetworkManager.shared.apiService.configuration.baseURL
    }
    
    var path: String {
        switch self {
        case .getCurrentUser:
            return "users/me"
        case .getUser(let id):
            return "users/\(id)"
        case .updateProfile:
            return "users/me"
        case .uploadAvatar:
            return "users/me/avatar"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getCurrentUser, .getUser:
            return .get
        case .updateProfile:
            return .put
        case .uploadAvatar:
            return .post
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .updateProfile(let name, let email):
            return ["name": name, "email": email]
        default:
            return nil
        }
    }
    
    var requiresAuthToken: Bool {
        return true // All user endpoints require auth
    }
}
```

### Step 2: Create Response Models

```swift
// User.swift
struct User: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
    let avatarURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case avatarURL = "avatar_url"
    }
}
```

## Implementing Authentication

### Create Auth Provider

```swift
// AppAuthProvider.swift
import MakNetworkManager
import Foundation

class AppAuthProvider: AuthProviderProtocol {
    @Published private(set) var isRefreshing = false
    
    private var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "accessToken") }
        set { UserDefaults.standard.set(newValue, forKey: "accessToken") }
    }
    
    private var refreshTokenValue: String? {
        get { UserDefaults.standard.string(forKey: "refreshToken") }
        set { UserDefaults.standard.set(newValue, forKey: "refreshToken") }
    }
    
    func getBearerToken() -> String? {
        guard let token = accessToken else { return nil }
        return "Bearer \(token)"
    }
    
    func refreshToken() async throws -> String {
        isRefreshing = true
        defer { isRefreshing = false }
        
        guard let refreshToken = refreshTokenValue else {
            throw NetworkError.unauthorized
        }
        
        // Call your token refresh endpoint
        let request = TokenAPI.refreshToken(refreshToken: refreshToken)
        let response = try await NetworkManager.shared.apiService.perform(
            request,
            decoding: TokenResponse.self
        )
        
        // Save new tokens
        self.accessToken = response.accessToken
        self.refreshTokenValue = response.refreshToken
        
        return response.accessToken
    }
    
    func saveTokens(access: String, refresh: String) {
        self.accessToken = access
        self.refreshTokenValue = refresh
    }
    
    func clearTokens() {
        self.accessToken = nil
        self.refreshTokenValue = nil
    }
}
```

## Building Service Layers

### Create Service Classes

```swift
// UserService.swift
import MakNetworkManager

class UserService {
    private let apiService: APIService
    
    init(apiService: APIService = NetworkManager.shared.apiService) {
        self.apiService = apiService
    }
    
    func getCurrentUser() async throws -> User {
        return try await apiService.perform(
            UserAPI.getCurrentUser,
            decoding: User.self
        )
    }
    
    func updateProfile(name: String, email: String) async throws -> User {
        return try await apiService.perform(
            UserAPI.updateProfile(name: name, email: email),
            decoding: User.self
        )
    }
}
```

## Using in ViewModels/Views

### SwiftUI Example

```swift
// ProfileViewModel.swift
import SwiftUI
import MakNetworkManager

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userService = UserService()
    
    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            user = try await userService.getCurrentUser()
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred"
        }
        
        isLoading = false
    }
    
    func updateProfile(name: String, email: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            user = try await userService.updateProfile(name: name, email: email)
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to update profile"
        }
        
        isLoading = false
    }
}

// ProfileView.swift
struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else if let user = viewModel.user {
                VStack {
                    Text(user.name)
                        .font(.title)
                    Text(user.email)
                        .font(.subheadline)
                }
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .task {
            await viewModel.loadProfile()
        }
    }
}
```

## Testing

### Unit Testing with Mocks

```swift
import XCTest
@testable import YourApp
@testable import MakNetworkManager

class UserServiceTests: XCTestCase {
    var userService: UserService!
    var mockSession: URLSession!
    
    override func setUp() {
        super.setUp()
        
        // Setup mock session
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        mockSession = URLSession(configuration: config)
        
        let executor = RequestExecutor(session: mockSession)
        let testConfig = NetworkConfiguration(
            baseURL: URL(string: "https://api.test.com")!,
            clientID: "test",
            clientSecret: "test"
        )
        
        let apiService = APIService(
            configuration: testConfig,
            requestExecutor: executor
        )
        
        userService = UserService(apiService: apiService)
    }
    
    override func tearDown() {
        URLProtocolMock.reset()
        super.tearDown()
    }
    
    func testGetCurrentUser() async throws {
        // Setup mock response
        let mockData = """
        {
            "id": 1,
            "name": "Test User",
            "email": "test@example.com",
            "avatar_url": null
        }
        """.data(using: .utf8)!
        
        URLProtocolMock.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (mockData, response, nil)
        }
        
        // Test
        let user = try await userService.getCurrentUser()
        
        XCTAssertEqual(user.id, 1)
        XCTAssertEqual(user.name, "Test User")
        XCTAssertEqual(user.email, "test@example.com")
    }
}
```

## Best Practices

### 1. Centralize Configuration

Keep all network configuration in one place:

```swift
enum AppConfig {
    static var apiBaseURL: URL {
        #if DEBUG
        return URL(string: "https://staging-api.yourapp.com")!
        #else
        return URL(string: "https://api.yourapp.com")!
        #endif
    }
}
```

### 2. Use Dependency Injection

```swift
class MyViewModel {
    private let userService: UserService
    
    init(userService: UserService = UserService()) {
        self.userService = userService
    }
}
```

### 3. Handle Errors Gracefully

```swift
func handleError(_ error: NetworkError) {
    switch error {
    case .noInternet:
        showAlert("No internet connection")
    case .unauthorized:
        // Redirect to login
        logout()
    case .server(let status, let message):
        showAlert(message ?? "Server error (\(status))")
    default:
        showAlert("Something went wrong")
    }
}
```

### 4. Use Type-Safe Endpoints

Always use enums for API endpoints instead of raw strings:

```swift
// ✅ Good
let request = UserAPI.getUser(id: 123)

// ❌ Bad
let url = "https://api.example.com/users/123"
```

### 5. Implement Retry Logic for Critical Operations

```swift
func fetchUserWithRetry(maxRetries: Int = 3) async throws -> User {
    var lastError: Error?
    
    for attempt in 0..<maxRetries {
        do {
            return try await userService.getCurrentUser()
        } catch {
            lastError = error
            if attempt < maxRetries - 1 {
                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
            }
        }
    }
    
    throw lastError ?? NetworkError.unknown("Retry failed")
}
```

## Troubleshooting

### Common Issues

**Issue**: "No such module 'MakNetworkManager'"
- **Solution**: Clean build folder (Cmd+Shift+K) and rebuild

**Issue**: Token refresh loop
- **Solution**: Ensure your auth provider's `isRefreshing` flag is properly managed

**Issue**: Requests timing out
- **Solution**: Check timeout configuration and network reachability

## Support

For issues and questions:
- GitHub Issues: https://github.com/zaighamfarid/MakNetworkManager/issues
- Documentation: https://github.com/zaighamfarid/MakNetworkManager

---

Happy coding! 🚀
