//
//  ContentView.swift
//  MakNetworkManagerExample
//
//  Main view demonstrating SDK features
//

import SwiftUI
import MakNetworkManager

struct ContentView: View {
    @EnvironmentObject var networkManager: ExampleNetworkManager
    @StateObject private var viewModel = PostsViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Network status banner
                NetworkStatusBanner(
                    status: networkManager.networkStatus,
                    isOnline: networkManager.isOnline
                )
                
                // Main content
                PostsListView(viewModel: viewModel)
            }
            .navigationTitle("MakNetworkManager")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.fetchPosts()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .task {
            await viewModel.fetchPosts()
        }
    }
}

struct NetworkStatusBanner: View {
    let status: NetworkStatus
    let isOnline: Bool
    
    var body: some View {
        if !isOnline {
            HStack {
                Image(systemName: "wifi.slash")
                Text("No Internet Connection")
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.red.opacity(0.8))
            .foregroundColor(.white)
        } else {
            HStack {
                Image(systemName: statusIcon)
                Text(statusText)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color.green.opacity(0.2))
            .foregroundColor(.green)
        }
    }
    
    private var statusIcon: String {
        switch status {
        case .wifi:
            return "wifi"
        case .cellular:
            return "antenna.radiowaves.left.and.right"
        case .unavailable:
            return "wifi.slash"
        }
    }
    
    private var statusText: String {
        switch status {
        case .wifi:
            return "Connected via WiFi"
        case .cellular:
            return "Connected via Cellular"
        case .unavailable:
            return "Offline"
        }
    }
}

struct PostsListView: View {
    @ObservedObject var viewModel: PostsViewModel
    
    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                ProgressView("Loading posts...")
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task {
                        await viewModel.fetchPosts()
                    }
                }
            } else if viewModel.posts.isEmpty {
                EmptyStateView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.posts) { post in
                            PostRowView(post: post)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct PostRowView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.title)
                .font(.headline)
            
            Text(post.body)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                Label("\(post.userId)", systemImage: "person.fill")
                Spacer()
                Label("ID: \(post.id)", systemImage: "number")
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Error")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: retry) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Posts")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Pull to refresh or tap the reload button")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ExampleNetworkManager.shared)
}
