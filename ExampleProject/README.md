# MakNetworkManager Example App

This SwiftUI example app demonstrates how to use the **MakNetworkManager** SDK in a real iOS application.

## Features Demonstrated

✅ **SDK Configuration** - How to set up MakNetworkManager  
✅ **Network Reachability** - Real-time connection status monitoring  
✅ **API Requests** - Making network calls with async/await  
✅ **Error Handling** - Graceful error handling with user feedback  
✅ **Loading States** - Proper UI states for loading/error/empty/success  
✅ **Token Management** - Example AuthProvider implementation  
✅ **MVVM Pattern** - Clean architecture with ViewModels  

## What's Inside

### `App/`
- **MakNetworkManagerExampleApp.swift** - App entry point
- **ExampleNetworkManager.swift** - Centralized network configuration
- **ExampleAuthProvider** - Demo auth provider

### `Views/`
- **ContentView.swift** - Main view with posts list
- **NetworkStatusBanner** - Connection status indicator
- **PostRowView** - Individual post cell
- **ErrorView** - Error state with retry
- **EmptyStateView** - Empty state UI

### `ViewModels/`
- **PostsViewModel.swift** - Business logic for posts
- **PostsAPI** - API endpoint definitions
- **Post** - Data model

## API Used

This example uses **JSONPlaceholder** (https://jsonplaceholder.typicode.com/) - a free fake REST API for testing and prototyping.

No authentication required for the demo.

## How to Run

### Option 1: Via Xcode (Recommended)

1. Open `MakNetworkManagerExample.xcodeproj` in Xcode
2. Select a simulator or device
3. Press Cmd+R to build and run

### Option 2: Via Swift Package Manager

From the example directory:

```bash
cd MakNetworkManager/ExampleProject
swift build
```

## What You'll See

When you run the app, you'll see:

1. **Network Status Banner** - Shows WiFi/Cellular/Offline status
2. **Posts List** - Fetched from JSONPlaceholder API
3. **Pull to Refresh** - Tap the refresh button to reload
4. **Error Handling** - Try turning off internet to see error states
5. **Loading States** - See the loading spinner during requests

## Key Code Examples

### 1. SDK Configuration

```swift
let configuration = NetworkConfiguration(
    baseURL: URL(string: "https://jsonplaceholder.typicode.com/")!,
    clientID: "example_client_id",
    clientSecret: "example_client_secret",
    enableLogging: true
)

let apiService = APIService(
    configuration: configuration,
    authProvider: authProvider
)
```

### 2. Defining API Endpoints

```swift
enum PostsAPI: APIRequest {
    case getPosts
    
    var baseURL: URL { /* ... */ }
    var path: String { "posts" }
    var method: HTTPMethod { .get }
    var requiresAuthToken: Bool { false }
}
```

### 3. Making Requests

```swift
let posts = try await apiService.perform(
    PostsAPI.getPosts,
    decoding: [Post].self
)
```

### 4. Error Handling

```swift
do {
    let posts = try await apiService.perform(...)
} catch let error as NetworkError {
    switch error {
    case .noInternet:
        // Handle offline state
    case .server(let status, let message):
        // Handle server errors
    default:
        // Handle other errors
    }
}
```

## Customization

You can easily adapt this example for your own API:

1. **Update URLs**: Change `baseURL` in `ExampleNetworkManager`
2. **Define Your APIs**: Create your own API enums conforming to `APIRequest`
3. **Add Models**: Create Codable models for your responses
4. **Implement Auth**: Update `ExampleAuthProvider` with real token logic
5. **Create Services**: Build service layers for your business logic

## Project Structure

```
MakNetworkManagerExample/
├── App/
│   ├── MakNetworkManagerExampleApp.swift
│   ├── ExampleNetworkManager.swift
│   └── ExampleAuthProvider.swift
├── Views/
│   └── ContentView.swift
├── ViewModels/
│   └── PostsViewModel.swift
└── Assets.xcassets/
```

## Requirements

- iOS 15.0+
- Xcode 15.0+
- Swift 5.9+
- MakNetworkManager SDK

## Learning Resources

- **SDK README**: See main README for comprehensive documentation
- **Integration Guide**: Step-by-step setup instructions
- **Inline Comments**: Code is well-commented for learning

## Next Steps

After exploring this example:

1. Read the main SDK documentation
2. Check out the Integration Guide
3. Review the test suite to learn about testing
4. Start building your own app!

## Support

For questions or issues:
- GitHub: https://github.com/zaighamfarid/MakNetworkManager
- Issues: https://github.com/zaighamfarid/MakNetworkManager/issues

---

**Happy coding!** 🚀

Built with ❤️ by Zaigham Farid
