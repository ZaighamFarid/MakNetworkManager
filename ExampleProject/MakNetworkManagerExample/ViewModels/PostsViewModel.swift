//
//  PostsViewModel.swift
//  MakNetworkManagerExample
//
//  ViewModel demonstrating SDK usage with async/await
//

import Foundation
import MakNetworkManager

@MainActor
class PostsViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService: APIService
    
    init(apiService: APIService = ExampleNetworkManager.shared.apiService) {
        self.apiService = apiService
    }
    
    func fetchPosts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Use JSONPlaceholder API for demo
            let response = try await apiService.perform(
                PostsAPI.getPosts,
                decoding: [Post].self
            )
            posts = Array(response.prefix(20)) // Limit to 20 posts for demo
            
        } catch let error as NetworkError {
            errorMessage = error.errorDescription ?? "Unknown error"
            
            switch error {
            case .noInternet:
                errorMessage = "No internet connection. Please check your network."
            case .timeout:
                errorMessage = "Request timed out. Please try again."
            case .server(let status, let message):
                errorMessage = "Server error (\(status)): \(message ?? "Unknown")"
            default:
                break
            }
            
        } catch {
            errorMessage = "An unexpected error occurred"
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await fetchPosts()
    }
}

/// Example API using JSONPlaceholder for demonstration
enum PostsAPI: APIRequest {
    case getPosts
    case getPost(id: Int)
    
    var baseURL: URL {
        return URL(string: "https://jsonplaceholder.typicode.com/")!
    }
    
    var path: String {
        switch self {
        case .getPosts:
            return "posts"
        case .getPost(let id):
            return "posts/\(id)"
        }
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var requiresAuthToken: Bool {
        return false
    }
}

/// Post model
struct Post: Codable, Identifiable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}
