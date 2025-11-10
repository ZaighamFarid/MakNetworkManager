# MakNetworkManager

A protocol-oriented iOS networking SDK for building scalable API layers in Swift, with async/await support, automatic token refresh, and comprehensive error handling.

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![iOS 15+](https://img.shields.io/badge/iOS-15+-blue.svg)](https://developer.apple.com/ios/)
[![SPM Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- ✅ **Protocol-Oriented Architecture** - Highly testable and modular design
- ✅ **Async/Await Support** - Modern Swift concurrency with backward-compatible closures
- ✅ **Automatic Token Refresh** - Seamless authentication with request queuing
- ✅ **Type-Safe Error Handling** - Unified `NetworkError` enum
- ✅ **Network Reachability** - Real-time connectivity monitoring  
- ✅ **Dependency Injection** - Fully customizable components
- ✅ **Zero External Dependencies** - Pure Swift implementation
- ✅ **Comprehensive Test Coverage** - Includes URLProtocolMock for testing
- ✅ **Example Project Included** - SwiftUI app demonstrating usage

## Installation

### Swift Package Manager

Add MakNetworkManager to your project using Xcode:

1. File > Add Package Dependencies
2. Enter package URL: `https://github.com/zaighamfarid/MakNetworkManager.git`
3. Select version and add to your target

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/zaighamfarid/MakNetworkManager.git", from: "1.0.0")
]
```

## Quick Start

### 1. Configure the SDK

In your `AppDelegate` or app entry point:

```swift
import MakNetworkManager

let configuration = NetworkConfiguration(
    baseURL: URL(string: "https://api.yourapp.com/v1/")!,
    oauthURL: URL(string: "https://auth.yourapp.com/")!,
    clientID: "your_client_id",
    clientSecret: "your_client_secret",
    enableLogging: true
)

let apiService = APIService(configuration: configuration)
```

### 2. Define API Endpoints

Create an enum conforming to `APIRequest`:

```swift
enum UserAPI: APIRequest {
    case getUser(id: Int)
    case updateUser(id: Int, name: String)
    
    var baseURL: URL {
        // Injected from configuration
        URL(string: "https://api.yourapp.com/v1/")!
    }
    
    var path: String {
        switch self {
        case .getUser(let id):
            return "users/\(id)"
        case .updateUser(let id, _):
            return "users/\(id)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getUser:
            return .get
        case .updateUser:
            return .put
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .updateUser(_, let name):
            return ["name": name]
        default:
            return nil
        }
    }
    
    var requiresAuthToken: Bool {
        return true
    }
}
```

### 3. Make API Calls

#### Using Async/Await

```swift
// Perform request and decode response
do {
    let user = try await apiService.perform(
        UserAPI.getUser(id: 123),
        decoding: User.self
    )
    print("User: \(user.name)")
} catch let error as NetworkError {
    print("Error: \(error.errorDescription ?? "Unknown")")
}
```

#### Using Closures

```swift
apiService.perform(UserAPI.getUser(id: 123)) { response in
    do {
        let user = try response.decode(User.self)
        print("User: \(user.name)")
    } catch {
        print("Decoding error: \(error)")
    }
} failure: { error in
    print("Network error: \(error.errorDescription ?? "Unknown")")
}
```

### 4. Handle Authentication

Implement `AuthProviderProtocol`:

```swift
class MyAuthProvider: AuthProviderProtocol {
    private var accessToken: String?
    private var refreshToken: String?
    
    func getBearerToken() -> String? {
        return accessToken.map { "Bearer \($0)" }
    }
    
    func refreshToken() async throws -> String {
        // Call your token refresh endpoint
        let response = try await URLSession.shared.data(from: refreshURL)
        // Parse and store new tokens
        self.accessToken = newAccessToken
        return newAccessToken
    }
    
    var isRefreshing: Bool = false
}

// Set auth provider on API service
apiService.setAuthProvider(MyAuthProvider())
```

## Advanced Usage

### Custom Request Builder

```swift
class CustomRequestBuilder: RequestBuilding {
    func buildRequest(
        from request: APIRequest,
        configuration: NetworkConfiguration
    ) throws -> URLRequest {
        // Custom request building logic
        var urlRequest = URLRequest(url: request.baseURL)
        // Add custom headers, signing, etc.
        return urlRequest
    }
}

let apiService = APIService(
    configuration: configuration,
    requestBuilder: CustomRequestBuilder()
)
```

### Custom Logger

```swift
class AnalyticsLogger: LoggerProtocol {
    func debug(_ message: String, file: String, function: String, line: Int) {
        // Send to analytics platform
    }
    
    func error(_ message: String, error: Error?, file: String, function: String, line: Int) {
        // Send to crash reporting
    }
    
    func logNetworkEvent(_ event: String, parameters: [String: Any]) {
        // Track network events
    }
}

let apiService = APIService(
    configuration: configuration,
    logger: AnalyticsLogger()
)
```

### Service Layer Pattern

```swift
class UserService {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func fetchUser(id: Int) async throws -> User {
        return try await apiService.perform(
            UserAPI.getUser(id: id),
            decoding: User.self
        )
    }
    
    func updateUser(id: Int, name: String) async throws -> User {
        return try await apiService.perform(
            UserAPI.updateUser(id: id, name: name),
            decoding: User.self
        )
    }
}
```

## Error Handling

MakNetworkManager provides a unified error type:

```swift
public enum NetworkError: Error {
    case noInternet
    case unauthorized
    case server(status: Int, message: String?)
    case decoding(String)
    case timeout
    case invalidRequest(String)
    case tokenRefreshFailed
    case unknown(String)
}
```

Handle errors gracefully:

```swift
do {
    let data = try await apiService.perform(request)
} catch NetworkError.noInternet {
    // Show offline UI
} catch NetworkError.unauthorized {
    // Redirect to login
} catch NetworkError.server(let status, let message) {
    // Handle server errors
} catch {
    // Handle unknown errors
}
```

## Network Reachability

Monitor network status:

```swift
let reachability = Reachability()
reachability.startMonitoring()

// Observe changes
NotificationCenter.default.addObserver(
    forName: .networkStatusChanged,
    object: nil,
    queue: .main
) { notification in
    if let status = notification.userInfo?["status"] as? NetworkStatus {
        switch status {
        case .wifi:
            print("Connected via WiFi")
        case .cellular:
            print("Connected via Cellular")
        case .unavailable:
            print("No connection")
        }
    }
}
```

## Testing

MakNetworkManager includes `URLProtocolMock` for testing:

```swift
import XCTest
@testable import MakNetworkManager

class MyTests: XCTestCase {
    func testAPICall() async throws {
        // Setup mock
        let mockData = """
        {"id": 1, "name": "Test User"}
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
        
        // Configure test session
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        let mockSession = URLSession(configuration: config)
        
        let executor = RequestExecutor(session: mockSession)
        let apiService = APIService(
            configuration: testConfiguration,
            requestExecutor: executor
        )
        
        // Test your code
        let user = try await apiService.perform(
            UserAPI.getUser(id: 1),
            decoding: User.self
        )
        
        XCTAssertEqual(user.name, "Test User")
    }
}
```

## Example Project

The SDK includes a complete SwiftUI example app demonstrating:

- SDK configuration
- API endpoint definitions  
- Service layer implementation
- Error handling
- Network status monitoring
- Loading states and UI updates

Run the example:

```bash
cd ExampleProject
open MakNetworkManagerExample.xcodeproj
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Your App                            │
│  (ViewModels, Services, Business Logic)                 │
└──────────────────────┬──────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────┐
│                   APIService                            │
│  (Request Orchestration & Token Refresh)                │
└──────────────────────┬──────────────────────────────────┘
                       ↓
        ┌──────────────┴──────────────┐
        ↓                             ↓
┌──────────────┐              ┌──────────────┐
│RequestBuilder│              │   Response   │
│              │              │   Handler    │
└──────┬───────┘              └──────┬───────┘
       ↓                             ↓
┌──────────────────────────────────────────┐
│         RequestExecutor                  │
│         (URLSession)                     │
└──────────────────────────────────────────┘
```

## Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

## License

MakNetworkManager is available under the MIT license. See the LICENSE file for more info.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Author

Developed with ❤️ for the iOS community

## Acknowledgments

- Inspired by modern networking best practices
- Built with protocol-oriented programming principles
- Designed for testability and maintainability

---

**Ready to use MakNetworkManager in your project? Star ⭐ this repo and let's build great apps together!**
