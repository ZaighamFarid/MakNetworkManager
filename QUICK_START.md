# MakNetworkManager - Quick Start

## 🚀 5-Minute Integration

### 1. Add Package (30 seconds)
```
Xcode → File → Add Package Dependencies
https://github.com/zaighamfarid/MakNetworkManager.git
```

### 2. Import (5 seconds)
```swift
import MakNetworkManager
```

### 3. Configure (1 minute)
```swift
let config = NetworkConfiguration(
    baseURL: URL(string: "https://api.yourapp.com/")!,
    clientID: "your_client_id",
    clientSecret: "your_secret"
)

let apiService = APIService(configuration: config)
```

### 4. Define API (2 minutes)
```swift
enum UserAPI: APIRequest {
    case getUser(id: Int)
    
    var baseURL: URL { config.baseURL }
    var path: String { "users/\(id)" }
    var method: HTTPMethod { .get }
    var requiresAuthToken: Bool { true }
}
```

### 5. Make Request (1 minute)
```swift
let user = try await apiService.perform(
    UserAPI.getUser(id: 123),
    decoding: User.self
)
```

## ✅ Done!

---

## 📱 Example App

Run the included example:
```bash
cd ExampleProject
# Open in Xcode and run
```

See live demo of:
- Network status monitoring
- API requests
- Error handling
- Loading states

---

## 📚 Full Documentation

- **README.md** - Complete guide
- **INTEGRATION_GUIDE.md** - Step-by-step
- **ExampleProject/README.md** - App details

---

## 🆘 Common Issues

**Q: "No such module 'MakNetworkManager'"**  
A: Clean build folder (Cmd+Shift+K) and rebuild

**Q: How do I add authentication?**  
A: Implement `AuthProviderProtocol` - see INTEGRATION_GUIDE.md

**Q: Where's the example app?**  
A: In `ExampleProject/MakNetworkManagerExample/`

---

## 💡 Key Concepts

1. **APIRequest** = Your endpoint definition
2. **APIService** = Handles all requests
3. **NetworkConfiguration** = Your API settings
4. **AuthProvider** = Token management

---

**Built by:** Zaigham Farid  
**GitHub:** github.com/zaighamfarid/MakNetworkManager  
**License:** MIT
